
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
    localparam  int     CH_DEPTH     = 2    ;
    localparam  int     CH_BITS      = 4    ;

    localparam  int     TAPS         = 4                        ;
    localparam  int     ROWS_BITS    = 16                       ;
    localparam  type    rows_t       = logic [ROWS_BITS-1:0]    ;
    localparam  int     COLS_BITS    = 16                       ;
    localparam  type    cols_t       = logic [COLS_BITS-1:0]    ;
    localparam  int     DE_BITS      = TAPS                     ;
    localparam  type    de_t         = logic [DE_BITS-1:0]      ;
    localparam  int     USER_BITS    = 1                        ;
    localparam  type    user_t       = logic [USER_BITS-1:0]    ;
    localparam  int     DATA_BITS    = CH_DEPTH*CH_BITS         ;
    localparam  type    data_t       = logic [DATA_BITS-1:0]    ;
    localparam  int     ROWS         = 5                        ;
    localparam  int     ANCHOR       = 2;                       ;
//  localparam  int     ANCHOR       = (ROWS-1) / 2             ;
    localparam  int     MAX_COLS     = 1024                     ;
//  localparam          BORDER_MODE  = "CONSTANT"               ;
//  localparam          BORDER_MODE  = "REPLICATE"              ;   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
    localparam          BORDER_MODE  = "REFLECT_101"            ;   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
    localparam  data_t  BORDER_VALUE = 8'haa                    ;   // BORDER_MODE == "CONSTANT"
    localparam          RAM_TYPE     = "block"                  ;
    localparam  bit     BYPASS_SIZE  = 1'b1                     ;
    localparam  bit     ENDIAN       = 0                        ;   // 0: little, 1:big


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

    jelly3_model_img_m
            #(
                .IMG_CH_DEPTH       (CH_DEPTH           ),
                .IMG_CH_BITS        (CH_BITS            ),
                .IMG_WIDTH          (16                 ),
                .IMG_HEIGHT         (12                 ),
                .COL_BLANK          (0                  ),   // 基本ゼロ
                .ROW_BLANK          (0                  ),   // 末尾にde落ちラインを追加
                .FILE_NAME          (""                 ),
                .FILE_EXT           (""                 ),
                .FILE_IMG_WIDTH     (640                ),
                .FILE_IMG_HEIGHT    (480                ),
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

    rows_t                          mat_dst_rows        ;
    cols_t                          mat_dst_cols        ;
    logic                           mat_dst_row_first   ;
    logic                           mat_dst_row_last    ;
    logic                           mat_dst_col_first   ;
    logic                           mat_dst_col_last    ;
    de_t                            mat_dst_de          ;
    user_t                          mat_dst_user        ;
    data_t  [TAPS-1:0][ROWS-1:0]    mat_dst_data        ;
    logic                           mat_dst_valid       ;

    jelly3_mat_buf_row
            #(
                .TAPS               (TAPS               ),
                .DE_BITS            (DE_BITS            ),
                .ROWS               (ROWS               ),
                .USER_BITS          (USER_BITS          ),
                .DATA_BITS          (CH_DEPTH*CH_BITS   ),
                .ANCHOR             (ANCHOR             ),
                .BORDER_MODE        (BORDER_MODE        ),   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
                .BORDER_VALUE       (BORDER_VALUE       ),   // BORDER_MODE == "CONSTANT"
                .ENDIAN             (ENDIAN             )    // 0: little, 1:big
            )
        u_mat_buf_row
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

                .m_mat_rows          (mat_dst_rows      ),
                .m_mat_cols          (mat_dst_cols      ),
                .m_mat_row_first     (mat_dst_row_first ),
                .m_mat_row_last      (mat_dst_row_last  ),
                .m_mat_col_first     (mat_dst_col_first ),
                .m_mat_col_last      (mat_dst_col_last  ),
                .m_mat_de            (mat_dst_de        ),
                .m_mat_user          (mat_dst_user      ),
                .m_mat_data          (mat_dst_data      ),
                .m_mat_valid         (mat_dst_valid     )
            );
    

    jelly3_mat_if
            #(
                .USE_DE             (USE_DE     ),
                .USE_USER           (USE_USER   ),
                .USE_VALID          (USE_VALID  ),
                .TAPS               (TAPS       ),
                .DE_BITS            (DE_BITS    ),
                .CH_DEPTH           (1          ),
                .CH_BITS            (8          ),
                .USER_BITS          (USER_BITS  )
            )
        mat_dst [0:ROWS-1]
            (
                .reset   ,
                .clk     ,
                .cke
            );
    
    for ( genvar y = 0; y < ROWS; y++ ) begin : loop_y
        assign mat_dst[y].rows      = mat_dst_rows     ;
        assign mat_dst[y].cols      = mat_dst_cols     ;
        assign mat_dst[y].row_first = mat_dst_row_first;
        assign mat_dst[y].row_last  = mat_dst_row_last ;
        assign mat_dst[y].col_first = mat_dst_col_first;
        assign mat_dst[y].col_last  = mat_dst_col_last ;
        assign mat_dst[y].de        = mat_dst_de       ;
        assign mat_dst[y].user      = mat_dst_user     ;
        assign mat_dst[y].valid     = mat_dst_valid    ;           

        for ( genvar i = 0; i < TAPS; i++ ) begin
            assign mat_dst[y].data[i] = mat_dst_data[i][y];
        end
    end

