// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module image_processing
        #(
            parameter   int     WIDTH_BITS  = 10                            ,
            parameter   int     HEIGHT_BITS = 9                             ,
            parameter   type    width_t     = logic [WIDTH_BITS-1:0]        ,
            parameter   type    height_t    = logic [HEIGHT_BITS-1:0]       ,
            parameter   int     TAPS        = 1                             ,
            parameter   int     RAW_BITS    = 10                            ,
            parameter   type    raw_t       = logic signed  [RAW_BITS-1:0]  ,
            parameter   int     SOBEL_BITS  = RAW_BITS + 8                  ,
            parameter   type    sobel_t     = logic signed  [SOBEL_BITS-1:0],
            parameter   int     CALC_BITS   = $bits(sobel_t) * 2            ,
            parameter   type    calc_t      = logic signed  [CALC_BITS-1:0] ,
            parameter   int     ACC_BITS    = $bits(calc_t) + 20            ,
            parameter   type    acc_t       = logic signed  [ACC_BITS-1:0]  ,
            parameter   int     MAX_COLS    = 4096                          ,
            parameter           RAM_TYPE    = "block"                       ,
            parameter   bit     BYPASS_SIZE = 1'b1                          ,

            parameter           DEVICE      = "RTL"                     
        )
        (
            input   var logic           in_update_req   ,
            input   var width_t         param_width     ,
            input   var height_t        param_height    ,

            jelly3_axi4s_if.s           s_axi4s         ,
            jelly3_axi4s_if.m           m_axi4s         ,

            jelly3_axi4l_if.s           s_axi4l         ,

            output  var acc_t           m_lk_gx2        ,
            output  var acc_t           m_lk_gy2        ,
            output  var acc_t           m_lk_gxy        ,
            output  var acc_t           m_lk_ex         ,
            output  var acc_t           m_lk_ey         ,
            output  var logic           m_lk_valid      
        );


    // ----------------------------------------
    //  local patrameter
    // ----------------------------------------

    localparam  int     ROWS_BITS  = $bits(height_t);
    localparam  int     COLS_BITS  = $bits(width_t);
    localparam  type    rows_t     = logic [ROWS_BITS-1:0];
    localparam  type    cols_t     = logic [COLS_BITS-1:0];

    localparam  int     S_CH_BITS  = s_axi4s.DATA_BITS;
    localparam  int     M_CH_BITS  = m_axi4s.DATA_BITS;


    // ----------------------------------------
    //  Address decoder
    // ----------------------------------------
    
    localparam int DEC_GAUSS = 0;
    localparam int DEC_SEL   = 1;
    localparam int DEC_NUM   = 2;

    jelly3_axi4l_if
            #(
                .ADDR_BITS      (s_axi4l.ADDR_BITS  ),
                .DATA_BITS      (s_axi4l.DATA_BITS  )
            )
        axi4l_dec [DEC_NUM]
            (
                .aresetn        (s_axi4l.aresetn    ),
                .aclk           (s_axi4l.aclk       ),
                .aclken         (s_axi4l.aclken     )
            );
    
    // address map
    assign {axi4l_dec[DEC_GAUSS].addr_base, axi4l_dec[DEC_GAUSS].addr_high} = {40'ha012_1000, 40'ha012_1fff};
    assign {axi4l_dec[DEC_SEL  ].addr_base, axi4l_dec[DEC_SEL  ].addr_high} = {40'ha012_f000, 40'ha012_ffff};

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
                .TAPS       (TAPS           ),
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (S_CH_BITS      ),
                .CH_DEPTH   (1              )
            )
        img_src
            (
                .reset      (reset          ),
                .clk        (clk            ),
                .cke        (cke            )
            );

   jelly3_mat_if
            #(
                .TAPS       (TAPS           ),
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (M_CH_BITS      ),
                .CH_DEPTH   (1              )
            )
        img_sink
            (
                .reset      (reset          ),
                .clk        (clk            ),
                .cke        (cke            )
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

                .img_cke        (cke                ),
                .m_mat          (img_src.m          ),
                .s_mat          (img_sink.s         )
        );
    
    
    // -------------------------------------
    //  Gaussian filter
    // -------------------------------------
    
    jelly3_mat_if
            #(
                .TAPS       (TAPS           ),
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (S_CH_BITS      ),
                .CH_DEPTH   (1              )
            )
        img_gauss
            (
                .reset      (reset          ),
                .clk        (clk            ),
                .cke        (cke            )
            );
    
    jelly3_img_bayer_gaussian
            #(
                .NUM            (4                      ),
                .MAX_COLS       (1024                   ),
                .RAM_TYPE       ("block"                ),
                .BORDER_MODE    ("REPLICATE"            ),
                .BYPASS_SIZE    (1'b1                   ),
                .ROUND          (1'b1                   )
            )
        u_img_bayer_gaussian
            (
                .in_update_req  (in_update_req          ),

                .s_img          (img_src                ),
                .m_img          (img_gauss              ),
            
                .s_axi4l        (axi4l_dec[DEC_GAUSS]   )
        );
    


    // -------------------------------------
    //  frame buffer
    // -------------------------------------

    jelly3_mat_if
            #(
                .TAPS       (1              ),
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (S_CH_BITS      ),
                .CH_DEPTH   (2              )
            )
        img_buf
            (
                .reset      (reset          ),
                .clk        (clk            ),
                .cke        (cke            )
            );

    jelly3_mat_buf_mem
            #(
                .N              (2          ),
                .BUF_SIZE       (640 * 132  ),
                .SDP            (1          ),
                .RAM_TYPE       ("ultra"    ),
                .DOUT_REG       (1          )
            )
        u_mat_buf_mem
            (
                .s_mat          (img_gauss  ),
                .m_mat          (img_buf    )
            );

    jelly3_img_bayer_lk
            #(
                .TAPS               (TAPS               ),
                .CH_BITS            (S_CH_BITS          ),
                .ROWS_BITS          (ROWS_BITS          ),
                .rows_t             (rows_t             ),
                .COLS_BITS          (COLS_BITS          ),
                .cols_t             (cols_t             ),
                .SOBEL_BITS         (SOBEL_BITS         ),
                .sobel_t            (sobel_t            ),
                .CALC_BITS          (CALC_BITS          ),
                .calc_t             (calc_t             ),
                .ACC_BITS           (ACC_BITS           ),
                .acc_t              (acc_t              ),
                .MAX_COLS           (MAX_COLS           ),
                .RAM_TYPE           (RAM_TYPE           ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
            )
        u_img_bayer_lk
            (
                .reset              (img_buf.reset      ),
                .clk                (img_buf.clk        ),
                .cke                (img_buf.cke        ),

                .s_img_rows         (img_buf.rows       ),
                .s_img_cols         (img_buf.cols       ),
                .s_img_row_first    (img_buf.row_first  ),
                .s_img_row_last     (img_buf.row_last   ),
                .s_img_col_first    (img_buf.col_first  ),
                .s_img_col_last     (img_buf.col_last   ),
                .s_img_de           (img_buf.de         ),
                .s_img_data         (img_buf.data       ),
                .s_img_user         (img_buf.user       ),
                .s_img_valid        (img_buf.valid      ),
                
                .m_lk_gx2           (m_lk_gx2           ),
                .m_lk_gy2           (m_lk_gy2           ),
                .m_lk_gxy           (m_lk_gxy           ),
                .m_lk_ex            (m_lk_ex            ),
                .m_lk_ey            (m_lk_ey            ),
                .m_lk_valid         (m_lk_valid         )
            );
    

    // -------------------------------------
    //  output selector
    // -------------------------------------

    localparam int SEL_NUM = 4;

    jelly3_mat_if
            #(
                .TAPS       (TAPS           ),
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (M_CH_BITS      ),
                .CH_DEPTH   (1              )
            )
        img_sel_s [SEL_NUM]
            (
                .reset      (img_sink.reset    ),
                .clk        (img_sink.clk      ),
                .cke        (img_sink.cke      )
            );

    jelly3_img_selector
            #(
                .NUM                (SEL_NUM            ),
                .INIT_CTL_SELECT    ('0                 )
            )
        u_img_selector
            (
                .s_img              (img_sel_s          ),
                .m_img              (img_sink           ),
                .s_axi4l            (axi4l_dec[DEC_SEL] )
            );
    
    assign img_sel_s[0].rows        = img_src.rows                  ;
    assign img_sel_s[0].cols        = img_src.cols                  ;
    assign img_sel_s[0].row_first   = img_src.row_first             ;
    assign img_sel_s[0].row_last    = img_src.row_last              ;
    assign img_sel_s[0].col_first   = img_src.col_first             ;
    assign img_sel_s[0].col_last    = img_src.col_last              ;
    assign img_sel_s[0].de          = img_src.de                    ;
    assign img_sel_s[0].data        = M_CH_BITS'(img_src.data[0][0]);
    assign img_sel_s[0].user        = img_src.user                  ;
    assign img_sel_s[0].valid       = img_src.valid                 ;

    assign img_sel_s[1].rows        = img_buf.rows                  ;
    assign img_sel_s[1].cols        = img_buf.cols                  ;
    assign img_sel_s[1].row_first   = img_buf.row_first             ;
    assign img_sel_s[1].row_last    = img_buf.row_last              ;
    assign img_sel_s[1].col_first   = img_buf.col_first             ;
    assign img_sel_s[1].col_last    = img_buf.col_last              ;
    assign img_sel_s[1].de          = img_buf.de                    ;
    assign img_sel_s[1].data        = M_CH_BITS'(img_buf.data[0][0]);
    assign img_sel_s[1].user        = img_buf.user                  ;
    assign img_sel_s[1].valid       = img_buf.valid                 ;
    
    assign img_sel_s[2].rows        = img_buf.rows                  ;
    assign img_sel_s[2].cols        = img_buf.cols                  ;
    assign img_sel_s[2].row_first   = img_buf.row_first             ;
    assign img_sel_s[2].row_last    = img_buf.row_last              ;
    assign img_sel_s[2].col_first   = img_buf.col_first             ;
    assign img_sel_s[2].col_last    = img_buf.col_last              ;
    assign img_sel_s[2].de          = img_buf.de                    ;
    assign img_sel_s[2].data        = M_CH_BITS'(img_buf.data[0][1]);
    assign img_sel_s[2].user        = img_buf.user                  ;
    assign img_sel_s[2].valid       = img_buf.valid                 ;
    
    assign img_sel_s[3].rows        = img_buf.rows                  ;
    assign img_sel_s[3].cols        = img_buf.cols                  ;
    assign img_sel_s[3].row_first   = img_buf.row_first             ;
    assign img_sel_s[3].row_last    = img_buf.row_last              ;
    assign img_sel_s[3].col_first   = img_buf.col_first             ;
    assign img_sel_s[3].col_last    = img_buf.col_last              ;
    assign img_sel_s[3].de          = img_buf.de                    ;
    assign img_sel_s[3].data        = 512 + M_CH_BITS'(img_buf.data[0][1]) - M_CH_BITS'(img_buf.data[0][0]);
    assign img_sel_s[3].user        = img_buf.user                  ;
    assign img_sel_s[3].valid       = img_buf.valid                 ;

endmodule



`default_nettype wire



// end of file
