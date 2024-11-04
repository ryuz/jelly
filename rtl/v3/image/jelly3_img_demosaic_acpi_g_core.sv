// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_demosaic_acpi_g_core
        #(
            parameter   int     CH_BITS     = 10                    ,
            parameter   type    ch_t        = logic [CH_BITS-1:0]   ,
            parameter   int     MAX_COLS    = 4096                  ,
            parameter           RAM_TYPE    = "block"               ,
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
    
    rows_t                          img_blk_rows        ;
    cols_t                          img_blk_cols        ;
    logic                           img_blk_row_first   ;
    logic                           img_blk_row_last    ;
    logic                           img_blk_col_first   ;
    logic                           img_blk_col_last    ;
    user_t                          img_blk_user        ;
    de_t                            img_blk_de          ;
    ch_t    [TAPS-1:0][4:0][4:0]    img_blk_raw         ;
    logic                           img_blk_valid       ;
    
    jelly3_mat_buf_blk
            #(
                .TAPS               (TAPS               ),
                .DE_BITS            (DE_BITS            ),
                .USER_BITS          (USER_BITS          ),
                .DATA_BITS          (CH_BITS            ),
                .ROWS               (5                  ),
                .COLS               (5                  ),
                .MAX_COLS           (MAX_COLS           ),
                .RAM_TYPE           (RAM_TYPE           ),
                .BORDER_MODE        ("REFLECT_101"      ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
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
                .m_mat_data         (img_blk_raw        ),
                .m_mat_valid        (img_blk_valid      )
            );
    


    for ( genvar tap = 0; tap < TAPS; tap++ ) begin : loop_calc
        ch_t        acpi_raw;
        ch_t        acpi_g;

        jelly3_img_demosaic_acpi_g_calc
                #(
                    .TAPS               (TAPS           ),
                    .TAP_POS            (tap            ),
                    .CH_BITS            ($bits(ch_t)    ),
                    .ch_t               (ch_t           )
                )
            u_img_demosaic_acpi_g_calc
                (
                    .reset              (s_img.reset    ),
                    .clk                (s_img.clk      ),
                    .cke                (s_img.cke      ),

                    .param_phase        (param_phase    ),
                    
                    .in_line_first      (img_blk_row_first & img_blk_valid  ),
                    .in_pixel_first     (img_blk_col_first & img_blk_valid  ),
                    .in_raw             (img_blk_raw[tap]                   ),
                    
                    .out_raw            (acpi_raw       ),
                    .out_g              (acpi_g         )
                );
        assign m_img.data[tap] = {acpi_g, acpi_raw};
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
    
    // assertion
    initial begin
        sva_data_bits   : assert ( $bits(ch_t) == s_img.DATA_BITS ) else $warning("$bits(ch_t) != s_img.DATA_BITS");
        sva_m_data_bits : assert ( m_img.DATA_BITS == s_img.DATA_BITS * 2) else $warning("m_img.DATA_BITS != s_img.DATA_BITS * 2");
    end
    always_comb begin
        sva_connect_clk : assert (m_img.clk === s_img.clk);
    end

endmodule


`default_nettype wire


// end of file
