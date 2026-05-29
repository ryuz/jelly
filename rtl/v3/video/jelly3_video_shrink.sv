// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   video processing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_video_shrink
        #(
            parameter   int     WIDTH_BITS  = 10                        ,
            parameter   int     HEIGHT_BITS = 9                         ,
            parameter   type    width_t     = logic [WIDTH_BITS-1:0]    ,
            parameter   type    height_t    = logic [HEIGHT_BITS-1:0]   ,
            parameter   int     CH_DEPTH    = 3                         ,
            parameter   int     N           = 2                         ,
            parameter   int     M           = 2                         ,
            parameter   int     NC          = N - 1                     ,
            parameter   int     MC          = M - 1                     ,
            parameter   int     SN          = N                         ,
            parameter   int     SM          = M                         ,
            parameter   int     MAX_COLS    = 4096                      ,
            parameter           RAM_TYPE    = "block"                   ,
            parameter   bit     BYPASS_SIZE = 1'b1                      ,
            parameter   bit     S_SIGNED    = 1'b0                      ,
            parameter   bit     M_SIGNED    = 1'b0                      ,
            parameter   int     SCALE_MUL_BITS = 16                     ,
            parameter   type    scale_mul_t = logic [SCALE_MUL_BITS-1:0],
            parameter   scale_mul_t SCALE_MUL = scale_mul_t'(1)         ,
            parameter   int     SCALE_SHIFT = 0                         ,
            parameter   bit     ROUNDING    = 1'b0                      ,
            parameter           DEVICE      = "RTL"                     
        )
        (
            input   var width_t         param_width     ,
            input   var height_t        param_height    ,

            jelly3_axi4s_if.s           s_axi4s         ,
            jelly3_axi4s_if.m           m_axi4s         
        );

    // ----------------------------------------
    //  local parameter
    // ----------------------------------------

    localparam  int     ROWS_BITS  = $bits(height_t);
    localparam  int     COLS_BITS  = $bits(width_t);
    localparam  type    rows_t     = logic [ROWS_BITS-1:0];
    localparam  type    cols_t     = logic [COLS_BITS-1:0];

    localparam  int     S_CH_BITS  = s_axi4s.DATA_BITS / CH_DEPTH;
    localparam  int     S_CH_DEPTH = CH_DEPTH;
    localparam  int     M_CH_BITS  = m_axi4s.DATA_BITS / CH_DEPTH;
    localparam  int     M_CH_DEPTH = CH_DEPTH;


    // ----------------------------------------
    //  AXI4-Stream <=> Image Interface
    // ----------------------------------------

    logic           reset ;
    logic           clk   ;
    logic           cke   ;
    assign  reset = ~s_axi4s.aresetn;
    assign  clk   = s_axi4s.aclk;
    
    jelly3_mat_if
            #(
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (S_CH_BITS      ),
                .CH_DEPTH   (S_CH_DEPTH     )
            )
        img_src
            (
                .reset      (reset  ),
                .clk        (clk    ),
                .cke        (cke    )
            );

    jelly3_mat_if
            #(
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (M_CH_BITS      ),
                .CH_DEPTH   (M_CH_DEPTH     )
            )
        img_sink
            (
                .reset      (reset  ),
                .clk        (clk    ),
                .cke        (cke    )
            );

    jelly3_axi4s_mat
            #(
                .ROWS_BITS      ($bits(rows_t)      ),
                .COLS_BITS      ($bits(cols_t)      ),
                .BLANK_BITS     (4                  ),
                .CKE_BUFG       (0                  )
            )
        u_axi4s_mat
            (
                .param_rows     (param_height       ),
                .param_cols     (param_width        ),
                .param_blank    (4'd5               ),
                .s_axi4s        (s_axi4s            ),
                .m_axi4s        (m_axi4s            ),

                .out_cke        (cke                ),
                .m_mat          (img_src.m          ),
                .s_mat          (img_sink.s         )
            );


    // ----------------------------------------
    //  Image Shrink (Average Pooling)
    // ----------------------------------------

    jelly3_img_ave_pooling
            #(
                .N              (N                  ),
                .M              (M                  ),
                .NC             (NC                 ),
                .MC             (MC                 ),
                .SN             (SN                 ),
                .SM             (SM                 ),
                .MAX_COLS       (MAX_COLS           ),
                .RAM_TYPE       (RAM_TYPE           ),
                .BYPASS_SIZE    (BYPASS_SIZE        ),
                .S_SIGNED       (S_SIGNED           ),
                .M_SIGNED       (M_SIGNED           ),
                .SCALE_MUL_BITS (SCALE_MUL_BITS     ),
                .scale_mul_t    (scale_mul_t        ),
                .SCALE_MUL      (SCALE_MUL          ),
                .SCALE_SHIFT    (SCALE_SHIFT        ),
                .ROUNDING       (ROUNDING           )
            )
        u_img_ave_pooling
            (
                .s_img          (img_src.s          ),
                .m_img          (img_sink.m         )
            );

endmodule


`default_nettype wire


// end of file
