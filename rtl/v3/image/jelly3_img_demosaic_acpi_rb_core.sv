// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_demosaic_acpi_rb_core
        #(
            parameter   int     CH_BITS     = 10                    ,
            parameter   type    ch_t        = logic [CH_BITS-1:0]   ,
            parameter   int     MAX_COLS    = 4096                  ,
            parameter           RAM_TYPE    = "block"               ,
            parameter   bit     RGB_SWAP    = 0                     ,
            parameter   bit     BYPASS_SIZE = 1'b1                  ,
            localparam  type    phase_t     = logic [1:0]           
        )
        (
            input   var phase_t param_phase,
            jelly3_mat_if.s     s_img,
            jelly3_mat_if.m     m_img
        );
    
    localparam  int     TAPS      = s_img.TAPS              ;
    localparam  int     ROWS_BITS = s_img.ROWS_BITS         ;
    localparam  int     COLS_BITS = s_img.COLS_BITS         ;
    localparam  int     DE_BITS   = s_img.DE_BITS           ;
    localparam  int     USER_BITS = s_img.USER_BITS         ;
    localparam  type    rows_t    = logic   [ROWS_BITS-1:0] ;
    localparam  type    cols_t    = logic   [COLS_BITS-1:0] ;
    localparam  type    de_t      = logic   [DE_BITS-1:0]   ;
    localparam  type    user_t    = logic   [USER_BITS-1:0] ;

    rows_t                              img_blk_rows        ;
    cols_t                              img_blk_cols        ;
    logic                               img_blk_row_first   ;
    logic                               img_blk_row_last    ;
    logic                               img_blk_col_first   ;
    logic                               img_blk_col_last    ;
    user_t                              img_blk_user        ;
    de_t                                img_blk_de          ;
    ch_t    [TAPS-1:0][2:0][2:0][1:0]   img_blk_data        ;
    logic                               img_blk_valid       ;
    
    jelly3_mat_buf_blk
            #(
                .ROWS               (3                  ),
                .COLS               (3                  ),
                .TAPS               (TAPS               ),
                .DE_BITS            (DE_BITS            ),
                .USER_BITS          (USER_BITS          ),
                .DATA_BITS          (2 * $bits(ch_t)    ),
                .MAX_COLS           (MAX_COLS           ),
                .RAM_TYPE           (RAM_TYPE           ),
                .BYPASS_SIZE        (BYPASS_SIZE        ),
                .BORDER_MODE        ("REFLECT_101"      )
            )   
        u_mat_buf_blk
            (   
                .reset              (s_img.reset        ),
                .clk                (s_img.clk          ),
                .cke                (s_img.cke          ),

                .s_mat_rows         (s_img.rows         ),
                .s_mat_cols         (s_img.cols         ),
                .s_mat_row_first    (s_img.row_first    ),
                .s_mat_row_last     (s_img.row_last     ),
                .s_mat_col_first    (s_img.col_first    ),
                .s_mat_col_last     (s_img.col_last     ),
                .s_mat_de           (s_img.de           ),
                .s_mat_user         (s_img.user         ),
                .s_mat_data         (s_img.data         ),
                .s_mat_valid        (s_img.valid        ),
                
                .m_mat_rows         (img_blk_rows       ),
                .m_mat_cols         (img_blk_cols       ),
                .m_mat_row_first    (img_blk_row_first  ),
                .m_mat_row_last     (img_blk_row_last   ),
                .m_mat_col_first    (img_blk_col_first  ),
                .m_mat_col_last     (img_blk_col_last   ),
                .m_mat_de           (img_blk_de         ),
                .m_mat_user         (img_blk_user       ),
                .m_mat_data         (img_blk_data       ),
                .m_mat_valid        (img_blk_valid      )
            );
    
    for ( genvar tap = 0; tap < TAPS; tap++ ) begin : loop_calc
        ch_t        acpi_raw;
        ch_t        acpi_r;
        ch_t        acpi_g;
        ch_t        acpi_b;
        
        jelly3_img_demosaic_acpi_rb_calc
                #(
                    .TAPS               (TAPS       ),
                    .TAP_POS            (tap        ),
                    .CH_BITS            ($bits(ch_t)),
                    .ch_t               (ch_t       )
                )
            i_img_demosaic_acpi_rb_calc
                (
                    .reset              (s_img.reset),
                    .clk                (s_img.clk  ),
                    .cke                (s_img.cke  ),
                    
                    .param_phase        (param_phase),
                    
                    .in_line_first      (img_blk_row_first & img_blk_valid  ),
                    .in_pixel_first     (img_blk_col_first & img_blk_valid  ),
                    .in_data            (img_blk_data[tap]                  ),
                    
                    .out_raw            (acpi_raw   ),
                    .out_r              (acpi_r     ),
                    .out_g              (acpi_g     ),
                    .out_b              (acpi_b     )
                );

        localparam  int     DST_DATA_BITS = m_img.DATA_BITS;

        // 4チャネル目があれば RAW を入れる
        assign m_img.data[tap] = RGB_SWAP ? DST_DATA_BITS'({acpi_raw, acpi_b, acpi_g, acpi_r})  :
                                            DST_DATA_BITS'({acpi_raw, acpi_r, acpi_g, acpi_b})  ;
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
        u_mat_delay
            (
                .reset              (m_img.reset        ),
                .clk                (m_img.clk          ),
                .cke                (m_img.cke          ),
                
                .s_mat_rows         (img_blk_rows       ),
                .s_mat_cols         (img_blk_cols       ),
                .s_mat_row_first    (img_blk_row_first  ),
                .s_mat_row_last     (img_blk_row_last   ),
                .s_mat_col_first    (img_blk_col_first  ),
                .s_mat_col_last     (img_blk_col_last   ),
                .s_mat_de           (img_blk_de         ),
                .s_mat_user         (img_blk_user       ),
                .s_mat_valid        (img_blk_valid      ),
                
                .m_mat_rows         (m_img.rows         ),
                .m_mat_cols         (m_img.cols         ),
                .m_mat_row_first    (m_img.row_first    ),
                .m_mat_row_last     (m_img.row_last     ),
                .m_mat_col_first    (m_img.col_first    ),
                .m_mat_col_last     (m_img.col_last     ),
                .m_mat_de           (m_img.de           ),
                .m_mat_user         (m_img.user         ),
                .m_mat_valid        (m_img.valid        )
            );
    
endmodule


`default_nettype wire


// end of file
