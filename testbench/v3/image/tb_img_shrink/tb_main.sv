`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );

    localparam  int     TAPS             = 1    ;
    localparam  int     DE_BITS          = TAPS ;
    localparam  int     CH_DEPTH         = 3    ;
    localparam  int     CH_BITS          = 8    ;

    localparam          IMG_FILE         = "../../../../../data/images/standard_images/color/Mandrill_256x256.ppm";
    localparam  int     IMG_WIDTH        = 256  ;
    localparam  int     IMG_HEIGHT       = 256  ;

    localparam  int     N                = 2    ;
    localparam  int     M                = 2    ;
    localparam  int     MAX_COLS         = 1024 ;

    localparam  int     SCALE_MUL_BITS   = 16;
    localparam  logic [SCALE_MUL_BITS-1:0]
                        SCALE_MUL        = SCALE_MUL_BITS'(16'd1);
    localparam  int     SCALE_SHIFT      = 2;

    logic   cke = 1'b1;

    jelly3_mat_if
            #(
                .TAPS               (TAPS       ),
                .CH_DEPTH           (CH_DEPTH   ),
                .CH_BITS            (CH_BITS    )
            )
        mat_src
            (
                .reset,
                .clk,
                .cke
            );

    jelly3_mat_if
            #(
                .TAPS               (TAPS       ),
                .DE_BITS            (DE_BITS    ),
                .CH_DEPTH           (CH_DEPTH   ),
                .CH_BITS            (CH_BITS    )
            )
        mat_dst
            (
                .reset,
                .clk,
                .cke
            );

    jelly3_img_ave_pooling
            #(
                .N                  (N              ),
                .M                  (M              ),
                .MAX_COLS           (MAX_COLS       ),
                .RAM_TYPE           ("block"        ),
                .BYPASS_SIZE        (1'b1           ),
                .SCALE_MUL_BITS     (SCALE_MUL_BITS ),
                .SCALE_MUL          (SCALE_MUL      ),
                .SCALE_SHIFT        (SCALE_SHIFT    ),
                .ROUNDING           (1'b0           )
            )
        u_img_ave_pooling
            (
                .s_img              (mat_src.s      ),
                .m_img              (mat_dst.m      )
            );

    jelly3_model_img_m
            #(
                .IMG_CH_DEPTH       (CH_DEPTH                ),
                .IMG_CH_BITS        (CH_BITS                 ),
                .IMG_WIDTH          (IMG_WIDTH               ),
                .IMG_HEIGHT         (IMG_HEIGHT              ),
                .COL_BLANK          (0                       ),
                .ROW_BLANK          (0                       ),
                .FILE_NAME          (IMG_FILE                ),
                .FILE_EXT           (                        ),
                .FILE_IMG_WIDTH     (IMG_WIDTH               ),
                .FILE_IMG_HEIGHT    (IMG_HEIGHT              ),
                .SEQUENTIAL_FILE    (0                       ),
                .ENDIAN             (0                       )
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
                .FILE_NAME          ("output_"  ),
                .FILE_EXT           (".ppm"     ),
                .SEQUENTIAL_FILE    (1          ),
                .ENDIAN             (0          )
            )
        u_model_img_dump
            (
                .s_img              (mat_dst.s  ),
                .frame_num          (frame_num  )
            );

    always_ff @(posedge clk) begin
        if ( !reset ) begin
            if ( frame_num >= 10 ) begin
                $display("[TB] finished at frame_num=%0d", frame_num);
                $finish;
            end
        end
    end

endmodule


`default_nettype wire


// end of file
