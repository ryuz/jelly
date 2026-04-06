// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_color_matrix_core
        #(
            parameter   int     CH_BITS          = 10                                   ,
            parameter   type    ch_t             = logic [CH_BITS-1:0]                  ,
            parameter   int     INTERNAL_BITS    = CH_BITS + 2                          ,
            parameter   type    internal_t       = logic signed [INTERNAL_BITS-1:0]     ,
            parameter   int     COEFF_INT_BITS   = 17                                   ,
            parameter   int     COEFF_FRAC_BITS  = 8                                    ,
            parameter   int     COEFF3_INT_BITS  = COEFF_INT_BITS                       ,
            parameter   int     COEFF3_FRAC_BITS = COEFF_FRAC_BITS                      ,
            parameter   bit     STATIC_COEFF     = 1                                    ,
            parameter           DEVICE           = "RTL"                                ,
            localparam  int     COEFF_BITS       = COEFF_INT_BITS + COEFF_FRAC_BITS     ,
            localparam  int     COEFF3_BITS      = COEFF3_INT_BITS + COEFF3_FRAC_BITS
        )
        (
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix00  ,
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix01  ,
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix02  ,
            input   var logic   signed  [COEFF3_BITS-1:0]   param_matrix03  ,
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix10  ,
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix11  ,
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix12  ,
            input   var logic   signed  [COEFF3_BITS-1:0]   param_matrix13  ,
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix20  ,
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix21  ,
            input   var logic   signed  [COEFF_BITS-1:0]    param_matrix22  ,
            input   var logic   signed  [COEFF3_BITS-1:0]   param_matrix23  ,

            input   var logic           [CH_BITS-1:0]       param_clip_min0 ,
            input   var logic           [CH_BITS-1:0]       param_clip_max0 ,
            input   var logic           [CH_BITS-1:0]       param_clip_min1 ,
            input   var logic           [CH_BITS-1:0]       param_clip_max1 ,
            input   var logic           [CH_BITS-1:0]       param_clip_min2 ,
            input   var logic           [CH_BITS-1:0]       param_clip_max2 ,

            jelly3_mat_if.s     s_img,
            jelly3_mat_if.m     m_img
        );

    localparam  int     CH_NUM           = s_img.CH_DEPTH;
    localparam  int     DE_BITS          = s_img.DE_BITS;
    localparam  int     USER_BITS        = s_img.USER_BITS;
    localparam  int     PACKED_USER_BITS = USER_BITS + DE_BITS + 4 + CH_NUM * CH_BITS;

    localparam  type    de_t   = logic [DE_BITS-1:0];
    localparam  type    user_t = logic [USER_BITS-1:0];


    // matrix
    logic   signed  [CH_BITS:0]             s_color0_signed;
    logic   signed  [CH_BITS:0]             s_color1_signed;
    logic   signed  [CH_BITS:0]             s_color2_signed;
    assign s_color0_signed = {1'b0, ch_t'(s_img.data[0][0])};
    assign s_color1_signed = {1'b0, ch_t'(s_img.data[0][1])};
    assign s_color2_signed = {1'b0, ch_t'(s_img.data[0][2])};

    logic                                   matrix_row_first;
    logic                                   matrix_row_last;
    logic                                   matrix_col_first;
    logic                                   matrix_col_last;
    logic   [DE_BITS-1:0]                   matrix_de;
    logic   [USER_BITS-1:0]                 matrix_user;
    logic   [CH_BITS-1:0]   [CH_NUM-1:0]   matrix_data_in;
    logic   signed  [INTERNAL_BITS-1:0]     matrix_color0;
    logic   signed  [INTERNAL_BITS-1:0]     matrix_color1;
    logic   signed  [INTERNAL_BITS-1:0]     matrix_color2;
    logic                                   matrix_valid;

    jelly_fixed_matrix3x4
            #(
                .COEFF_INT_WIDTH        (COEFF_INT_BITS         ),
                .COEFF_FRAC_WIDTH       (COEFF_FRAC_BITS        ),
                .COEFF3_INT_WIDTH       (COEFF3_INT_BITS        ),
                .COEFF3_FRAC_WIDTH      (COEFF3_FRAC_BITS       ),

                .S_FIXED_INT_WIDTH      (CH_BITS+1              ),
                .S_FIXED_FRAC_WIDTH     (0                      ),

                .M_FIXED_INT_WIDTH      (INTERNAL_BITS          ),
                .M_FIXED_FRAC_WIDTH     (0                      ),

                .USER_WIDTH             (PACKED_USER_BITS       ),

                .STATIC_COEFF           (STATIC_COEFF           ),

                .MASTER_IN_REGS         (0                      ),
                .MASTER_OUT_REGS        (0                      ),

                .DEVICE                 (DEVICE                 )
            )
        u_fixed_matrix3x4
            (
                .reset                  (s_img.reset            ),
                .clk                    (s_img.clk              ),
                .cke                    (s_img.cke              ),

                .coeff00                (param_matrix00         ),
                .coeff01                (param_matrix01         ),
                .coeff02                (param_matrix02         ),
                .coeff03                (param_matrix03         ),
                .coeff10                (param_matrix10         ),
                .coeff11                (param_matrix11         ),
                .coeff12                (param_matrix12         ),
                .coeff13                (param_matrix13         ),
                .coeff20                (param_matrix20         ),
                .coeff21                (param_matrix21         ),
                .coeff22                (param_matrix22         ),
                .coeff23                (param_matrix23         ),

                .s_user                 ({
                                            s_img.user,
                                            s_img.de,
                                            s_img.row_first,
                                            s_img.row_last,
                                            s_img.col_first,
                                            s_img.col_last,
                                            s_img.data[0]
                                        }),
                .s_fixed_x              (s_color0_signed        ),
                .s_fixed_y              (s_color1_signed        ),
                .s_fixed_z              (s_color2_signed        ),
                .s_valid                (s_img.valid            ),
                .s_ready                (                       ),

                .m_user                 ({
                                            matrix_user,
                                            matrix_de,
                                            matrix_row_first,
                                            matrix_row_last,
                                            matrix_col_first,
                                            matrix_col_last,
                                            matrix_data_in
                                        }),
                .m_fixed_x              (matrix_color0          ),
                .m_fixed_y              (matrix_color1          ),
                .m_fixed_z              (matrix_color2          ),
                .m_valid                (matrix_valid           ),
                .m_ready                (1'b1                   )
            );


    // clip
    logic   signed  [INTERNAL_BITS-1:0]     clip_min0;
    logic   signed  [INTERNAL_BITS-1:0]     clip_max0;
    logic   signed  [INTERNAL_BITS-1:0]     clip_min1;
    logic   signed  [INTERNAL_BITS-1:0]     clip_max1;
    logic   signed  [INTERNAL_BITS-1:0]     clip_min2;
    logic   signed  [INTERNAL_BITS-1:0]     clip_max2;
    assign clip_min0 = INTERNAL_BITS'({1'b0, param_clip_min0});
    assign clip_max0 = INTERNAL_BITS'({1'b0, param_clip_max0});
    assign clip_min1 = INTERNAL_BITS'({1'b0, param_clip_min1});
    assign clip_max1 = INTERNAL_BITS'({1'b0, param_clip_max1});
    assign clip_min2 = INTERNAL_BITS'({1'b0, param_clip_min2});
    assign clip_max2 = INTERNAL_BITS'({1'b0, param_clip_max2});

    logic                                   clip_row_first  ;
    logic                                   clip_row_last   ;
    logic                                   clip_col_first  ;
    logic                                   clip_col_last   ;
    logic   [DE_BITS-1:0]                   clip_de         ;
    logic   [USER_BITS-1:0]                 clip_user       ;
    logic   [CH_BITS-1:0]   [CH_NUM-1:0]   clip_data_in    ;
    ch_t                                    clip_color0     ;
    ch_t                                    clip_color1     ;
    ch_t                                    clip_color2     ;
    logic                                   clip_valid      ;

    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            clip_row_first  <= 'x;
            clip_row_last   <= 'x;
            clip_col_first  <= 'x;
            clip_col_last   <= 'x;
            clip_de         <= 'x;
            clip_user       <= 'x;
            clip_data_in    <= 'x;
            clip_color0     <= 'x;
            clip_color1     <= 'x;
            clip_color2     <= 'x;
            clip_valid      <= 1'b0;
        end
        else if ( s_img.cke ) begin
            clip_row_first  <= matrix_row_first;
            clip_row_last   <= matrix_row_last;
            clip_col_first  <= matrix_col_first;
            clip_col_last   <= matrix_col_last;
            clip_de         <= matrix_de;
            clip_user       <= matrix_user;
            clip_data_in    <= matrix_data_in;
            clip_valid      <= matrix_valid;

            clip_color0     <= ch_t'(matrix_color0[CH_BITS-1:0]);
            clip_color1     <= ch_t'(matrix_color1[CH_BITS-1:0]);
            clip_color2     <= ch_t'(matrix_color2[CH_BITS-1:0]);

            if ( matrix_color0 < clip_min0 ) clip_color0 <= ch_t'(clip_min0[CH_BITS-1:0]);
            if ( matrix_color0 > clip_max0 ) clip_color0 <= ch_t'(clip_max0[CH_BITS-1:0]);
            if ( matrix_color1 < clip_min1 ) clip_color1 <= ch_t'(clip_min1[CH_BITS-1:0]);
            if ( matrix_color1 > clip_max1 ) clip_color1 <= ch_t'(clip_max1[CH_BITS-1:0]);
            if ( matrix_color2 < clip_min2 ) clip_color2 <= ch_t'(clip_min2[CH_BITS-1:0]);
            if ( matrix_color2 > clip_max2 ) clip_color2 <= ch_t'(clip_max2[CH_BITS-1:0]);
        end
    end

    assign m_img.rows      = s_img.rows;
    assign m_img.cols      = s_img.cols;
    assign m_img.row_first = clip_row_first;
    assign m_img.row_last  = clip_row_last;
    assign m_img.col_first = clip_col_first;
    assign m_img.col_last  = clip_col_last;
    assign m_img.de        = clip_de;
    assign m_img.user      = clip_user;
    always_comb begin : p_m_data
        m_img.data[0]    = 'x;
        m_img.data[0][0] = clip_color0;
        m_img.data[0][1] = clip_color1;
        m_img.data[0][2] = clip_color2;
        for (int i = 3; i < CH_NUM; i++) begin
            m_img.data[0][i] = clip_data_in[i];
        end
    end
    assign m_img.valid     = clip_valid;

    // assertion
    initial begin
        sva_ch_bits : assert ( CH_BITS == s_img.CH_BITS ) else $warning("CH_BITS != s_img.CH_BITS");
        sva_ch_num  : assert ( CH_NUM  >= 3             ) else $error  ("CH_NUM must be >= 3");
    end
    always_comb begin
        sva_connect_reset : assert (m_img.reset === s_img.reset) else $error("m_img.reset != s_img.reset");
        sva_connect_clk   : assert (m_img.clk   === s_img.clk  ) else $error("m_img.clk != s_img.clk"  );
        sva_connect_cke   : assert (m_img.cke   === s_img.cke  ) else $error("m_img.cke != s_img.cke"  );
    end

endmodule


`default_nettype wire


// end of file
