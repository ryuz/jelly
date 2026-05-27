`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   bit     IS_SIGNED           = 1'b0
        )
        (
            input   var logic   reset,
            input   var logic   clk
        );

    localparam  bit     USE_DE           = 1;
    localparam  bit     USE_USER         = 0;
    localparam  bit     USE_VALID        = 1;
    localparam  int     TAPS             = 1;
    localparam  int     DE_BITS          = TAPS;
    localparam  int     CH_DEPTH         = 3;
    localparam  int     CH_BITS          = 8;
    localparam  int     ROWS_BITS        = 16;
    localparam  int     COLS_BITS        = 16;
    localparam  int     USER_BITS        = 1;
    localparam  bit     ENDIAN           = 0;

    localparam  int     IMG_WIDTH        = 16;
    localparam  int     IMG_HEIGHT       = 12;

    localparam  int     N                = 3;
    localparam  int     M                = 3;
    localparam  int     MAX_COLS         = 1024;

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
                .reset,
                .clk,
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
                .ROWS_BITS          (ROWS_BITS  ),
                .COLS_BITS          (COLS_BITS  ),
                .USER_BITS          (USER_BITS  )
            )
        mat_dst
            (
                .reset,
                .clk,
                .cke
            );

    jelly3_img_max_pooling
            #(
                .N                  (N          ),
                .M                  (M          ),
                .MAX_COLS           (MAX_COLS   ),
                .RAM_TYPE           ("block"    ),
                .BYPASS_SIZE        (1'b1       ),
                .IS_SIGNED          (IS_SIGNED  )
            )
        u_img_max_pooling
            (
                .s_img              (mat_src.s  ),
                .m_img              (mat_dst.m  )
            );

    jelly3_model_img_m
            #(
                .IMG_CH_DEPTH       (CH_DEPTH               ),
                .IMG_CH_BITS        (CH_BITS                ),
                .IMG_WIDTH          (IMG_WIDTH              ),
                .IMG_HEIGHT         (IMG_HEIGHT             ),
                .COL_BLANK          (0                      ),
                .ROW_BLANK          (0                      ),
                .FILE_NAME          ("../pattern/input_"    ),
                .FILE_EXT           (".ppm"                 ),
                .FILE_IMG_WIDTH     (IMG_WIDTH              ),
                .FILE_IMG_HEIGHT    (IMG_HEIGHT             ),
                .SEQUENTIAL_FILE    (1                      ),
                .ENDIAN             (ENDIAN                 )
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

    logic [31:0] frame_num;
    jelly3_model_img_dump
            #(
                .FORMAT             ("P3"       ),
                .FILE_NAME          ("dut_"     ),
                .FILE_EXT           (".ppm"     ),
                .SEQUENTIAL_FILE    (1          ),
                .ENDIAN             (ENDIAN     )
            )
        u_model_img_dump
            (
                .s_img              (mat_dst.s  ),
                .frame_num          (frame_num  )
            );

    always_ff @(posedge clk) begin
        if ( !reset ) begin
            if ( frame_num >= 1 ) begin
                $display("[TB] finished at frame_num=%0d", frame_num);
                $finish;
            end
        end
    end

endmodule


`default_nettype wire


// end of file
