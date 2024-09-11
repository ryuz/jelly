
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
    localparam  int     USER_BITS    = 1    ;

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
                .USER_BITS          (USER_BITS  )
            )
        mat_src
            (
                .reset   ,
                .clk     ,
                .cke
            );

    jelly3_model_mat_m
            #(
                .IMG_CH_DEPTH       (CH_DEPTH           ),
                .IMG_CH_BITS        (CH_BITS            ),
                .IMG_COLS           (64                 ),
                .IMG_ROWS           (48                 ),
                .COL_BLANK          (0                  ),   // 基本ゼロ
                .ROW_BLANK          (0                  ),   // 末尾にde落ちラインを追加
                .FILE_NAME          (""                 ),
                .FILE_EXT           (""                 ),
                .FILE_IMG_WIDTH     (640                ),
                .FILE_IMG_HEIGHT    (480                ),
                .SEQUENTIAL_FILE    (0                  ),
                .ENDIAN             (0                  )
            )
        u_model_mat_m
            (
                .enable             (1'b1       ),
                .busy               (           ),

                .m_mat              (mat_src.m  ),
                .out_x              (           ),
                .out_y              (           ),
                .out_f              (           )
            );


    jelly3_mat_col_buffer
            #(
                .TAPS               (TAPS               ),
                .DE_BITS            (DE_BITS            ),
                .COLS               (7                  ),
                .USER_BITS          (1                  ),
                .DATA_WIDTH         (CH_DEPTH*CH_BITS   ),
                .ANCHOR             (3                  ),
//              .BORDER_MODE        ("REPLICATE"        ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
                .BORDER_MODE        ("CONSTANT"         ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
                .BORDER_VALUE       (8'haa              ),   // BORDER_MODE == "CONSTANT"
                .ENDIAN             (0                  )    // 0: little, 1:big
            )
        u_mat_col_buffer
            (
                .reset               ,
                .clk                 ,
                .cke                 ,

                .s_img_row_first     (mat_src.row_first ),
                .s_img_row_last      (mat_src.row_last  ),
                .s_img_col_first     (mat_src.col_first ),
                .s_img_col_last      (mat_src.col_last  ),
                .s_img_de            (mat_src.de        ),
                .s_img_user          (mat_src.user      ),
                .s_img_data          (mat_src.data      ),
                .s_img_valid         (mat_src.valid     ),

                .m_img_row_first     (),
                .m_img_row_last      (),
                .m_img_col_first     (),
                .m_img_col_last      (),
                .m_img_de            (),
                .m_img_user          (),
                .m_img_data          (),
                .m_img_valid         ()
            );
    


endmodule


`default_nettype wire


// end of file
