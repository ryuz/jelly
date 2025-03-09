// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_bayer_lk
        #(
            parameter   int     TAPS        = 1                             ,
            parameter   int     DE_BITS     = TAPS                          ,
            parameter   type    de_t        = logic         [DE_BITS-1:0]   ,
            parameter   int     CH_DEPTH    = 2                             ,
            parameter   int     CH_BITS     = 8                             ,
            parameter   type    ch_t        = logic         [CH_BITS-1:0]   ,
            parameter   type    data_t      = ch_t          [CH_DEPTH-1:0]  ,
            parameter   int     USER_BITS   = 1                             ,
            parameter   type    user_t      = logic         [USER_BITS-1:0] ,
            parameter   int     ROWS_BITS   = 16                            ,
            parameter   type    rows_t      = logic         [ROWS_BITS-1:0] ,
            parameter   int     COLS_BITS   = 16                            ,
            parameter   type    cols_t      = logic         [COLS_BITS-1:0] ,
            parameter   int     SOBEL_BITS  = $bits(ch_t) + 8               ,
            parameter   type    sobel_t     = logic signed  [SOBEL_BITS-1:0],
            parameter   int     CALC_BITS   = $bits(sobel_t) * 2            ,
            parameter   type    calc_t      = logic signed  [CALC_BITS-1:0] ,
            parameter   int     ACC_BITS    = $bits(calc_t) + 20            ,
            parameter   type    acc_t       = logic signed  [ACC_BITS-1:0]  ,
            parameter   int     MAX_COLS    = 4096                          ,
            parameter           RAM_TYPE    = "block"                       ,
            parameter   bit     BYPASS_SIZE = 1'b1                          
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            input   var rows_t              s_img_rows      ,
            input   var cols_t              s_img_cols      ,
            input   var logic               s_img_row_first ,
            input   var logic               s_img_row_last  ,
            input   var logic               s_img_col_first ,
            input   var logic               s_img_col_last  ,
            input   var de_t                s_img_de        ,
            input   var data_t  [TAPS-1:0]  s_img_data      ,
            input   var user_t              s_img_user      ,
            input   var logic               s_img_valid     ,

            output  var rows_t              m_img_rows      ,
            output  var cols_t              m_img_cols      ,
            output  var logic               m_img_row_first ,
            output  var logic               m_img_row_last  ,
            output  var logic               m_img_col_first ,
            output  var logic               m_img_col_last  ,
            output  var de_t                m_img_de        ,
            output  var data_t  [TAPS-1:0]  m_img_data      ,
            output  var logic               m_img_valid     
        );
    
    localparam  int     RAW_BITS  = $bits(ch_t)                     ;
    localparam  type    raw_t     = logic           [RAW_BITS-1:0]  ;


    // ------------------------------------------------
    //  Sobel Filter
    // ------------------------------------------------

    rows_t                          img_blk_rows        ;
    cols_t                          img_blk_cols        ;
    logic                           img_blk_row_first   ;
    logic                           img_blk_row_last    ;
    logic                           img_blk_col_first   ;
    logic                           img_blk_col_last    ;
    user_t                          img_blk_user        ;
    de_t                            img_blk_de          ;
    data_t  [TAPS-1:0][4:0][4:0]    img_blk_raw         ;
    logic                           img_blk_valid       ;
    
    jelly3_mat_buf_blk
            #(
                .TAPS               (TAPS               ),
                .DE_BITS            (DE_BITS            ),
                .USER_BITS          (USER_BITS          ),
                .DATA_BITS          (CH_BITS * 2        ),
                .ROWS               (5                  ),
                .COLS               (5                  ),
                .MAX_COLS           (MAX_COLS           ),
                .RAM_TYPE           (RAM_TYPE           ),
                .BORDER_MODE        ("REFLECT_101"      ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
            )
        u_mat_buf_blk
            (
                .reset              (reset              ),
                .clk                (clk                ),
                .cke                (cke                ),

                .s_mat_rows         (s_img_rows         ),
                .s_mat_cols         (s_img_cols         ),
                .s_mat_row_first    (s_img_row_first    ),
                .s_mat_row_last     (s_img_row_last     ),
                .s_mat_col_first    (s_img_col_first    ),
                .s_mat_col_last     (s_img_col_last     ),
                .s_mat_de           (s_img_de           ),
                .s_mat_user         (s_img_user         ),
                .s_mat_data         (s_img_data         ),
                .s_mat_valid        (s_img_valid        ),
                
                .m_mat_rows         (img_blk_rows       ),
                .m_mat_cols         (img_blk_cols       ),
                .m_mat_row_first    (img_blk_row_first  ),
                .m_mat_row_last     (img_blk_row_last   ),
                .m_mat_col_first    (img_blk_col_first  ),
                .m_mat_col_last     (img_blk_col_last   ),
                .m_mat_de           (img_blk_de         ),
                .m_mat_user         (img_blk_user       ),
                .m_mat_data         (img_blk_raw        ),
                .m_mat_valid        (img_blk_valid      )
            );
    

    rows_t                  img_sobel_rows      ;
    cols_t                  img_sobel_cols      ;
    logic                   img_sobel_row_first ;
    logic                   img_sobel_row_last  ;
    logic                   img_sobel_col_first ;
    logic                   img_sobel_col_last  ;
    user_t                  img_sobel_user      ;
    de_t                    img_sobel_de        ;
    raw_t   [TAPS-1:0][1:0] img_sobel_raw       ;
    calc_t  [TAPS-1:0]      img_sobel_diff      ;
    calc_t  [TAPS-1:0]      img_sobel_gradx     ;
    calc_t  [TAPS-1:0]      img_sobel_grady     ;
    logic                   img_sobel_valid     ;

    for ( genvar i = 0; i < TAPS; i++ ) begin : loop_sobel
        jelly3_img_bayer_lk_sobel
                #(
                    .RAW_BITS           (RAW_BITS           ),
                    .raw_t              (raw_t              ),
                    .CALC_BITS          ($bits(sobel_t)     ),
                    .calc_t             (calc_t             )
                )
            u_img_bayer_lk_sobel
                (
                    .reset              (reset              ),
                    .clk                (clk                ),
                    .cke                (cke                ),

                    .in_raw             (img_blk_raw    [i] ),

                    .out_raw            (img_sobel_raw  [i] ),
                    .out_diff           (img_sobel_diff [i] ),
                    .out_gradx          (img_sobel_gradx[i] ),
                    .out_grady          (img_sobel_grady[i] )
                );
    end
    
    jelly3_mat_delay
            #(
                .ROWS_BITS          (ROWS_BITS          ),
                .COLS_BITS          (COLS_BITS          ),
                .DE_BITS            (DE_BITS            ),
                .USER_BITS          (USER_BITS          ),
                .LATENCY            (7                  ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
            )
        u_img_delay
            (
                .reset              (reset              ),
                .clk                (clk                ),
                .cke                (cke                ),
                
                .s_mat_rows         (img_blk_rows       ),
                .s_mat_cols         (img_blk_cols       ),
                .s_mat_row_first    (img_blk_row_first  ),
                .s_mat_row_last     (img_blk_row_last   ),
                .s_mat_col_first    (img_blk_col_first  ),
                .s_mat_col_last     (img_blk_col_last   ),
                .s_mat_de           (img_blk_de         ),
                .s_mat_user         (img_blk_user       ),
                .s_mat_valid        (img_blk_valid      ),
                
                .m_mat_rows         (img_sobel_rows     ),
                .m_mat_cols         (img_sobel_cols     ),
                .m_mat_row_first    (img_sobel_row_first),
                .m_mat_row_last     (img_sobel_row_last ),
                .m_mat_col_first    (img_sobel_col_first),
                .m_mat_col_last     (img_sobel_col_last ),
                .m_mat_de           (img_sobel_de       ),
                .m_mat_user         (img_sobel_user     ),
                .m_mat_valid        (img_sobel_valid    )
            );
    
    // ------------------------------------------------
    //  Lucas Kanade 
    // ------------------------------------------------

    for ( genvar i = 0; i < TAPS; i++ ) begin : loop_translation
        jelly3_img_bayer_lk_translation








endmodule


`default_nettype wire


// end of file
