// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module video_raw_to_rgb
        #(
            parameter   int     WIDTH_BITS  = 13                        ,
            parameter   int     HEIGHT_BITS = 12                        ,
            parameter   type    width_t     = logic [WIDTH_BITS-1:0]    ,
            parameter   type    height_t    = logic [HEIGHT_BITS-1:0]   ,
            parameter   int     M_CH_DEPTH  = 3                         ,
            parameter           DEVICE      = "RTL"                     
        )
        (
            input   var logic           in_update_req   ,
            input   var width_t         param_width     ,
            input   var height_t        param_height    ,

            jelly3_axi4s_if.s           s_axi4s         ,
            jelly3_axi4s_if.m           m_axi4s         ,

            jelly3_axi4l_if.s           s_axi4l         
        );

    // ----------------------------------------
    //  local patrameter
    // ----------------------------------------

    localparam  int     ROWS_BITS  = $bits(height_t);
    localparam  int     COLS_BITS  = $bits(width_t);
    localparam  type    rows_t     = logic [ROWS_BITS-1:0];
    localparam  type    cols_t     = logic [COLS_BITS-1:0];

    localparam  int     S_CH_BITS  = s_axi4s.DATA_BITS;
    localparam  int     S_CH_DEPTH = 1;
    localparam  int     M_CH_BITS  = m_axi4s.DATA_BITS / M_CH_DEPTH;


    // ----------------------------------------
    //  Address decoder
    // ----------------------------------------

    localparam DEC_WB    = 0;
    localparam DEC_DEMOS = 1;

    localparam DEC_NUM   = 2;

    jelly3_axi4l_if
            #(
                .ADDR_BITS      (s_axi4l.ADDR_BITS  ),
                .DATA_BITS      (s_axi4l.DATA_BITS  )
            )
        axi4l_dec [DEC_NUM]
            (
                .aresetn        (s_axi4l.aresetn    ),
                .aclk           (s_axi4l.aclk       ),
                .aclken         (1'b1               )
            );
    
    // address map
    assign {axi4l_dec[DEC_WB   ].addr_base, axi4l_dec[DEC_WB   ].addr_high} = {40'ha012_1000, 40'ha012_1fff};
    assign {axi4l_dec[DEC_DEMOS].addr_base, axi4l_dec[DEC_DEMOS].addr_high} = {40'ha012_2000, 40'ha012_2fff};

    jelly3_axi4l_addr_decoder
            #(
                .NUM            (DEC_NUM    ),
                .DEC_ADDR_BITS  (16         )
            )
        u_axi4l_addr_decoder
            (
                .s_axi4l        (s_axi4l    ),
                .m_axi4l        (axi4l_dec  )
            );


    // -------------------------------------
    //  AXI4-Stream <=> Image Interface
    // -------------------------------------

    logic           reset ;
    logic           clk   ;
    logic           cke   ;
    assign  reset = ~s_axi4s.aresetn;
    assign  clk   = s_axi4s.aclk;
    
    jelly3_mat_if
            #(
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (S_CH_BITS      ),
                .CH_DEPTH   (S_CH_DEPTH     )
            )
        img_src
            (
                .reset      (reset  ),
                .clk        (clk    ),
                .cke        (cke    )
            );

   jelly3_mat_if
            #(
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (M_CH_BITS      ),
                .CH_DEPTH   (M_CH_DEPTH     )
            )
        img_sink
            (
                .reset      (reset  ),
                .clk        (clk    ),
                .cke        (cke    )
            );
    

    jelly3_axi4s_mat
            #(
                .ROWS_BITS      ($bits(rows_t)      ),
                .COLS_BITS      ($bits(cols_t)      ),
                .BLANK_BITS     (4                  ),
                .CKE_BUFG       (0                  ) 
            )
        u_axi4s_mat
            (
                .param_rows     (param_height       ),
                .param_cols     (param_width        ),
                .param_blank    (4'd6               ),
                .s_axi4s        (s_axi4s            ),
                .m_axi4s        (m_axi4s            ),

                .out_cke        (cke                ),
                .m_mat          (img_src.m          ),
                .s_mat          (img_sink.s         )
        );
    

    // -------------------------------------
    //  Black Level Correction
    // -------------------------------------

    // 現像用データサイズ
    localparam  int     CH_BITS = S_CH_BITS + 1;
    localparam  type    ch_t    = logic signed [CH_BITS-1:0];

    jelly3_mat_if
            #(
                .CH_BITS    ($bits(ch_t)),
                .CH_DEPTH   (S_CH_DEPTH )
            )
        img_wb
            (
                .reset      (reset      ),
                .clk        (clk        ),
                .cke        (cke        )
            );

    jelly3_img_bayer_white_balance
            #(
                .S_DATA_BITS        (S_CH_BITS              ),
                .M_DATA_BITS        ($bits(ch_t)            ),
                .OFFSET_BITS        (S_CH_BITS              ),
                .COEFF_BITS         (16                     ),
                .COEFF_Q            (12                     ),
                .INIT_CTL_CONTROL   (2'b11                  ),
                .INIT_PARAM_PHASE   (2'b00                  ),
                .INIT_PARAM_OFFSET0 (66                     ),
                .INIT_PARAM_OFFSET1 (66                     ),
                .INIT_PARAM_OFFSET2 (66                     ),
                .INIT_PARAM_OFFSET3 (66                     ),
                .INIT_PARAM_COEFF0  (4620                   ),
                .INIT_PARAM_COEFF1  (4096                   ),
                .INIT_PARAM_COEFF2  (4096                   ),
                .INIT_PARAM_COEFF3  (10428                  ) 
            )
        u_img_bayer_white_balance
            (
                .in_update_req      (in_update_req          ),
                .s_img              (img_src.s              ),
                .m_img              (img_wb.m               ),
                .s_axi4l            (axi4l_dec[DEC_WB].s    )
            );
    


    // -------------------------------------
    //  demosaic
    // -------------------------------------

    jelly3_mat_if
            #(
                .CH_BITS        ($bits(ch_t)    ),
                .CH_DEPTH       (4              )
            )
         img_demos
            (
                .reset          (img_src.reset  ),
                .clk            (img_src.clk    ),
                .cke            (img_src.cke    )
            );
    
    jelly3_img_demosaic_acpi
            #(
                .CH_BITS            ($bits(ch_t)            ),
                .ch_t               (ch_t                   ),
                .MAX_COLS           (2048                   ),
                .RAM_TYPE           ("block"                ),
                .INIT_PARAM_PHASE   (2'b00                  )
            )
        u_img_demosaic_acpi
            (
                .in_update_req      (in_update_req          ),
                .s_img              (img_wb.s               ),
                .m_img              (img_demos.m            ),
                .s_axi4l            (axi4l_dec[DEC_DEMOS].s )
            );
    
    // -------------------------------------
    //  clamp
    // -------------------------------------

    jelly3_mat_if
            #(
                .CH_BITS        (img_src.CH_BITS    ),
                .CH_DEPTH       (img_sink.CH_DEPTH  )
            )
         img_clamp
            (
                .reset          (img_src.reset      ),
                .clk            (img_src.clk        ),
                .cke            (img_src.cke        )
            );

    jelly3_mat_clamp_core
            #(
                .calc_t         (ch_t               )
            )
        u_mat_clamp_core
            (
                .enable         (1'b1               ),
                .min_value      (ch_t'(0)           ),
                .max_value      (ch_t'(1023)        ),
                .s_mat          (img_demos.s        ),
                .m_mat          (img_clamp.m        )
            );


    // -------------------------------------
    //  gamma correction
    // -------------------------------------

    if ( 0 ) begin : gamma
        logic   [2:0][7:0]  img_clamp_gamma;
        for ( genvar i = 0; i < 3; i++ ) begin : gamma_table
            gamma_table
                u_gamma_table
                    (
                        .addr       (img_clamp.data[0][i][9:0]),
                        .data       (img_clamp_gamma[i])
                    );
        end

        logic               gamma_row_first;
        logic               gamma_row_last ;
        logic               gamma_col_first;
        logic               gamma_col_last ;
        logic               gamma_de       ;
        logic   [2:0][7:0]  gamma_data     ;
        logic               gamma_user     ;
        logic               gamma_valid    ;
        always_ff @(posedge img_src.clk) begin
            if ( img_src.reset ) begin
                gamma_row_first <= 'x;
                gamma_row_last  <= 'x;
                gamma_col_first <= 'x;
                gamma_col_last  <= 'x;
                gamma_de        <= 'x;
                gamma_data      <= 'x;
                gamma_user      <= 'x;
                gamma_valid     <= '0;
            end
            else if ( img_src.cke  ) begin
                gamma_row_first <= img_clamp.row_first  ;
                gamma_row_last  <= img_clamp.row_last   ;
                gamma_col_first <= img_clamp.col_first  ;
                gamma_col_last  <= img_clamp.col_last   ;
                gamma_de        <= img_clamp.de         ;
                gamma_data      <= img_clamp_gamma      ;
                gamma_user      <= img_clamp.user       ;
                gamma_valid     <= img_clamp.valid      ;
            end
        end

        assign img_sink.row_first   = gamma_row_first;
        assign img_sink.row_last    = gamma_row_last ;
        assign img_sink.col_first   = gamma_col_first;
        assign img_sink.col_last    = gamma_col_last ;
        assign img_sink.de          = gamma_de       ;
        assign img_sink.data        = gamma_data     ;
        assign img_sink.user        = gamma_user     ;
        assign img_sink.valid       = gamma_valid    ;
    end
    else begin : no_gamma
        assign img_sink.row_first   = img_clamp.row_first       ;
        assign img_sink.row_last    = img_clamp.row_last        ;
        assign img_sink.col_first   = img_clamp.col_first       ;
        assign img_sink.col_last    = img_clamp.col_last        ;
        assign img_sink.de          = img_clamp.de              ;
        assign img_sink.data[0][0]  = img_clamp.data[0][0][9:2] ;
        assign img_sink.data[0][1]  = img_clamp.data[0][1][9:2] ;
        assign img_sink.data[0][2]  = img_clamp.data[0][2][9:2] ;
        assign img_sink.user        = img_clamp.user            ;
        assign img_sink.valid       = img_clamp.valid           ;
    end
    
endmodule



`default_nettype wire



// end of file
