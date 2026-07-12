// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// バッファ割り当て
module jelly3_buffer_allocator
        #(
            parameter   int     NUM          = 1                        ,
            parameter   int     ADDR_BITS    = 32                       ,
            parameter   type    addr_t       = logic [ADDR_BITS-1:0]    ,
            parameter   int     INDEX_BITS   = 4                        ,
            parameter   type    index_t      = logic [INDEX_BITS-1:0]   ,
            parameter   int     REGADR_BITS  = 8                        ,
            parameter   type    regadr_t     = logic [REGADR_BITS-1:0]  ,
            parameter           CORE_ID      = 32'h527a_0008            ,
            parameter           CORE_VERSION = 32'h0000_0000
        )
        (
            jelly3_axi4l_if.s               s_axi4l         ,

            output  var logic   [NUM-1:0]   buffer_request  ,
            output  var logic   [NUM-1:0]   buffer_release  ,
            input   var addr_t  [NUM-1:0]   buffer_addr     ,
            input   var index_t [NUM-1:0]   buffer_index
        );


    typedef logic [s_axi4l.DATA_BITS-1:0]   axi4l_data_t;


    // ---------------------------------
    //  Register
    // ---------------------------------

    // register address offset
    localparam  regadr_t    REGADR_CORE_ID         = regadr_t'('h00);
    localparam  regadr_t    REGADR_CORE_VERSION    = regadr_t'('h01);
    localparam  regadr_t    REGADR_CORE_CONFIG     = regadr_t'('h03);
    localparam  regadr_t    REGADR_BUFFER0_REQUEST = regadr_t'('h20);
    localparam  regadr_t    REGADR_BUFFER0_RELEASE = regadr_t'('h21);
    localparam  regadr_t    REGADR_BUFFER0_ADDR    = regadr_t'('h22);
    localparam  regadr_t    REGADR_BUFFER0_INDEX   = regadr_t'('h23);


    // address decode
    regadr_t    regadr_write;
    regadr_t    regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));


    // ---------------------------------
    //  Write path
    // ---------------------------------

    logic   [NUM-1:0]   reg_request;
    logic   [NUM-1:0]   reg_release;
    logic               bvalid;

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_request <= '0;
            reg_release <= '0;
            bvalid      <= 1'b0;
        end
        else if ( s_axi4l.aclken ) begin
            reg_request <= '0;
            reg_release <= '0;
            if ( s_axi4l.bready ) begin
                bvalid <= 1'b0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                for ( int j = 0; j < NUM; ++j ) begin
                    if ( regadr_write == REGADR_BUFFER0_REQUEST + regadr_t'(4*j) ) reg_request[j] <= 1'b1;
                    if ( regadr_write == REGADR_BUFFER0_RELEASE + regadr_t'(4*j) ) reg_release[j] <= 1'b1;
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
        else if ( s_axi4l.aclken ) begin
            if ( s_axi4l.rready ) begin
                rdata  <= 'x;
                rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                rdata <= '0;
                case ( regadr_read )
                REGADR_CORE_ID:      rdata <= axi4l_data_t'(CORE_ID);
                REGADR_CORE_VERSION: rdata <= axi4l_data_t'(CORE_VERSION);
                REGADR_CORE_CONFIG:  rdata <= axi4l_data_t'(NUM);
                default: ;
                endcase
                for ( int j = 0; j < NUM; ++j ) begin
                    if ( regadr_read == REGADR_BUFFER0_ADDR  + regadr_t'(4*j) ) rdata <= axi4l_data_t'(buffer_addr [j]);
                    if ( regadr_read == REGADR_BUFFER0_INDEX + regadr_t'(4*j) ) rdata <= axi4l_data_t'(buffer_index[j]);
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
    //  Output
    // ---------------------------------

    assign buffer_request = reg_request;
    assign buffer_release = reg_release;


endmodule


`default_nettype wire


// end of file
