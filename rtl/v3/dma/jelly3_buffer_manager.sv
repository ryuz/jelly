// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// バッファ管理
module jelly3_buffer_manager
        #(
            parameter   int     BUFFER_NUM   = 3                                        ,
            parameter   int     READER_NUM   = 1                                        ,
            parameter   int     ADDR_BITS    = 32                                       ,
            parameter   type    addr_t       = logic [ADDR_BITS-1:0]                    ,
            parameter   int     REFCNT_BITS  = 4                                        ,
            parameter   type    refcnt_t     = logic [REFCNT_BITS-1:0]                  ,
            parameter   int     INDEX_BITS   = $clog2(BUFFER_NUM)                       ,
            parameter   type    index_t      = logic [INDEX_BITS-1:0]                   ,
            parameter   int     REGADR_BITS  = 8                                        ,
            parameter   type    regadr_t     = logic [REGADR_BITS-1:0]                  ,
            parameter           CORE_ID      = 32'h527a_0004                            ,
            parameter           CORE_VERSION = 32'h0000_0000                            ,
            parameter   addr_t  INIT_ADDR [BUFFER_NUM] = '{default: '0}
        )
        (
            jelly3_axi4l_if.s                               s_axi4l         ,

            input   var logic                               writer_request  ,
            input   var logic                               writer_release  ,
            output  var addr_t                              writer_addr     ,
            output  var index_t                             writer_index    ,

            input   var logic   [READER_NUM-1:0]            reader_request  ,
            input   var logic   [READER_NUM-1:0]            reader_release  ,
            output  var addr_t  [READER_NUM-1:0]            reader_addr     ,
            output  var index_t [READER_NUM-1:0]            reader_index    ,

            output  var addr_t                              newest_addr     ,
            output  var index_t                             newest_index    ,

            output  var refcnt_t [BUFFER_NUM-1:0]           status_refcnt
        );


    typedef logic [s_axi4l.DATA_BITS-1:0]   axi4l_data_t;
    typedef logic [s_axi4l.STRB_BITS-1:0]   axi4l_strb_t;


    // ---------------------------------
    //  Register
    // ---------------------------------

    // register address offset
    localparam  regadr_t    REGADR_CORE_ID        = regadr_t'('h00);
    localparam  regadr_t    REGADR_CORE_VERSION   = regadr_t'('h01);
    localparam  regadr_t    REGADR_CORE_CONFIG    = regadr_t'('h03);
    localparam  regadr_t    REGADR_NEWEST_INDEX   = regadr_t'('h20);
    localparam  regadr_t    REGADR_WRITER_INDEX   = regadr_t'('h21);
    localparam  regadr_t    REGADR_BUFFER0_ADDR   = regadr_t'('h40);
    localparam  regadr_t    REGADR_BUFFER0_REFCNT = regadr_t'('h80);

    // write mask
    function automatic axi4l_data_t write_mask(
                                        input axi4l_data_t org,
                                        input axi4l_data_t dat,
                                        input axi4l_strb_t strb
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? dat[i] : org[i];
        end
    endfunction

    // address decode
    regadr_t    regadr_write;
    regadr_t    regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));

    // buffer address registers
    addr_t      reg_addr [0:BUFFER_NUM-1];


    // ---------------------------------
    //  Write path
    // ---------------------------------

    logic   bvalid;

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            for ( int i = 0; i < BUFFER_NUM; ++i ) begin
                reg_addr[i] <= INIT_ADDR[i];
            end
            bvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l.bready ) begin
                bvalid <= 1'b0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                for ( int i = 0; i < BUFFER_NUM; ++i ) begin
                    if ( regadr_write == REGADR_BUFFER0_ADDR + regadr_t'(i) ) begin
                        reg_addr[i] <= addr_t'(write_mask(axi4l_data_t'(reg_addr[i]), s_axi4l.wdata, s_axi4l.wstrb));
                    end
                end
                bvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.bvalid  = bvalid;


    // ---------------------------------
    //  Read path
    // ---------------------------------

    axi4l_data_t    rdata;
    logic           rvalid;

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            rdata  <= 'x;
            rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l.rready ) begin
                rdata  <= 'x;
                rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                rdata <= '0;
                case ( regadr_read )
                REGADR_CORE_ID:      rdata <= axi4l_data_t'(CORE_ID);
                REGADR_CORE_VERSION: rdata <= axi4l_data_t'(CORE_VERSION);
                REGADR_CORE_CONFIG:  rdata <= axi4l_data_t'(BUFFER_NUM);
                REGADR_NEWEST_INDEX: rdata <= axi4l_data_t'(newest_index);
                REGADR_WRITER_INDEX: rdata <= axi4l_data_t'(writer_index);
                default: ;
                endcase
                for ( int i = 0; i < BUFFER_NUM; ++i ) begin
                    if ( regadr_read == REGADR_BUFFER0_ADDR   + regadr_t'(i) ) rdata <= axi4l_data_t'(reg_addr[i]);
                    if ( regadr_read == REGADR_BUFFER0_REFCNT + regadr_t'(i) ) rdata <= axi4l_data_t'(status_refcnt[i]);
                end
                rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.arready = ~rvalid || s_axi4l.rready;
    assign s_axi4l.rdata   = rdata;
    assign s_axi4l.rresp   = '0;
    assign s_axi4l.rvalid  = rvalid;


    // ---------------------------------
    //  Buffer arbiter
    // ---------------------------------

    // param_buf_addr を packed array に変換
    addr_t  [BUFFER_NUM-1:0]    param_buf_addr;
    always_comb begin
        for ( int i = 0; i < BUFFER_NUM; ++i ) begin
            param_buf_addr[i] = reg_addr[i];
        end
    end

    jelly3_buffer_arbiter
            #(
                .BUFFER_NUM     (BUFFER_NUM )   ,
                .READER_NUM     (READER_NUM )   ,
                .ADDR_BITS      (ADDR_BITS  )   ,
                .addr_t         (addr_t     )   ,
                .REFCNT_BITS    (REFCNT_BITS)   ,
                .refcnt_t       (refcnt_t   )   ,
                .INDEX_BITS     (INDEX_BITS )   ,
                .index_t        (index_t    )
            )
        u_buffer_arbiter
            (
                .reset          (~s_axi4l.aresetn  ),
                .clk            (s_axi4l.aclk      ),
                .cke            (1'b1              ),

                .param_buf_addr (param_buf_addr     ),

                .writer_request (writer_request     ),
                .writer_release (writer_release     ),
                .writer_addr    (writer_addr        ),
                .writer_index   (writer_index       ),

                .reader_request (reader_request     ),
                .reader_release (reader_release     ),
                .reader_addr    (reader_addr        ),
                .reader_index   (reader_index       ),

                .newest_addr    (newest_addr        ),
                .newest_index   (newest_index       ),

                .status_refcnt  (status_refcnt      )
            );


endmodule


`default_nettype wire


// end of file
