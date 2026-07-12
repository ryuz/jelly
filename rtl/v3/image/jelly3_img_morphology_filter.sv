// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_morphology_filter
        #(
            parameter   int                 NUM                 = 1                         ,
            parameter   int                 N                   = 3                         ,
            parameter   int                 M                   = 3                         ,
            parameter   int                 MAX_COLS            = 1024                      ,
            parameter                       RAM_TYPE            = "block"                   ,
            parameter   bit                 BYPASS_SIZE         = 1'b1                      ,
            parameter   int                 INDEX_BITS          = 1                         ,
            parameter   type                index_t             = logic [INDEX_BITS-1:0]    ,
            parameter   int                 REGADR_BITS         = 8                         ,
            parameter   type                regadr_t            = logic [REGADR_BITS-1:0]   ,
            parameter                       CORE_ID             = 32'h527a_4384             ,
            parameter                       CORE_VERSION        = 32'h0001_0000             ,
            parameter   bit         [1:0]   INIT_CTL_CONTROL    = 2'b01                     ,
            parameter   bit     [NUM-1:0]   INIT_PARAM_ENABLE   = '0                        ,
            parameter   bit     [NUM-1:0]   INIT_PARAM_DILATION = '0                        ,
            parameter   bit [N-1:0][M-1:0]  INIT_PARAM_FILTER   = '1                        
        )
        (
            input   var logic               in_update_req   ,

            jelly3_mat_if.s                 s_img           ,
            jelly3_mat_if.m                 m_img           ,

            jelly3_axi4l_if.s               s_axi4l
        );



    // -------------------------------------
    //  registers domain
    // -------------------------------------

    // type
    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata)-1:0];
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb)-1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID          = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION     = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL      = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS       = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_INDEX        = regadr_t'('h07);
    localparam  regadr_t REGADR_PARAM_ENABLE     = regadr_t'('h08);
    localparam  regadr_t REGADR_PARAM_DILATION   = regadr_t'('h09);
    localparam  regadr_t REGADR_PARAM_FILTER     = regadr_t'('h10);

    // registers
    logic   [1:0]           reg_ctl_control     ;    // bit[0]:enable, bit[1]:update
    logic   [NUM-1:0]       reg_param_enable    ;
    logic   [NUM-1:0]       reg_param_dilation  ;
    logic   [N-1:0][M-1:0]  reg_param_filter    ;

    // shadow registers(core domain)
    logic   [0:0]           core_ctl_control    ;
    logic   [NUM-1:0]       core_param_enable   ;
    logic   [NUM-1:0]       core_param_dilation ;
    logic   [N-1:0][M-1:0]  core_param_filter   ;

    // handshake with core domain
    index_t         update_index    ;
    logic           update_ack      ;
    index_t         ctl_index       ;

    jelly_param_update_master
            #(
                .INDEX_WIDTH    ($bits(index_t)     )
            )
        u_param_update_master
            (
                .reset          (~s_axi4l.aresetn   ),
                .clk            (s_axi4l.aclk       ),
                .cke            (1'b1               ),
                .in_index       (update_index       ),
                .out_ack        (update_ack         ),
                .out_index      (ctl_index          )
            );

    // write mask
    function [s_axi4l.DATA_BITS-1:0] write_mask(
                                        input axi4l_data_t org,
                                        input axi4l_data_t data,
                                        input axi4l_strb_t strb
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction

    // registers control
    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / axi4l_addr_t'($bits(axi4l_strb_t)));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / axi4l_addr_t'($bits(axi4l_strb_t)));

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_ctl_control    <= INIT_CTL_CONTROL      ;
            reg_param_enable   <= INIT_PARAM_ENABLE     ;
            reg_param_dilation <= INIT_PARAM_DILATION   ;
            reg_param_filter   <= INIT_PARAM_FILTER     ;

            s_axi4l.bvalid <= 1'b0;
            s_axi4l.rdata  <= 'x;
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            // auto clear
            if ( update_ack ) begin
                reg_ctl_control[1] <= 1'b0;
            end

            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 1'b0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL:    reg_ctl_control    <=                          2'(write_mask(axi4l_data_t'(reg_ctl_control),    s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_ENABLE:   reg_param_enable   <=                        NUM'(write_mask(axi4l_data_t'(reg_param_enable),   s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_DILATION: reg_param_dilation <=                        NUM'(write_mask(axi4l_data_t'(reg_param_dilation), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
                for ( int i = 0; i < N; i++ ) begin
                    if ( regadr_write == REGADR_PARAM_FILTER + regadr_t'(i) ) begin
                        reg_param_filter[i] <= M'(write_mask(axi4l_data_t'(reg_param_filter[i]), s_axi4l.wdata, s_axi4l.wstrb));
                    end
                end
                s_axi4l.bvalid <= 1'b1;
            end

            // read
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                case ( regadr_read )
                REGADR_CORE_ID:          s_axi4l.rdata <= axi4l_data_t'(CORE_ID             );
                REGADR_CORE_VERSION:     s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION        );
                REGADR_CTL_CONTROL:      s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control     );
                REGADR_CTL_STATUS:       s_axi4l.rdata <= axi4l_data_t'(core_ctl_control    );   // debug use only
                REGADR_CTL_INDEX:        s_axi4l.rdata <= axi4l_data_t'(ctl_index           );
                REGADR_PARAM_ENABLE:     s_axi4l.rdata <= axi4l_data_t'(reg_param_enable    );
                REGADR_PARAM_DILATION:   s_axi4l.rdata <= axi4l_data_t'(reg_param_dilation  );
                default:                 s_axi4l.rdata <= '0;
                endcase
                for ( int i = 0; i < N; i++ ) begin
                    if ( regadr_read == REGADR_PARAM_FILTER + regadr_t'(i) ) begin
                        s_axi4l.rdata <= axi4l_data_t'(reg_param_filter[i]);
                    end
                end

                s_axi4l.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;



    // -------------------------------------
    //  core domain
    // -------------------------------------

    // handshake with registers domain
    logic   update_trig ;
    logic   update_en   ;
    assign  update_trig = (s_img.valid & s_img.row_first & s_img.col_first);

    jelly_param_update_slave
            #(
                .INDEX_WIDTH    ($bits(index_t))
            )
        u_param_update_slave
            (
                .reset          (s_img.reset),
                .clk            (s_img.clk  ),
                .cke            (s_img.cke  ),

                .in_trigger     (update_trig        ),
                .in_update      (reg_ctl_control[1] ),

                .out_update     (update_en      ),
                .out_index      (update_index   )
            );

    // wait for frame start to update parameters
    logic       reg_update_req;
    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            reg_update_req       <= 1'b0;

            core_ctl_control     <= INIT_CTL_CONTROL[0] ;
            core_param_enable    <= INIT_PARAM_ENABLE   ;
            core_param_dilation  <= INIT_PARAM_DILATION ;
            core_param_filter    <= INIT_PARAM_FILTER   ;
        end
        else begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end

            if ( s_img.cke ) begin
                if ( reg_update_req & update_trig & update_en ) begin
                    reg_update_req       <= 1'b0;

                    core_ctl_control     <= reg_ctl_control[0]  ;
                    core_param_enable    <= reg_param_enable    ;
                    core_param_dilation  <= reg_param_dilation  ;
                    core_param_filter    <= reg_param_filter    ;
                end
            end
        end
    end

    // core
    logic   [NUM-1:0]   enable;
    assign enable = core_ctl_control[0] ? core_param_enable : '0;

    jelly3_mat_if
            #(
                .USE_DE     (m_img.USE_DE   ),
                .USE_USER   (m_img.USE_USER ),
                .USE_VALID  (m_img.USE_VALID),
                .TAPS       (m_img.TAPS     ),
                .DE_BITS    (m_img.DE_BITS  ),
                .CH_DEPTH   (m_img.CH_DEPTH ),
                .CH_BITS    (m_img.CH_BITS  ),
                .ROWS_BITS  (m_img.ROWS_BITS),
                .COLS_BITS  (m_img.COLS_BITS),
                .DATA_BITS  (m_img.DATA_BITS),
                .USER_BITS  (m_img.USER_BITS)
            )
        img_morph [0:NUM]
            (
                .reset      (m_img.reset    ),
                .clk        (m_img.clk      ),
                .cke        (m_img.cke      )
            );

    assign img_morph[0].rows      = s_img.rows      ;
    assign img_morph[0].cols      = s_img.cols      ;
    assign img_morph[0].row_first = s_img.row_first ;
    assign img_morph[0].row_last  = s_img.row_last  ;
    assign img_morph[0].col_first = s_img.col_first ;
    assign img_morph[0].col_last  = s_img.col_last  ;
    assign img_morph[0].de        = s_img.de        ;
    assign img_morph[0].data      = s_img.data      ;
    assign img_morph[0].user      = s_img.user      ;
    assign img_morph[0].valid     = s_img.valid     ;

    for ( genvar i = 0; i < NUM; i++ ) begin : loop_core
        jelly3_img_morphology_filter_core
                #(
                    .N              (N                      ),
                    .M              (M                      ),
                    .MAX_COLS       (MAX_COLS               ),
                    .RAM_TYPE       (RAM_TYPE               ),
                    .BYPASS_SIZE    (BYPASS_SIZE            )
                )
            u_img_morphology_filter_core
                (
                    .enable         (enable[i]              ),
                    .param_dilation (core_param_dilation[i] ),
                    .param_filter   (core_param_filter      ),
                    .s_img          (img_morph[i]           ),
                    .m_img          (img_morph[i+1]         )
                );
    end

    assign m_img.rows      = img_morph[NUM].rows;
    assign m_img.cols      = img_morph[NUM].cols;
    assign m_img.row_first = img_morph[NUM].row_first;
    assign m_img.row_last  = img_morph[NUM].row_last;
    assign m_img.col_first = img_morph[NUM].col_first;
    assign m_img.col_last  = img_morph[NUM].col_last;
    assign m_img.de        = img_morph[NUM].de;
    assign m_img.data      = img_morph[NUM].data;
    assign m_img.user      = img_morph[NUM].user;
    assign m_img.valid     = img_morph[NUM].valid;

endmodule


`default_nettype wire


// end of file
