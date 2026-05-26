// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_max_pooling
        #(
            parameter   int     N           = 2             ,
            parameter   int     M           = 2             ,
            parameter   int     NC          = N - 1         ,
            parameter   int     MC          = M - 1         ,
            parameter   int     MAX_COLS    = 4096          ,
            parameter           RAM_TYPE    = "block"       ,
            parameter   bit     BYPASS_SIZE = 1'b1          
        )
        (
            jelly3_mat_if.s                 s_img   ,
            jelly3_mat_if.m                 m_img   
        );

    localparam  int     TAPS      = s_img.TAPS      ;
    localparam  int     CH_BITS   = s_img.CH_BITS   ;
    localparam  int     CH_DEPTH  = s_img.CH_DEPTH  ;
    localparam  int     DE_BITS   = s_img.DE_BITS   ;
    localparam  int     USER_BITS = s_img.USER_BITS ;
    localparam  int     ROWS_BITS = s_img.ROWS_BITS ;
    localparam  int     COLS_BITS = s_img.COLS_BITS ;

    localparam  type    ch_t      = logic [CH_BITS-1:0]     ;
    localparam  type    data_t    = ch_t  [CH_DEPTH-1:0]    ;
    localparam  type    de_t      = logic [DE_BITS-1:0]     ;
    localparam  type    user_t    = logic [USER_BITS-1:0]   ;
    localparam  type    rows_t    = logic [ROWS_BITS-1:0]   ;
    localparam  type    cols_t    = logic [COLS_BITS-1:0]   ;
    localparam  int     N_BITS    = (N > 1) ? $clog2(N) : 1 ;
    localparam  int     M_BITS    = (M > 1) ? $clog2(M) : 1 ;
    localparam  type    n_t       = logic [N_BITS-1:0]      ;
    localparam  type    m_y       = logic [M_BITS-1:0]      ;


    rows_t                          img_blk_rows        ;
    cols_t                          img_blk_cols        ;
    logic                           img_blk_row_first   ;
    logic                           img_blk_row_last    ;
    logic                           img_blk_col_first   ;
    logic                           img_blk_col_last    ;
    de_t                            img_blk_de          ;
    user_t                          img_blk_user        ;
    data_t  [TAPS-1:0][N-1:0][M-1:0]img_blk_data        ;
    logic                           img_blk_valid       ;

    jelly3_mat_buf_blk
            #(
                .TAPS               (TAPS               ),
                .ROWS_BITS          (ROWS_BITS          ),
                .rows_t             (rows_t             ),
                .COLS_BITS          (COLS_BITS          ),
                .cols_t             (cols_t             ),
                .DE_BITS            (DE_BITS            ),
                .de_t               (de_t               ),
                .USER_BITS          (USER_BITS          ),
                .user_t             (user_t             ),
                .DATA_BITS          (CH_BITS * CH_DEPTH ),
                .data_t             (data_t             ),
                .ROWS               (N                  ),
                .COLS               (M                  ),
                .ROW_ANCHOR         (NC                 ),
                .COL_ANCHOR         (MC                 ),
                .MAX_COLS           (MAX_COLS           ),
                .RAM_TYPE           (RAM_TYPE           ),
                .BORDER_MODE        ("REFLECT_101"      ),
                .BORDER_VALUE       ('0                 ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
            )
        u_mat_buf_blk
            (
                .reset              (s_img.reset        ),
                .clk                (s_img.clk          ),
                .cke                (s_img.cke          ),

                .s_mat_rows         (s_img.rows         ),
                .s_mat_cols         (s_img.cols         ),
                .s_mat_row_first    (s_img.row_first    ),
                .s_mat_row_last     (s_img.row_last     ),
                .s_mat_col_first    (s_img.col_first    ),
                .s_mat_col_last     (s_img.col_last     ),
                .s_mat_de           (s_img.de           ),
                .s_mat_user         (s_img.user         ),
                .s_mat_data         (s_img.data         ),
                .s_mat_valid        (s_img.valid        ),

                .m_mat_rows         (img_blk_rows       ),
                .m_mat_cols         (img_blk_cols       ),
                .m_mat_row_first    (img_blk_row_first  ),
                .m_mat_row_last     (img_blk_row_last   ),
                .m_mat_col_first    (img_blk_col_first  ),
                .m_mat_col_last     (img_blk_col_last   ),
                .m_mat_de           (img_blk_de         ),
                .m_mat_user         (img_blk_user       ),
                .m_mat_data         (img_blk_data       ),
                .m_mat_valid        (img_blk_valid      )
            );


    n_t                             st0_n_count         ;
    m_y                             st0_m_count         ;
    rows_t                          st0_rows            ;
    cols_t                          st0_cols            ;
    logic                           st0_row_first       ;
    logic                           st0_row_last        ;
    logic                           st0_col_first       ;
    logic                           st0_col_last        ;
    de_t                            st0_de              ;
    user_t                          st0_user            ;
    data_t  [TAPS-1:0]              st0_data            ;
    logic                           st0_valid           ;

    rows_t                          st1_rows            ;
    cols_t                          st1_cols            ;
    logic                           st1_row_first       ;
    logic                           st1_row_last        ;
    logic                           st1_col_first       ;
    logic                           st1_col_last        ;
    de_t                            st1_de              ;
    user_t                          st1_user            ;
    data_t  [TAPS-1:0]              st1_data            ;
    logic                           st1_valid           ;

    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset || m_img.reset ) begin
            st0_n_count      <= 'x;
            st0_m_count      <= 'x;
            st0_rows         <= 'x;
            st0_cols         <= 'x;
            st0_row_first    <= 'x;
            st0_row_last     <= 'x;
            st0_col_first    <= 'x;
            st0_col_last     <= 'x;
            st0_de           <= 'x;
            st0_user         <= 'x;
            st0_data         <= 'x;
            st0_valid        <= 1'b0;

            st1_rows         <= 'x;
            st1_cols         <= 'x;
            st1_row_first    <= 'x;
            st1_row_last     <= 'x;
            st1_col_first    <= 'x;
            st1_col_last     <= 'x;
            st1_de           <= 'x;
            st1_user         <= 'x;
            st1_data         <= 'x;
            st1_valid        <= 1'b0;

            m_img.rows       <= 'x;
            m_img.cols       <= 'x;
            m_img.row_first  <= 'x;
            m_img.row_last   <= 'x;
            m_img.col_first  <= 'x;
            m_img.col_last   <= 'x;
            m_img.de         <= 'x;
            m_img.user       <= 'x;
            m_img.data       <= 'x;
            m_img.valid      <= 1'b0;
        end
        else if ( s_img.cke ) begin
            // stage 0: count block center position
            if ( img_blk_valid && img_blk_row_first ) begin
                st0_n_count <= '0;
            end
            else if ( img_blk_valid && img_blk_col_first ) begin
                st0_n_count <= st0_n_count + 1'b1;
                if ( st0_n_count == n_t'(N - 1) ) begin
                    st0_n_count <= '0;
                end
            end

            if ( img_blk_valid && img_blk_col_first ) begin
                st0_m_count <= '0;
            end
            else if ( img_blk_valid && |img_blk_de ) begin
                st0_m_count <= st0_m_count + 1'b1;
                if ( st0_m_count == m_y'(M - 1) ) begin
                    st0_m_count <= '0;
                end
            end

            st0_rows      <= img_blk_rows       ;
            st0_cols      <= img_blk_cols       ;
            st0_row_first <= img_blk_row_first  ;
            st0_row_last  <= img_blk_row_last   ;
            st0_col_first <= img_blk_col_first  ;
            st0_col_last  <= img_blk_col_last   ;
            st0_de        <= img_blk_de         ;
            st0_user      <= img_blk_user       ;
            st0_valid     <= img_blk_valid      ;

            for ( int tap = 0; tap < TAPS; tap++ ) begin
                for ( int ch = 0; ch < CH_DEPTH; ch++ ) begin
                    st0_data[tap][ch] <= '0;
                    for ( int y = 0; y < N; y++ ) begin
                        for ( int x = 0; x < M; x++ ) begin
                            st0_data[tap][ch] <= st0_data[tap][ch] | img_blk_data[tap][y][x][ch];
                        end
                    end
                end
            end

            // stage 1: gate de at selected anchor position
            st1_rows      <= st0_rows                                                    ;
            st1_cols      <= st0_cols                                                    ;
            st1_row_first <= st0_row_first                                               ;
            st1_row_last  <= st0_row_last                                                ;
            st1_col_first <= st0_col_first                                               ;
            st1_col_last  <= st0_col_last                                                ;
            st1_de        <= st0_de & de_t'({DE_BITS{st0_n_count == n_t'(NC) && st0_m_count == m_y'(MC)}});
            st1_user      <= st0_user                                                    ;
            st1_data      <= st0_data                                                    ;
            st1_valid     <= st0_valid                                                   ;

            // output register
            m_img.rows      <= st1_rows      ;
            m_img.cols      <= st1_cols      ;
            m_img.row_first <= st1_row_first ;
            m_img.row_last  <= st1_row_last  ;
            m_img.col_first <= st1_col_first ;
            m_img.col_last  <= st1_col_last  ;
            m_img.de        <= st1_de        ;
            m_img.user      <= st1_user      ;
            m_img.data      <= st1_data      ;
            m_img.valid     <= st1_valid     ;
        end
    end

    // assertion
    initial begin
        sva_ch_bits  : assert ( m_img.CH_BITS  == s_img.CH_BITS  ) else $warning("m_img.CH_BITS != s_img.CH_BITS" );
        sva_ch_depth : assert ( m_img.CH_DEPTH == s_img.CH_DEPTH ) else $warning("m_img.CH_DEPTH != s_img.CH_DEPTH");
        sva_taps     : assert ( m_img.TAPS     == s_img.TAPS     ) else $warning("m_img.TAPS != s_img.TAPS"        );
    end
    always_comb begin
        sva_connect_clk : assert (m_img.clk === s_img.clk);
        sva_connect_cke : assert (m_img.cke === s_img.cke);
    end

endmodule


`default_nettype wire


// end of file
