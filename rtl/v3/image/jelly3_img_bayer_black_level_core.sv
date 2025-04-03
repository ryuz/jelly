// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Black Level Correction
module jelly3_img_bayer_black_level_core
        #(
            parameter   int     S_DATA_BITS = 10                            ,
            parameter   type    s_data_t    = logic [S_DATA_BITS-1:0]       ,
            parameter   int     M_DATA_BITS = S_DATA_BITS + 1               ,
            parameter   type    m_data_t    = logic signed [M_DATA_BITS-1:0],
            parameter   int     OFFSET_BITS = S_DATA_BITS                   ,
            parameter   type    offset_t    = logic [OFFSET_BITS-1:0]       ,
            parameter   bit     BYPASS_SIZE = 1'b1                          ,
            localparam  type    phase_t     = logic [1:0]                   
        )
        (
            input   var logic               enable,
            input   var phase_t             param_phase,
            input   var offset_t    [3:0]   param_offset,
            jelly3_mat_if.s                 s_img,
            jelly3_mat_if.m                 m_img
        );

    localparam  int     TAPS      = s_img.TAPS          ;
    localparam  int     ROWS_BITS = s_img.ROWS_BITS     ;
    localparam  int     COLS_BITS = s_img.COLS_BITS     ;
    localparam  int     DE_BITS   = s_img.DE_BITS       ;
    localparam  int     USER_BITS = s_img.USER_BITS     ;

    localparam  type    de_t      = logic    [DE_BITS  -1:0];
    localparam  type    user_t    = logic    [USER_BITS-1:0];

    localparam  int     CALC_BITS = ($bits(s_data_t) > $bits(m_data_t)) ? $bits(s_data_t)+1 : $bits(m_data_t)+1;
    localparam  type    calc_t    = logic  signed  [CALC_BITS-1:0];
    localparam  bit     SIGNED    = calc_t'(s_data_t'(calc_t'(-1))) == calc_t'(-1);

    localparam calc_t   MAX_VALUE = SIGNED ? calc_t'({1'b0, {($bits(m_data_t)-1){1'b1}}}) : calc_t'({1'b0, {$bits(m_data_t){1'b1}}});
    localparam calc_t   MIN_VALUE = SIGNED ? calc_t'({1'b1, {($bits(m_data_t)-1){1'b0}}}) : calc_t'({1'b0, {$bits(m_data_t){1'b0}}});



    for ( genvar tap = 0; tap < TAPS; tap++ ) begin : loop_calc
        jelly3_img_bayer_black_level_calc
                #(
                    .TAPS               (TAPS           ),
                    .TAP_POS            (tap            ),

                    .S_DATA_BITS        ($bits(s_data_t)),
                    .s_data_t           (s_data_t       ),
                    .M_DATA_BITS        ($bits(m_data_t)),
                    .m_data_t           (m_data_t       ),
                    .OFFSET_BITS        (OFFSET_BITS    )
                )
            u_img_bayer_black_level_calc
                (
                    .reset              (s_img.reset    ),
                    .clk                (s_img.clk      ),
                    .cke                (s_img.cke      ),

                    .enable             (enable         ),
                    .param_phase        (param_phase    ),
                    .param_offset       (param_offset   ),
                    
                    .s_row_first        (s_img.row_first),
                    .s_col_first        (s_img.col_first),
                    .s_data             (s_img.data[tap]),
                    
                    .m_data             (m_img.data[tap])
                );
    end
    
    jelly3_mat_delay
            #(
                .ROWS_BITS          (ROWS_BITS          ),
                .COLS_BITS          (COLS_BITS          ),
                .DE_BITS            (DE_BITS            ),
                .USER_BITS          (USER_BITS          ),
                .LATENCY            (3                  ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
            )
        u_img_delay
            (
                .reset              (m_img.reset        ),
                .clk                (m_img.clk          ),
                .cke                (m_img.cke          ),
                
                .s_mat_rows         (s_img.rows         ),
                .s_mat_cols         (s_img.cols         ),
                .s_mat_row_first    (s_img.row_first    ),
                .s_mat_row_last     (s_img.row_last     ),
                .s_mat_col_first    (s_img.col_first    ),
                .s_mat_col_last     (s_img.col_last     ),
                .s_mat_de           (s_img.de           ),
                .s_mat_user         (s_img.user         ),
                .s_mat_valid        (s_img.valid        ),
                
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

endmodule


`default_nettype wire


// end of file
