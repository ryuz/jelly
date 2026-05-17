// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_gamma_correction
        #(
            parameter   int                     CH_DEPTH          = 3                       ,
            parameter   int                     S_DATA_BITS       = 8                       ,
            parameter   type                    s_data_t          = logic [S_DATA_BITS-1:0] ,
            parameter   int                     M_DATA_BITS       = 8                       ,
            parameter   type                    m_data_t          = logic [M_DATA_BITS-1:0] ,
            parameter                           RAM_TYPE          = "block"                 ,

            parameter                           CORE_ID           = 32'h527a_2120           ,
            parameter                           CORE_VERSION      = 32'h0003_0001           ,
            parameter   int                     INDEX_BITS        = 1                       ,
            parameter   type                    index_t           = logic [INDEX_BITS-1:0]  ,
            parameter   int                     REGADR_BITS       = 16                      ,
            parameter   type                    regadr_t          = logic [REGADR_BITS-1:0] ,
            parameter   int                     TABLE_ADR_BITS    = $bits(s_data_t) < 8 ? 8 : $bits(s_data_t),

            parameter   bit     [2:0]           INIT_CTL_CONTROL  = 3'b000                  ,
            parameter   bit     [CH_DEPTH-1:0]  INIT_PARAM_ENABLE = '0
        )
        (
            input   var logic       in_update_req,

            jelly3_mat_if.s         s_img,
            jelly3_mat_if.m         m_img,

            jelly3_axi4l_if.s       s_axi4l
        );

    // -------------------------------------
    //  registers domain
    // -------------------------------------

    initial begin
        if ( TABLE_ADR_BITS < S_DATA_BITS )    $error("TABLE_ADR_BITS must be >= S_DATA_BITS");
        if ( REGADR_BITS < (TABLE_ADR_BITS + 1) ) $error("REGADR_BITS is too small for gamma table addressing");
        if ( CH_DEPTH != s_img.CH_DEPTH )      $error("CH_DEPTH != s_img.CH_DEPTH");
        if ( CH_DEPTH != m_img.CH_DEPTH )      $error("CH_DEPTH != m_img.CH_DEPTH");
        if ( S_DATA_BITS != s_img.CH_BITS )    $warning("S_DATA_BITS != s_img.CH_BITS");
        if ( M_DATA_BITS != m_img.CH_BITS )    $warning("M_DATA_BITS != m_img.CH_BITS");
    end

    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata)-1:0];
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb)-1:0];
    localparam type enable_t     = logic [CH_DEPTH-1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID        = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION   = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL    = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS     = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_INDEX      = regadr_t'('h07);
    localparam  regadr_t REGADR_PARAM_ENABLE   = regadr_t'('h08);
    localparam  regadr_t REGADR_CURRENT_ENABLE = regadr_t'('h18);
    localparam  regadr_t REGADR_CFG_TBL_ADDR   = regadr_t'('h80);
    localparam  regadr_t REGADR_CFG_TBL_SIZE   = regadr_t'('h81);
    localparam  regadr_t REGADR_CFG_TBL_WIDTH  = regadr_t'('h82);


    // registers
    logic       [2:0]               reg_ctl_control ;
    logic       [CH_DEPTH-1:0]      reg_param_enable;
    logic       [CH_DEPTH-1:0]      reg_mem_en      ;
    s_data_t                        reg_mem_addr    ;
    m_data_t                        reg_mem_din     ;

    // shadow registers(core domain)
    logic   [0:0]               core_ctl_control;
    logic   [CH_DEPTH-1:0]      core_param_enable;


    // handshake with core domain
    index_t                     update_index;
    logic                       update_ack;
    index_t                     ctl_index;

    jelly_param_update_master
            #(
                .INDEX_WIDTH    ($bits(index_t))
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
    regadr_t regadr_write;
    regadr_t regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / axi4l_addr_t'($bits(axi4l_strb_t)));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / axi4l_addr_t'($bits(axi4l_strb_t)));

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_ctl_control  <= INIT_CTL_CONTROL;
            reg_param_enable <= INIT_PARAM_ENABLE;
            reg_mem_en       <= '0;
            reg_mem_addr     <= 'x;
            reg_mem_din      <= 'x;

            s_axi4l.bvalid <= 1'b0;
            s_axi4l.rdata  <= 'x;
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            // auto clear update bit
            if ( update_ack && !reg_ctl_control[2] ) begin
                reg_ctl_control[1] <= 1'b0;
            end
            reg_mem_en   <= '0;
            reg_mem_addr <= 'x;
            reg_mem_din  <= 'x;

            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 1'b0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL:  reg_ctl_control  <=                          3'(write_mask(axi4l_data_t'(reg_ctl_control ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_ENABLE: reg_param_enable <= enable_t'(write_mask(axi4l_data_t'(reg_param_enable), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
                for ( int i = 0; i < CH_DEPTH; i++ ) begin
                    if ( (regadr_write >> TABLE_ADR_BITS) == regadr_t'(i+1) ) begin
                        reg_mem_en[i] <= 1'b1;
                        reg_mem_addr  <= s_data_t'(regadr_write[TABLE_ADR_BITS-1:0]);
                        reg_mem_din   <= m_data_t'(s_axi4l.wdata);
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
                REGADR_CORE_ID:        s_axi4l.rdata <= axi4l_data_t'(CORE_ID               );
                REGADR_CORE_VERSION:   s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION          );
                REGADR_CTL_CONTROL:    s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control       );
                REGADR_CTL_STATUS:     s_axi4l.rdata <= axi4l_data_t'(core_ctl_control      );
                REGADR_CTL_INDEX:      s_axi4l.rdata <= axi4l_data_t'(ctl_index             );
                REGADR_PARAM_ENABLE:   s_axi4l.rdata <= axi4l_data_t'(reg_param_enable      );
                REGADR_CURRENT_ENABLE: s_axi4l.rdata <= axi4l_data_t'(core_param_enable     );
                REGADR_CFG_TBL_ADDR:   s_axi4l.rdata <= axi4l_data_t'(axi4l_data_t'(1) << TABLE_ADR_BITS);
                REGADR_CFG_TBL_SIZE:   s_axi4l.rdata <= axi4l_data_t'(axi4l_data_t'(1) << S_DATA_BITS   );
                REGADR_CFG_TBL_WIDTH:  s_axi4l.rdata <= axi4l_data_t'(M_DATA_BITS           );
                default:               s_axi4l.rdata <= '0;
                endcase
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
    logic update_trig;
    logic update_en;
    assign update_trig = (s_img.valid && s_img.row_first && s_img.col_first);

    jelly_param_update_slave
            #(
                .INDEX_WIDTH    ($bits(index_t))
            )
        u_param_update_slave
            (
                .reset          (s_img.reset         ),
                .clk            (s_img.clk           ),
                .cke            (s_img.cke           ),

                .in_trigger     (update_trig         ),
                .in_update      (reg_ctl_control[1]  ),

                .out_update     (update_en           ),
                .out_index      (update_index        )
            );

    // wait for frame start to update parameters
    logic reg_update_req;
    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            reg_update_req   <= 1'b0;
            core_ctl_control <= INIT_CTL_CONTROL[0];
            core_param_enable <= INIT_PARAM_ENABLE;
        end
        else begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end

            if ( s_img.cke ) begin
                if ( reg_update_req && update_trig && update_en ) begin
                    reg_update_req   <= 1'b0;
                    core_ctl_control <= reg_ctl_control[0];
                    core_param_enable <= reg_ctl_control[0] ? reg_param_enable : '0;
                end
            end
        end
    end

    // cores
    m_data_t [CH_DEPTH-1:0] core_data;
    for ( genvar i = 0; i < CH_DEPTH; i++ ) begin : g_core
        jelly3_img_gamma_correction_core
                #(
                    .S_DATA_BITS     (S_DATA_BITS               ),
                    .s_data_t        (s_data_t                  ),
                    .M_DATA_BITS     (M_DATA_BITS               ),
                    .m_data_t        (m_data_t                  ),
                    .RAM_TYPE        (RAM_TYPE                  )
                )
            u_img_gamma_correction_core
                (
                    .reset          (s_img.reset                ),
                    .clk            (s_img.clk                  ),
                    .cke            (s_img.cke                  ),

                    .enable         (core_param_enable[i]       ),

                    .mem_clk        (s_axi4l.aclk               ),
                    .mem_en         (reg_mem_en[i]              ),
                    .mem_addr       (reg_mem_addr               ),
                    .mem_din        (reg_mem_din                ),

                    .s_data         (s_data_t'(s_img.data[0][i])),

                    .m_data         (core_data[i]               )
                );
    end


    // delay sideband to match 3-cycle LUT path
    localparam  int     DE_BITS   = s_img.DE_BITS           ;
    localparam  int     USER_BITS = s_img.USER_BITS         ;
    localparam  type    de_t      = logic [DE_BITS-1:0]     ;
    localparam  type    user_t    = logic [USER_BITS-1:0]   ;

    logic               dly_row_first   ;
    logic               dly_row_last    ;
    logic               dly_col_first   ;
    logic               dly_col_last    ;
    de_t                dly_de          ;
    user_t              dly_user        ;
    logic               dly_valid       ;

    jelly3_mat_delay
            #(
                .LATENCY    (3                  ),
                .ROWS_BITS  (s_img.ROWS_BITS    ),
                .rows_t     (logic [s_img.ROWS_BITS-1:0]),
                .COLS_BITS  (s_img.COLS_BITS    ),
                .cols_t     (logic [s_img.COLS_BITS-1:0]),
                .DE_BITS    (DE_BITS            ),
                .de_t       (de_t               ),
                .DATA_BITS  (1                  ),
                .USER_BITS  (USER_BITS          ),
                .user_t     (user_t             )
            )
        u_mat_delay
            (
                .reset              (s_img.reset    ),
                .clk                (s_img.clk      ),
                .cke                (s_img.cke      ),

                .s_mat_rows         (s_img.rows     ),
                .s_mat_cols         (s_img.cols     ),
                .s_mat_row_first    (s_img.row_first),
                .s_mat_row_last     (s_img.row_last ),
                .s_mat_col_first    (s_img.col_first),
                .s_mat_col_last     (s_img.col_last ),
                .s_mat_de           (s_img.de       ),
                .s_mat_data         (               ),
                .s_mat_user         (s_img.user     ),
                .s_mat_valid        (s_img.valid    ),

                .m_mat_rows         (               ),
                .m_mat_cols         (               ),
                .m_mat_row_first    (dly_row_first  ),
                .m_mat_row_last     (dly_row_last   ),
                .m_mat_col_first    (dly_col_first  ),
                .m_mat_col_last     (dly_col_last   ),
                .m_mat_de           (dly_de         ),
                .m_mat_data         (               ),
                .m_mat_user         (dly_user       ),
                .m_mat_valid        (dly_valid      )
            );

    assign m_img.rows      = s_img.rows;
    assign m_img.cols      = s_img.cols;
    assign m_img.row_first = dly_row_first;
    assign m_img.row_last  = dly_row_last;
    assign m_img.col_first = dly_col_first;
    assign m_img.col_last  = dly_col_last;
    assign m_img.de        = dly_de;
    assign m_img.user      = dly_user;
    assign m_img.valid     = dly_valid;

    always_comb begin : p_data
        m_img.data[0] = 'x;
        for ( int i = 0; i < CH_DEPTH; i++ ) begin
            m_img.data[0][i] = core_data[i];
        end
    end


    // assertion
    always_comb begin
        sva_connect_reset : assert (m_img.reset === s_img.reset) else $error("m_img.reset != s_img.reset");
        sva_connect_clk   : assert (m_img.clk   === s_img.clk)   else $error("m_img.clk != s_img.clk");
        sva_connect_cke   : assert (m_img.cke   === s_img.cke)   else $error("m_img.cke != s_img.cke");
    end

endmodule


`default_nettype wire


// end of file