//  localparam DST_FILE_EXT = ".pgm";
    localparam DST_FILE_EXT = "_log.txt";

    logic  [31:0]    frame_num   ;
    jelly3_model_img_dump
            #(
                .FORMAT             ("P2"           ),
                .FILE_NAME          ("output/img0_" ),
                .FILE_EXT           (DST_FILE_EXT   ),
                .SEQUENTIAL_FILE    (1              ),
                .ENDIAN             (0              )
            )
        u_model_img_dump_0
            (
                .s_img              (mat_dst[0]     ),

                .frame_num          (frame_num      )
            );

    jelly3_model_img_dump
            #(
                .FORMAT             ("P2"           ),
                .FILE_NAME          ("output/img1_" ),
                .FILE_EXT           (DST_FILE_EXT   ),
                .SEQUENTIAL_FILE    (1              ),
                .ENDIAN             (0              )
            )
        u_model_img_dump_1
            (
                .s_img              (mat_dst[1]     ),

                .frame_num          (               )
            );

    jelly3_model_img_dump
            #(
                .FORMAT             ("P2"           ),
                .FILE_NAME          ("output/img2_" ),
                .FILE_EXT           (DST_FILE_EXT   ),
                .SEQUENTIAL_FILE    (1              ),
                .ENDIAN             (0              )
            )
        u_model_img_dump_2
            (
                .s_img              (mat_dst[2]     ),

                .frame_num          (               )
            );

    jelly3_model_img_dump
            #(
                .FORMAT             ("P2"           ),
                .FILE_NAME          ("output/img3_" ),
                .FILE_EXT           (DST_FILE_EXT   ),
                .SEQUENTIAL_FILE    (1              ),
                .ENDIAN             (0              )
            )
        u_model_img_dump_3
            (
                .s_img              (mat_dst[3]     ),

                .frame_num          (               )
            );


    jelly3_model_img_dump
            #(
                .FORMAT             ("P2"           ),
                .FILE_NAME          ("output/img4_" ),
                .FILE_EXT           (DST_FILE_EXT   ),
                .SEQUENTIAL_FILE    (1              ),
                .ENDIAN             (0              )
            )
        u_model_img_dump_4
            (
                .s_img              (mat_dst[4]     ),

                .frame_num          (               )
            );

    always_ff @(posedge clk) begin
        if ( !reset ) begin
            if ( frame_num >= 1 ) begin
                $finish;
            end
        end
    end

endmodule


`default_nettype wire


// end of file
