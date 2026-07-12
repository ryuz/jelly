// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module video_raw_to_rgb
        #(
            parameter   int     WIDTH_BITS  = 14                        ,
            parameter   int     HEIGHT_BITS = 12                        ,
            parameter   type    width_t     = logic [WIDTH_BITS-1:0]    ,
            parameter   type    height_t    = logic [HEIGHT_BITS-1:0]   ,
            parameter   int     M_CH_DEPTH  = 4                         ,
            parameter           DEVICE      = "RTL"                     
        )
        (
            input   var logic           aclken, 
            input   var logic           in_update_req,
            input   var width_t         param_width,
            input   var height_t        param_height,

            jelly3_axi4s_if.s           s_axi4s,
            jelly3_axi4s_if.m           m_axi4s,

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

    localparam DEC_WB     = 0;
    localparam DEC_DEMOS  = 1;
    localparam DEC_COLMAT = 2;
    localparam DEC_GAMMA  = 3;
    localparam DEC_NUM    = 4;

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
    assign {axi4l_dec[DEC_WB    ].addr_base, axi4l_dec[DEC_WB    ].addr_high} = {40'ha030_1000, 40'ha030_1fff};
    assign {axi4l_dec[DEC_DEMOS ].addr_base, axi4l_dec[DEC_DEMOS ].addr_high} = {40'ha030_2000, 40'ha030_2fff};
    assign {axi4l_dec[DEC_COLMAT].addr_base, axi4l_dec[DEC_COLMAT].addr_high} = {40'ha030_3000, 40'ha030_3fff};
    assign {axi4l_dec[DEC_GAMMA ].addr_base, axi4l_dec[DEC_GAMMA ].addr_high} = {40'ha032_0000, 40'ha032_ffff};

    jelly3_axi4l_addr_decoder
            #(
                .NUM            (DEC_NUM    ),
                .DEC_ADDR_BITS  (20         )
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
                .param_blank    (4'd5               ),
                .s_axi4s        (s_axi4s            ),
                .m_axi4s        (m_axi4s            ),

                .out_cke        (cke                ),
                .m_mat          (img_src.m          ),
                .s_mat          (img_sink.s         )
        );
    
    /*
    assign img_sink.row_first   = img_src.row_first;
    assign img_sink.row_last    = img_src.row_last ;
    assign img_sink.col_first   = img_src.col_first;
    assign img_sink.col_last    = img_src.col_last ;
    assign img_sink.de          = img_src.de       ;
    assign img_sink.data        = img_src.data     ;
    assign img_sink.user        = img_src.user     ;
    assign img_sink.valid       = img_src.valid    ;
    */


    // -------------------------------------
    //  Black Level Correction
    // -------------------------------------

    // 現像用データサイズ
    localparam  int     CH_BITS = S_CH_BITS + 2;
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
                .INIT_CTL_CONTROL   (2'b01                  ),
                .INIT_PARAM_PHASE   (2'b00                  ),
                .INIT_PARAM_OFFSET0 ('0                     ),
                .INIT_PARAM_OFFSET1 ('0                     ),
                .INIT_PARAM_OFFSET2 ('0                     ),
                .INIT_PARAM_OFFSET3 ('0                     ) 
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
                .CH_BITS            ($bits(ch_t)),
                .ch_t               (ch_t       ),
                .MAX_COLS           (4096       ),
                .RAM_TYPE           ("block"    ),
                .INIT_PARAM_PHASE   (2'b00      )
            )
        u_img_demosaic_acpi
            (
                .in_update_req      (in_update_req          ),
                .s_img              (img_wb.s               ),
                .m_img              (img_demos.m            ),
                .s_axi4l            (axi4l_dec[DEC_DEMOS].s )
            );
    
//   assign img_sink.row_first   = img_demos.row_first;
//   assign img_sink.row_last    = img_demos.row_last ;
//   assign img_sink.col_first   = img_demos.col_first;
//   assign img_sink.col_last    = img_demos.col_last ;
//   assign img_sink.de          = img_demos.de       ;
//   assign img_sink.data        = img_demos.data     ;
//   assign img_sink.user        = img_demos.user     ;
//   assign img_sink.valid       = img_demos.valid    ;


    jelly3_mat_if
            #(
                .CH_BITS        ($bits(ch_t)    ),
                .CH_DEPTH       (4              )
            )
         img_colmat
            (
                .reset          (img_src.reset  ),
                .clk            (img_src.clk    ),
                .cke            (img_src.cke    )
            );

    jelly3_img_color_matrix
            #(
                .CH_BITS                ($bits(ch_t)            ),
                .ch_t                   (ch_t                   ),
                .COEFF_INT_BITS         (9                      ),
                .COEFF_FRAC_BITS        (16                     ),
                .COEFF3_INT_BITS        (17                     ),
                .COEFF3_FRAC_BITS       (8                      ),
                .STATIC_COEFF           (1                      ),
                .INIT_PARAM_CLIP_MIN0   (12'd0                  ),
                .INIT_PARAM_CLIP_MAX0   (12'd1023               ),
                .INIT_PARAM_CLIP_MIN1   (12'd0                  ),
                .INIT_PARAM_CLIP_MAX1   (12'd1023               ),
                .INIT_PARAM_CLIP_MIN2   (12'd0                  ),
                .INIT_PARAM_CLIP_MAX2   (12'd1023               )
            )
        u_img_color_matrix
            (
                .in_update_req          (in_update_req          ),
                .s_img                  (img_demos.s            ),
                .m_img                  (img_colmat.m           ),
                .s_axi4l                (axi4l_dec[DEC_COLMAT].s)
            );


    // -------------------------------------
    //  clamp
    // -------------------------------------

    jelly3_mat_if
            #(
                .CH_BITS        (M_CH_BITS          ),
                .CH_DEPTH       (M_CH_DEPTH         )
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
                .inv            (1'b0               ),
                .zero           (1'b0               ),
                .min_value      (12'd0              ),
                .max_value      (12'd1023           ),
                .s_mat          (img_colmat.s       ),
                .m_mat          (img_clamp.m        )
            );
    

    // -------------------------------------
    //  gamma correction
    // -------------------------------------
    jelly3_mat_if
            #(
                .CH_BITS        (M_CH_BITS          ),
                .CH_DEPTH       (M_CH_DEPTH         )
            )
         img_gamma
            (
                .reset          (img_src.reset      ),
                .clk            (img_src.clk        ),
                .cke            (img_src.cke        )
            );

    jelly3_img_gamma_correction
            #(
                .CH_DEPTH           (M_CH_DEPTH                 ),
                .S_DATA_BITS        (M_CH_BITS                  ),
                .M_DATA_BITS        (M_CH_BITS                  ),
                .REGADR_BITS        (14                         ),
                .RAM_TYPE           ("block"                    ),
                .INIT_CTL_CONTROL   (3'b000                     ),
                .INIT_PARAM_ENABLE  ('0                         )
            )
        u_img_gamma_correction
            (
                .in_update_req      (in_update_req              ),
                
                .s_img              (img_clamp.s                ),
                .m_img              (img_gamma.m                ),

                .s_axi4l            (axi4l_dec[DEC_GAMMA ].s    )
            );


    assign img_sink.row_first   = img_gamma.row_first;
    assign img_sink.row_last    = img_gamma.row_last ;
    assign img_sink.col_first   = img_gamma.col_first;
    assign img_sink.col_last    = img_gamma.col_last ;
    assign img_sink.de          = img_gamma.de       ;
    assign img_sink.data        = img_gamma.data     ;
    assign img_sink.user        = img_gamma.user     ;
    assign img_sink.valid       = img_gamma.valid    ;


    
endmodule



`default_nettype wire



// end of file
