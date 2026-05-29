`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );

    localparam  int     DATA_BITS       = 24;
    localparam  int     COMPONENTS      = 3 ;
    localparam  int     PIXEL_BITS      = DATA_BITS / COMPONENTS;

    localparam          IMG_FILE        = "../../../../../data/images/standard_images/color/Mandrill_256x256";
    localparam          IMG_EXT         = ".ppm";
    localparam  int     IMG_WIDTH       = 256;
    localparam  int     IMG_HEIGHT      = 256;

    localparam  int     N               = 2;
    localparam  int     M               = 2;
    localparam  int     SN              = 2;
    localparam  int     SM              = 2;
    localparam  int     OUT_WIDTH       = IMG_WIDTH  / SM;
    localparam  int     OUT_HEIGHT      = IMG_HEIGHT / SN;
    localparam  int     FRAME_NUM       = 10;

    localparam  int     SRC_BUSY_RATE   = 30;
    localparam  int     DST_BUSY_RATE   = 30;

    localparam  int     SCALE_MUL_BITS  = 16;
    localparam  logic [SCALE_MUL_BITS-1:0]
                        SCALE_MUL       = SCALE_MUL_BITS'(16'd1);
    localparam  int     SCALE_SHIFT     = 2;

    localparam  type    width_t         = logic [15:0];
    localparam  type    height_t        = logic [15:0];

    logic                           cke = 1'b1;
    width_t                         param_width  = width_t'(IMG_WIDTH);
    height_t                        param_height = height_t'(IMG_HEIGHT);

    jelly3_axi4s_if
            #(
                .DATA_BITS          (DATA_BITS)
            )
        axi4s_src
            (
                .aresetn            (~reset    ),
                .aclk               (clk       ),
                .aclken             (cke       )
            );

    jelly3_axi4s_if
            #(
                .DATA_BITS          (DATA_BITS)
            )
        axi4s_dst
            (
                .aresetn            (~reset    ),
                .aclk               (clk       ),
                .aclken             (cke       )
            );

    jelly3_video_shrink
            #(
                .width_t            (width_t         ),
                .height_t           (height_t        ),
                .N                  (N               ),
                .M                  (M               ),
                .SN                 (SN              ),
                .SM                 (SM              ),
                .MAX_COLS           (IMG_WIDTH       ),
                .SCALE_MUL_BITS     (SCALE_MUL_BITS  ),
                .SCALE_MUL          (SCALE_MUL       ),
                .SCALE_SHIFT        (SCALE_SHIFT     )
            )
        u_video_shrink
            (
                .param_width        (param_width     ),
                .param_height       (param_height    ),
                .s_axi4s            (axi4s_src.s     ),
                .m_axi4s            (axi4s_dst.m     )
            );


    logic [31:0] src_frame;
    logic        src_busy;
    jelly3_model_axi4s_m
            #(
                .COMPONENTS         (COMPONENTS      ),
                .DATA_BITS          (PIXEL_BITS      ),
                .IMG_WIDTH          (IMG_WIDTH       ),
                .IMG_HEIGHT         (IMG_HEIGHT      ),
                .H_BLANK            (0               ),
                .V_BLANK            (0               ),
                .FILE_NAME          (IMG_FILE        ),
                .FILE_EXT           (IMG_EXT         ),
                .FILE_IMG_WIDTH     (IMG_WIDTH       ),
                .FILE_IMG_HEIGHT    (IMG_HEIGHT      ),
                .SEQUENTIAL_FILE    (0               ),
                .BUSY_RATE          (SRC_BUSY_RATE   ),
                .RANDOM_SEED        (123             )
            )
        u_model_axi4s_m
            (
                .enable             (src_frame < FRAME_NUM),
                .busy               (src_busy        ),
                .m_axi4s            (axi4s_src.m     ),
                .out_x              (                ),
                .out_y              (                ),
                .out_f              (src_frame       )
            );

    jelly3_model_axi4s_s
            #(
                .BUSY_RATE          (DST_BUSY_RATE   ),
                .RANDOM_SEED        (321             )
            )
        u_model_axi4s_s
            (
                .s_axi4s            (axi4s_dst.s     )
            );


    jelly3_model_axi4s_dump
            #(
                .COMPONENTS         (COMPONENTS      ),
                .DATA_BITS          (PIXEL_BITS      ),
                .X_BITS             ($bits(width_t)  ),
                .x_t                (width_t         ),
                .Y_BITS             ($bits(height_t) ),
                .y_t                (height_t        ),
                .FORMAT             ("P3"            ),
                .FILE_NAME          ("src_"          ),
                .FILE_EXT           (".ppm"          ),
                .SEQUENTIAL_FILE    (1               ),
                .ENDIAN             (0               )
            )
        u_model_axi4s_dump_src
            (
                .param_width        (width_t'(IMG_WIDTH)   ),
                .param_height       (height_t'(IMG_HEIGHT) ),
                .frame_num          (                      ),
                .mon_axi4s          (axi4s_src.mon         )
            );


    logic [31:0] frame_num;
    jelly3_model_axi4s_dump
            #(
                .COMPONENTS         (COMPONENTS      ),
                .DATA_BITS          (PIXEL_BITS      ),
                .X_BITS             ($bits(width_t)  ),
                .x_t                (width_t         ),
                .Y_BITS             ($bits(height_t) ),
                .y_t                (height_t        ),
                .FORMAT             ("P3"            ),
                .FILE_NAME          ("output_"       ),
                .FILE_EXT           (".ppm"          ),
                .SEQUENTIAL_FILE    (1               ),
                .ENDIAN             (0               )
            )
        u_model_axi4s_dump_out
            (
                .param_width        (width_t'(OUT_WIDTH)   ),
                .param_height       (height_t'(OUT_HEIGHT) ),
                .frame_num          (frame_num             ),
                .mon_axi4s          (axi4s_dst.mon         )
            );

    logic src_started;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            src_started <= 1'b0;
        end
        else begin
            if ( !src_started && src_busy ) begin
                src_started <= 1'b1;
            end

            if ( src_started && !src_busy && (src_frame >= FRAME_NUM) ) begin
                $display("[TB] finished at src_frame=%0d frame_num=%0d", src_frame, frame_num);
                $finish;
            end
        end
    end

endmodule


`default_nettype wire


// end of file
