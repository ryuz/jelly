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
            parameter   int     WIDTH_BITS  = 13                        ,
            parameter   int     HEIGHT_BITS = 12                        ,
            parameter   type    width_t     = logic [WIDTH_BITS-1:0]    ,
            parameter   type    height_t    = logic [HEIGHT_BITS-1:0]   ,
            parameter   int     M_CH_DEPTH  = 4                         ,
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
                .INIT_CTL_CONTROL   (2'b01                  ),
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
                .CH_BITS            ($bits(ch_t)),
                .ch_t               (ch_t       ),
                .MAX_COLS           (2048       ),
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


    // -------------------------------------
    //  clamp
    // -------------------------------------

    jelly3_mat_if
            #(
                .CH_BITS        (img_sink.CH_BITS   ),
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
                .min_value      (11'd0              ),
                .max_value      (11'd1023           ),
                .s_mat          (img_demos.s        ),
                .m_mat          (img_clamp.m        )
            );

    assign img_sink.row_first   = img_clamp.row_first;
    assign img_sink.row_last    = img_clamp.row_last ;
    assign img_sink.col_first   = img_clamp.col_first;
    assign img_sink.col_last    = img_clamp.col_last ;
    assign img_sink.de          = img_clamp.de       ;
    assign img_sink.data        = img_clamp.data     ;
    assign img_sink.user        = img_clamp.user     ;
    assign img_sink.valid       = img_clamp.valid    ;



    /*
    wire    [WB_DAT_WIDTH-1:0]          wb_colmat_dat_o;
    wire                                wb_colmat_stb_i;
    wire                                wb_colmat_ack_o;
    
    jelly2_img_color_matrix
            #(
                .USER_WIDTH             (TUSER_WIDTH+10),
                .DATA_WIDTH             (DATA_WIDTH),
                .INTERNAL_WIDTH         (DATA_WIDTH+2),
                
                .COEFF_INT_WIDTH        (9),
                .COEFF_FRAC_WIDTH       (16),
                .COEFF3_INT_WIDTH       (9),
                .COEFF3_FRAC_WIDTH      (16),
                .STATIC_COEFF           (1),
                .DEVICE                 (DEVICE),
                
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_PARAM_MATRIX00    (25'h010000),
                .INIT_PARAM_MATRIX01    (25'h000000),
                .INIT_PARAM_MATRIX02    (25'h000000),
                .INIT_PARAM_MATRIX03    (25'h000000),
                .INIT_PARAM_MATRIX10    (25'h000000),
                .INIT_PARAM_MATRIX11    (25'h010000),
                .INIT_PARAM_MATRIX12    (25'h000000),
                .INIT_PARAM_MATRIX13    (25'h000000),
                .INIT_PARAM_MATRIX20    (25'h000000),
                .INIT_PARAM_MATRIX21    (25'h000000),
                .INIT_PARAM_MATRIX22    (25'h010000),
                .INIT_PARAM_MATRIX23    (25'h000000),
                .INIT_PARAM_CLIP_MIN0   ({DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX0   ({DATA_WIDTH{1'b1}}),
                .INIT_PARAM_CLIP_MIN1   ({DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX1   ({DATA_WIDTH{1'b1}}),
                .INIT_PARAM_CLIP_MIN2   ({DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX2   ({DATA_WIDTH{1'b1}})
            )
        i_img_color_matrix
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .in_update_req          (in_update_req),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_colmat_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_colmat_stb_i),
                .s_wb_ack_o             (wb_colmat_ack_o),
                
                .s_img_row_first        (img_demos_row_first),
                .s_img_row_last         (img_demos_row_last),
                .s_img_col_first        (img_demos_col_first),
                .s_img_col_last         (img_demos_col_last),
                .s_img_de               (img_demos_de),
                .s_img_user             ({img_demos_user, img_demos_raw}),
                .s_img_color0           (img_demos_r),
                .s_img_color1           (img_demos_g),
                .s_img_color2           (img_demos_b),
                .s_img_valid            (img_demos_valid),
                
                .m_img_row_first        (img_sink_row_first),
                .m_img_row_last         (img_sink_row_last),
                .m_img_col_first        (img_sink_col_first),
                .m_img_col_last         (img_sink_col_last),
                .m_img_de               (img_sink_de),
                .m_img_user             ({img_sink_user, img_sink_data[DATA_WIDTH*3 +: DATA_WIDTH]}),
                .m_img_color0           (img_sink_data[DATA_WIDTH*2 +: DATA_WIDTH]),
                .m_img_color1           (img_sink_data[DATA_WIDTH*1 +: DATA_WIDTH]),
                .m_img_color2           (img_sink_data[DATA_WIDTH*0 +: DATA_WIDTH]),
                .m_img_valid            (img_sink_valid)
            );
    
    assign wb_demos_stb_i  = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:8] == 0);
    assign wb_colmat_stb_i = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:8] == 1);
    
    assign s_wb_dat_o      = wb_demos_stb_i  ? wb_demos_dat_o  :
                             wb_colmat_stb_i ? wb_colmat_dat_o :
                             '0;
    
    assign s_wb_ack_o      = wb_demos_stb_i  ? wb_demos_ack_o  :
                             wb_colmat_stb_i ? wb_colmat_ack_o :
                             s_wb_stb_i;
    */
    
endmodule



`default_nettype wire



// end of file
