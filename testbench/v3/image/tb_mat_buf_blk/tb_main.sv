
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
    localparam  int     CH_DEPTH     = 3    ;
    localparam  int     CH_BITS      = 8    ;
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
                .USER_BITS          (USER_BITS  )
            )
        mat_src
            (
                .reset   ,
                .clk     ,
                .cke
            );

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
        mat_dst
            (
                .reset   ,
                .clk     ,
                .cke
            );

    localparam  type    ch_t         = logic [CH_BITS-1:0]      ;
    localparam  type    data_t       = ch_t  [CH_DEPTH-1:0]     ;
    localparam  type    de_t         = logic [DE_BITS-1:0]      ;
    localparam  type    user_t       = logic [USER_BITS-1:0]    ;
    localparam  int     ROWS         = 31                       ;
    localparam  int     COLS         = 31                       ;
    localparam  int     ROW_ANCHOR   = (ROWS-1) / 2             ;
    localparam  int     COL_ANCHOR   = (COLS-1) / 2             ;
 
//  logic                                   mat_row_first     ;
//  logic                                   mat_row_last      ;
//  logic                                   mat_col_first     ;
//  logic                                   mat_col_last      ;
//  de_t                                    mat_de            ;
//  user_t                                  mat_user          ;
//  data_t  [TAPS-1:0][ROWS-1:0][COLS-1:0]  mat_data          ;
//  logic                                   mat_valid         ;
    data_t  [TAPS-1:0][ROWS-1:0][COLS-1:0]  mat_dst_data      ;
    
    jelly3_mat_buf_blk
            #(
                .TAPS               (TAPS               ),
                .DE_BITS            (DE_BITS            ),
                .USER_BITS          (USER_BITS          ),
                .DATA_BITS          (CH_DEPTH*CH_BITS   ),
                .ROWS               (ROWS               ),
                .COLS               (COLS               ),
                .ROW_ANCHOR         (ROW_ANCHOR         ),
                .COL_ANCHOR         (COL_ANCHOR         ),
//              .BORDER_MODE        ("REPLICATE"        ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
//              .BORDER_MODE        ("CONSTANT"         ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
                .BORDER_MODE        ("REFLECT_101"      ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
//              .BORDER_MODE        ("REFLECT"          ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
                .BORDER_VALUE       (24'h00ff00         ),   // BORDER_MODE == "CONSTANT"
                .ENDIAN             (ENDIAN             )    // 0: little, 1:big
            )
        u_mat_buf_blk
            (
                .reset               ,
                .clk                 ,
                .cke                 ,

                .s_mat_row_first     (mat_src.row_first ),
                .s_mat_row_last      (mat_src.row_last  ),
                .s_mat_col_first     (mat_src.col_first ),
                .s_mat_col_last      (mat_src.col_last  ),
                .s_mat_de            (mat_src.de        ),
                .s_mat_user          (mat_src.user      ),
                .s_mat_data          (mat_src.data      ),
                .s_mat_valid         (mat_src.valid     ),

                .m_mat_row_first     (mat_dst.row_first ),
                .m_mat_row_last      (mat_dst.row_last  ),
                .m_mat_col_first     (mat_dst.col_first ),
                .m_mat_col_last      (mat_dst.col_last  ),
                .m_mat_de            (mat_dst.de        ),
                .m_mat_user          (mat_dst.user      ),
                .m_mat_data          (mat_dst_data      ),
                .m_mat_valid         (mat_dst.valid     )
            );
    
    assign mat_dst.rows = mat_src.rows;
    assign mat_dst.cols = mat_src.cols;


    // --------------------------------------------------
    //  model
    // --------------------------------------------------

//  localparam          FILE_NAME       = "";
    localparam          FILE_NAME       = "../../../../../data/images/windowswallpaper/Chrysanthemum_320x240.ppm";
//  localparam          FILE_NAME       = "../../../../../data/images/windowswallpaper/Penguins_320x240.ppm";
    localparam  int     FILE_IMG_WIDTH  = 320;
    localparam  int     FILE_IMG_HEIGHT = 240;
    localparam  int     IMG_WIDTH       = 320;
    localparam  int     IMG_HEIGHT      = 240;

    jelly3_model_img_m
            #(
                .IMG_CH_DEPTH       (CH_DEPTH           ),
                .IMG_CH_BITS        (CH_BITS            ),
                .IMG_WIDTH          (IMG_WIDTH          ),
                .IMG_HEIGHT         (IMG_HEIGHT         ),
                .COL_BLANK          (0                  ),   // 基本ゼロ
                .ROW_BLANK          (0                  ),   // 末尾にde落ちラインを追加
                .FILE_NAME          (FILE_NAME          ),
                .FILE_EXT           (""                 ),
                .FILE_IMG_WIDTH     (FILE_IMG_WIDTH     ),
                .FILE_IMG_HEIGHT    (FILE_IMG_HEIGHT    ),
                .SEQUENTIAL_FILE    (0                  ),
                .ENDIAN             (ENDIAN             )
            )
        u_model_mat_m
            (
                .enable             (1'b1       ),
                .busy               (           ),

                .m_img              (mat_src.m  ),
                .out_x              (           ),
                .out_y              (           ),
                .out_f              (           )
            );
    
    for ( genvar tap = 0; tap < TAPS; tap++ ) begin : loop_data
//      assign mat_dst.data[tap] = mat_dst_data[tap][0][0];
        assign mat_dst.data[tap] = mat_dst_data[tap][ROWS-1][COLS-1];
    end

    jelly3_model_img_s
            #(
                .FORMAT             ("P3"               ),
                .FILE_NAME          ("img_"             ),
                .FILE_EXT           (".ppm"             ),
                .SEQUENTIAL_FILE    (1                  ),
                .ENDIAN             (ENDIAN             )
            )
        u_model_img_s
            (
                .s_img              (mat_dst.s          ),
                .frame_num          (                   )
            );


endmodule


`default_nettype wire


// end of file
