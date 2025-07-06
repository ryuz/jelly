
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );
    
    localparam  bit     USE_DE       = 1    ;
    localparam  bit     USE_USER     = 0    ;
    localparam  bit     USE_VALID    = 1    ;
    localparam  int     TAPS         = 4    ;
    localparam  int     DE_BITS      = TAPS ;
    localparam  int     CH_DEPTH     = 1    ;
    localparam  int     CH_BITS      = 8    ;
    localparam  int     ROWS_BITS    = 14   ;
    localparam  int     COLS_BITS    = 16   ;
    localparam  int     USER_BITS    = 1    ;
    localparam  bit     ENDIAN       = 0    ;

    logic   cke = 1'b1;

    jelly3_mat_if
            #(
                .USE_DE             (USE_DE     ),
                .USE_USER           (USE_USER   ),
                .USE_VALID          (USE_VALID  ),
                .TAPS               (TAPS       ),
                .DE_BITS            (DE_BITS    ),
                .CH_DEPTH           (CH_DEPTH   ),
                .CH_BITS            (CH_BITS    ),
                .ROWS_BITS          (ROWS_BITS  ),
                .COLS_BITS          (COLS_BITS  ),
                .USER_BITS          (USER_BITS  )
            )
        mat_src
            (
                .reset   ,
                .clk     ,
                .cke
            );

    jelly3_model_img_m
            #(
                .IMG_CH_DEPTH       (CH_DEPTH           ),
                .IMG_CH_BITS        (CH_BITS            ),
                .IMG_WIDTH          (64                 ),
                .IMG_HEIGHT         (48                 ),
                .COL_BLANK          (0                  ),   // 基本ゼロ
                .ROW_BLANK          (0                  ),   // 末尾にde落ちラインを追加
                .FILE_NAME          (""                 ),
                .FILE_EXT           (""                 ),
                .FILE_IMG_WIDTH     (640                ),
                .FILE_IMG_HEIGHT    (480                ),
                .SEQUENTIAL_FILE    (0                  ),
                .ENDIAN             (ENDIAN             )
            )
        u_model_img_m
            (
                .enable             (1'b1       ),
                .busy               (           ),

                .m_img              (mat_src.m  ),
                .out_x              (           ),
                .out_y              (           ),
                .out_f              (           )
            );


    jelly3_mat_buf_col
            #(
                .TAPS               (TAPS               ),
                .DE_BITS            (DE_BITS            ),
                .COLS               (11                 ),
//              .ANCHOR             (1                  ),
                .ROWS_BITS          (ROWS_BITS          ),
                .COLS_BITS          (COLS_BITS          ),
                .USER_BITS          (1                  ),
                .DATA_BITS          (CH_DEPTH*CH_BITS   ),
//              .BORDER_MODE        ("REPLICATE"        ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
//              .BORDER_MODE        ("CONSTANT"         ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
                .BORDER_MODE        ("REFLECT_101"      ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
//              .BORDER_MODE        ("REFLECT"          ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
                .BORDER_VALUE       (8'haa              ),   // BORDER_MODE == "CONSTANT"
                .ENDIAN             (ENDIAN             )    // 0: little, 1:big
            )
        u_mat_buf_col
            (
                .reset               ,
                .clk                 ,
                .cke                 ,

                .s_mat_rows          (mat_src.rows      ),
                .s_mat_cols          (mat_src.cols      ),
                .s_mat_row_first     (mat_src.row_first ),
                .s_mat_row_last      (mat_src.row_last  ),
                .s_mat_col_first     (mat_src.col_first ),
                .s_mat_col_last      (mat_src.col_last  ),
                .s_mat_de            (mat_src.de        ),
                .s_mat_user          (mat_src.user      ),
                .s_mat_data          (mat_src.data      ),
                .s_mat_valid         (mat_src.valid     ),

                .m_mat_rows          (),
                .m_mat_cols          (),
                .m_mat_row_first     (),
                .m_mat_row_last      (),
                .m_mat_col_first     (),
                .m_mat_col_last      (),
                .m_mat_de            (),
                .m_mat_user          (),
                .m_mat_data          (),
                .m_mat_valid         ()
            );
    


endmodule


`default_nettype wire


// end of file
