// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_ave_pooling
        #(
            parameter   int         N               = 2                         ,
            parameter   int         M               = 2                         ,
            parameter   int         NC              = N - 1                     ,
            parameter   int         MC              = M - 1                     ,
            parameter   int         SN              = N                         ,
            parameter   int         SM              = M                         ,
            parameter   int         MAX_COLS        = 4096                      ,
            parameter               RAM_TYPE        = "block"                   ,
            parameter   bit         BYPASS_SIZE     = 1'b1                      ,
            parameter   bit         S_SIGNED        = 1'b0                      ,
            parameter   bit         M_SIGNED        = 1'b0                      ,
            parameter   int         SCALE_MUL_BITS  = 16                        ,
            parameter   type        scale_mul_t     = logic [SCALE_MUL_BITS-1:0],
            parameter   scale_mul_t SCALE_MUL       = scale_mul_t'(1)           ,
            parameter   int         SCALE_SHIFT     = 0                         ,
            parameter   bit         ROUNDING        = 1'b0                      
        )
        (
            jelly3_mat_if.s                 s_img   ,
            jelly3_mat_if.m                 m_img   
        );

    localparam  int     S_TAPS      = s_img.TAPS      ;
    localparam  int     S_CH_BITS   = s_img.CH_BITS   ;
    localparam  int     S_CH_DEPTH  = s_img.CH_DEPTH  ;
    localparam  int     S_DE_BITS   = s_img.DE_BITS   ;
    localparam  int     S_USER_BITS = s_img.USER_BITS ;
    localparam  int     S_ROWS_BITS = s_img.ROWS_BITS ;
    localparam  int     S_COLS_BITS = s_img.COLS_BITS ;

    localparam  int     M_TAPS      = m_img.TAPS      ;
    localparam  int     M_CH_BITS   = m_img.CH_BITS   ;
    localparam  int     M_CH_DEPTH  = m_img.CH_DEPTH  ;
    localparam  int     M_DE_BITS   = m_img.DE_BITS   ;
    localparam  int     M_USER_BITS = m_img.USER_BITS ;
    localparam  int     M_ROWS_BITS = m_img.ROWS_BITS ;
    localparam  int     M_COLS_BITS = m_img.COLS_BITS ;

    localparam  type    s_ch_t      = logic [S_CH_BITS-1:0]     ;
    localparam  type    s_data_t    = s_ch_t  [S_CH_DEPTH-1:0]  ;
    localparam  type    s_de_t      = logic [S_DE_BITS-1:0]     ;
    localparam  type    s_user_t    = logic [S_USER_BITS-1:0]   ;
    localparam  type    s_rows_t    = logic [S_ROWS_BITS-1:0]   ;
    localparam  type    s_cols_t    = logic [S_COLS_BITS-1:0]   ;

    localparam  type    m_ch_t      = logic [M_CH_BITS-1:0]     ;
    localparam  type    m_data_t    = m_ch_t  [M_CH_DEPTH-1:0]  ;
    localparam  type    m_de_t      = logic [M_DE_BITS-1:0]     ;
    localparam  type    m_user_t    = logic [M_USER_BITS-1:0]   ;
    localparam  type    m_rows_t    = logic [M_ROWS_BITS-1:0]   ;
    localparam  type    m_cols_t    = logic [M_COLS_BITS-1:0]   ;

    localparam  int     N_BITS      = (N > 1) ? $clog2(N) : 1   ;
    localparam  int     M_BITS      = (M > 1) ? $clog2(M) : 1   ;
    localparam  int     SN_BITS     = (SN > 1) ? $clog2(SN) : 1  ;
    localparam  int     SM_BITS     = (SM > 1) ? $clog2(SM) : 1  ;
    localparam  int     SNC         = SN - 1                     ;
    localparam  int     SMC         = SM - 1                     ;
    localparam  int     TREE_UNIT   = 2                         ;
    localparam  int     H_LATENCY   = (M > 1) ? (($clog2(M) + $clog2(TREE_UNIT) - 1) / $clog2(TREE_UNIT)) : 1;
    localparam  int     V_LATENCY   = (N > 1) ? (($clog2(N) + $clog2(TREE_UNIT) - 1) / $clog2(TREE_UNIT)) : 1;
    localparam  int     REDUCED_MAX_COLS = (MAX_COLS + SM - 1) / SM;

    localparam  int     C_CH_BITS   = S_CH_BITS + (S_SIGNED ? 0 : 1);
    localparam  int     H_SUM_BITS  = C_CH_BITS + ((M > 1) ? $clog2(M) : 0);
    localparam  int     V_SUM_BITS  = H_SUM_BITS + ((N > 1) ? $clog2(N) : 0);
    localparam  int     SCALED_BITS = V_SUM_BITS + SCALE_MUL_BITS + 1;

    localparam  type    n_t         = logic [N_BITS-1:0]        ;
    localparam  type    m_t         = logic [M_BITS-1:0]        ;
    localparam  type    sn_t        = logic [SN_BITS-1:0]       ;
    localparam  type    sm_t        = logic [SM_BITS-1:0]       ;
    localparam  type    c_ch_t      = logic signed [C_CH_BITS-1:0]  ;
    localparam  type    h_sum_t     = logic signed [H_SUM_BITS-1:0] ;
    localparam  type    v_sum_t     = logic signed [V_SUM_BITS-1:0] ;
    localparam  type    h_data_t    = h_sum_t [S_CH_DEPTH-1:0]  ;
    localparam  type    scaled_t    = logic signed [SCALED_BITS-1:0];

    function automatic s_cols_t calc_pool_cols(input s_cols_t cols);
        int v;
        begin
            v = int'(cols);
            if ( BYPASS_SIZE && v < M ) begin
                calc_pool_cols = cols;
            end
            else begin
                calc_pool_cols = s_cols_t'(v / SM);
            end
        end
    endfunction

    function automatic s_rows_t calc_pool_rows(input s_rows_t rows);
        int v;
        begin
            v = int'(rows);
            if ( BYPASS_SIZE && v < N ) begin
                calc_pool_rows = rows;
            end
            else begin
                calc_pool_rows = s_rows_t'(v / SN);
            end
        end
    endfunction

    function automatic c_ch_t to_calc_ch(input s_ch_t value);
        begin
            to_calc_ch = S_SIGNED ? c_ch_t'($signed(value)) : c_ch_t'($unsigned(value));
        end
    endfunction

    function automatic m_ch_t scale_and_clip(input v_sum_t value);
        scaled_t mul_val;
        scaled_t adj_val;
        scaled_t shr_val;
        scaled_t min_val;
        scaled_t max_val;
        begin
            mul_val = scaled_t'(value) * scaled_t'($signed(SCALE_MUL));
            if ( ROUNDING && SCALE_SHIFT > 0 ) begin
                adj_val = mul_val + (scaled_t'(1) << (SCALE_SHIFT-1));
            end
            else begin
                adj_val = mul_val;
            end

            if ( SCALE_SHIFT >= SCALED_BITS ) begin
                shr_val = adj_val[SCALED_BITS-1] ? scaled_t'('1) : scaled_t'('0);
            end
            else begin
                shr_val = adj_val >>> SCALE_SHIFT;
            end

            if ( M_SIGNED ) begin
                min_val = scaled_t'({1'b1, {(M_CH_BITS-1){1'b0}}});
                max_val = scaled_t'({1'b0, {(M_CH_BITS-1){1'b1}}});
                if ( shr_val > max_val ) begin
                    scale_and_clip = m_ch_t'({1'b0, {(M_CH_BITS-1){1'b1}}});
                end
                else if ( shr_val < min_val ) begin
                    scale_and_clip = m_ch_t'({1'b1, {(M_CH_BITS-1){1'b0}}});
                end
                else begin
                    scale_and_clip = m_ch_t'(shr_val);
                end
            end
            else begin
                if ( shr_val < scaled_t'('0) ) begin
                    scale_and_clip = '0;
                end
                else if ( shr_val > scaled_t'(m_ch_t'('1)) ) begin
                    scale_and_clip = m_ch_t'('1);
                end
                else begin
                    scale_and_clip = m_ch_t'(shr_val);
                end
            end
        end
    endfunction


    s_rows_t                         colbuf_rows           ;
    s_cols_t                         colbuf_cols           ;
    logic                            colbuf_row_first      ;
    logic                            colbuf_row_last       ;
    logic                            colbuf_col_first      ;
    logic                            colbuf_col_last       ;
    s_de_t                           colbuf_de             ;
    s_user_t                         colbuf_user           ;
    s_data_t [S_TAPS-1:0][M-1:0]     colbuf_data           ;
    logic                            colbuf_valid          ;

    jelly3_mat_buf_col
            #(
                .TAPS               (S_TAPS             ),
                .ROWS_BITS          (S_ROWS_BITS        ),
                .rows_t             (s_rows_t           ),
                .COLS_BITS          (S_COLS_BITS        ),
                .cols_t             (s_cols_t           ),
                .DE_BITS            (S_DE_BITS          ),
                .de_t               (s_de_t             ),
                .USER_BITS          (S_USER_BITS        ),
                .user_t             (s_user_t           ),
                .DATA_BITS          (S_CH_BITS * S_CH_DEPTH),
                .data_t             (s_data_t           ),
                .COLS               (M                  ),
                .ANCHOR             (MC                 ),
                .BORDER_MODE        ("REFLECT_101"      ),
                .BORDER_VALUE       ('0                 ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
            )
        u_mat_buf_col
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

                .m_mat_rows         (colbuf_rows        ),
                .m_mat_cols         (colbuf_cols        ),
                .m_mat_row_first    (colbuf_row_first   ),
                .m_mat_row_last     (colbuf_row_last    ),
                .m_mat_col_first    (colbuf_col_first   ),
                .m_mat_col_last     (colbuf_col_last    ),
                .m_mat_de           (colbuf_de          ),
                .m_mat_user         (colbuf_user        ),
                .m_mat_data         (colbuf_data        ),
                .m_mat_valid        (colbuf_valid       )
            );


    sm_t                            h_m_count            ;
    logic                           h_bypass_in          ;
    sm_t                            h_cur_m_count        ;
    logic                           h_select_in          ;

    s_rows_t        [H_LATENCY-1:0] h_rows_pipe          ;
    s_cols_t        [H_LATENCY-1:0] h_cols_pipe          ;
    logic           [H_LATENCY-1:0] h_row_first_pipe     ;
    logic           [H_LATENCY-1:0] h_row_last_pipe      ;
    logic           [H_LATENCY-1:0] h_col_first_pipe     ;
    logic           [H_LATENCY-1:0] h_col_last_pipe      ;
    s_de_t          [H_LATENCY-1:0] h_de_pipe            ;
    s_user_t        [H_LATENCY-1:0] h_user_pipe          ;
    logic           [H_LATENCY-1:0] h_select_pipe        ;
    logic           [H_LATENCY-1:0] h_bypass_pipe        ;

    c_ch_t  [S_TAPS-1:0][S_CH_DEPTH-1:0][M-1:0] h_tree_s_data;
    h_sum_t [S_TAPS-1:0][S_CH_DEPTH-1:0]        h_tree_data  ;
    logic   [S_TAPS-1:0][S_CH_DEPTH-1:0]        h_tree_valid_i;
    logic                                        h_tree_valid ;

    assign h_bypass_in   = BYPASS_SIZE && (int'(colbuf_cols) < M);
    assign h_cur_m_count = colbuf_col_first ? '0 : h_m_count;
    assign h_select_in   = colbuf_valid && (|colbuf_de) && (h_bypass_in || (h_cur_m_count == sm_t'(SMC)));

    for ( genvar tap = 0; tap < S_TAPS; tap++ ) begin : h_tap_loop
        for ( genvar ch = 0; ch < S_CH_DEPTH; ch++ ) begin : h_ch_loop
            for ( genvar x = 0; x < M; x++ ) begin : h_x_loop
                assign h_tree_s_data[tap][ch][x] = to_calc_ch(colbuf_data[tap][x][ch]);
            end
            jelly3_sum_tree
                    #(
                        .N          (M                  ),
                        .UNIT       (TREE_UNIT          ),
                        .USER_BITS  (1                  ),
                        .S_DATA_BITS(C_CH_BITS          ),
                        .s_data_t   (c_ch_t             ),
                        .M_DATA_BITS(H_SUM_BITS         ),
                        .m_data_t   (h_sum_t            ),
                        .LATENCY    (H_LATENCY          )
                    )
                u_sum_tree
                    (
                        .reset      (s_img.reset            ),
                        .clk        (s_img.clk              ),
                        .cke        (s_img.cke              ),
                        .s_en       ('1                     ),
                        .s_data     (h_tree_s_data[tap][ch] ),
                        .s_user     (1'b0                   ),
                        .s_valid    (colbuf_valid           ),
                        .m_data     (h_tree_data[tap][ch]   ),
                        .m_user     (                       ),
                        .m_valid    (h_tree_valid_i[tap][ch])
                    );
        end
    end
    assign h_tree_valid = h_tree_valid_i[0][0];

    s_cols_t                         h_col_index          ;
    s_rows_t                         h_rows_stream        ;
    s_cols_t                         h_cols_stream        ;
    logic                            h_row_first_stream   ;
    logic                            h_row_last_stream    ;
    logic                            h_col_first_stream   ;
    logic                            h_col_last_stream    ;
    s_de_t                           h_de_stream          ;
    s_user_t                         h_user_stream        ;
    h_data_t [S_TAPS-1:0]            h_data_stream        ;
    logic                            h_valid_stream       ;

    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset || m_img.reset ) begin
            h_m_count        <= '0;
            h_rows_pipe      <= 'x;
            h_cols_pipe      <= 'x;
            h_row_first_pipe <= 'x;
            h_row_last_pipe  <= 'x;
            h_col_first_pipe <= 'x;
            h_col_last_pipe  <= 'x;
            h_de_pipe        <= 'x;
            h_user_pipe      <= 'x;
            h_select_pipe    <= '0;
            h_bypass_pipe    <= '0;
            h_col_index      <= '0;
        end
        else if ( s_img.cke ) begin
            if ( colbuf_valid && |colbuf_de ) begin
                if ( h_bypass_in || (h_cur_m_count == sm_t'(SM - 1)) ) begin
                    h_m_count <= '0;
                end
                else begin
                    h_m_count <= h_cur_m_count + 1'b1;
                end
            end

            h_rows_pipe[0]      <= colbuf_rows      ;
            h_cols_pipe[0]      <= colbuf_cols      ;
            h_row_first_pipe[0] <= colbuf_row_first ;
            h_row_last_pipe[0]  <= colbuf_row_last  ;
            h_col_first_pipe[0] <= colbuf_col_first ;
            h_col_last_pipe[0]  <= colbuf_col_last  ;
            h_de_pipe[0]        <= colbuf_de        ;
            h_user_pipe[0]      <= colbuf_user      ;
            h_select_pipe[0]    <= h_select_in      ;
            h_bypass_pipe[0]    <= h_bypass_in      ;
            for ( int i = 1; i < H_LATENCY; i++ ) begin
                h_rows_pipe[i]      <= h_rows_pipe[i-1]      ;
                h_cols_pipe[i]      <= h_cols_pipe[i-1]      ;
                h_row_first_pipe[i] <= h_row_first_pipe[i-1] ;
                h_row_last_pipe[i]  <= h_row_last_pipe[i-1]  ;
                h_col_first_pipe[i] <= h_col_first_pipe[i-1] ;
                h_col_last_pipe[i]  <= h_col_last_pipe[i-1]  ;
                h_de_pipe[i]        <= h_de_pipe[i-1]        ;
                h_user_pipe[i]      <= h_user_pipe[i-1]      ;
                h_select_pipe[i]    <= h_select_pipe[i-1]    ;
                h_bypass_pipe[i]    <= h_bypass_pipe[i-1]    ;
            end

            if ( h_tree_valid && h_col_first_pipe[H_LATENCY-1] ) begin
                h_col_index <= '0;
            end
            else if ( h_tree_valid && h_select_pipe[H_LATENCY-1] ) begin
                h_col_index <= h_col_index + s_cols_t'(1);
            end
        end
    end

    always_comb begin
        h_rows_stream      = h_rows_pipe[H_LATENCY-1];
        h_cols_stream      = h_bypass_pipe[H_LATENCY-1] ? h_cols_pipe[H_LATENCY-1] : calc_pool_cols(h_cols_pipe[H_LATENCY-1]);
        h_row_first_stream = h_row_first_pipe[H_LATENCY-1];
        h_row_last_stream  = h_row_last_pipe[H_LATENCY-1];
        h_col_first_stream = h_select_pipe[H_LATENCY-1] && (h_col_index == '0);
        h_col_last_stream  = h_select_pipe[H_LATENCY-1] && (h_col_index == h_cols_stream - s_cols_t'(1));
        h_de_stream        = h_select_pipe[H_LATENCY-1] ? h_de_pipe[H_LATENCY-1] : '0;
        h_user_stream      = h_user_pipe[H_LATENCY-1];
        h_valid_stream     = h_tree_valid && h_select_pipe[H_LATENCY-1];
        for ( int tap = 0; tap < S_TAPS; tap++ ) begin
            for ( int ch = 0; ch < S_CH_DEPTH; ch++ ) begin
                h_data_stream[tap][ch] = h_bypass_pipe[H_LATENCY-1] ? h_sum_t'(to_calc_ch(colbuf_data[tap][MC][ch])) : h_tree_data[tap][ch];
            end
        end
    end


    s_rows_t                         rowbuf_rows          ;
    s_cols_t                         rowbuf_cols          ;
    logic                            rowbuf_row_first     ;
    logic                            rowbuf_row_last      ;
    logic                            rowbuf_col_first     ;
    logic                            rowbuf_col_last      ;
    s_de_t                           rowbuf_de            ;
    s_user_t                         rowbuf_user          ;
    h_data_t [S_TAPS-1:0][N-1:0]     rowbuf_data          ;
    logic                            rowbuf_valid         ;

    jelly3_mat_buf_row
            #(
                .TAPS               (S_TAPS             ),
                .ROWS_BITS          (S_ROWS_BITS        ),
                .rows_t             (s_rows_t           ),
                .COLS_BITS          (S_COLS_BITS        ),
                .cols_t             (s_cols_t           ),
                .DE_BITS            (S_DE_BITS          ),
                .de_t               (s_de_t             ),
                .USER_BITS          (S_USER_BITS        ),
                .user_t             (s_user_t           ),
                .DATA_BITS          (H_SUM_BITS * S_CH_DEPTH),
                .data_t             (h_data_t           ),
                .ROWS               (N                  ),
                .ANCHOR             (NC                 ),
                .MAX_COLS           (REDUCED_MAX_COLS   ),
                .RAM_TYPE           (RAM_TYPE           ),
                .BORDER_MODE        ("REFLECT_101"      ),
                .BORDER_VALUE       ('0                 ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
            )
        u_mat_buf_row
            (
                .reset              (s_img.reset        ),
                .clk                (s_img.clk          ),
                .cke                (s_img.cke          ),

                .s_mat_rows         (h_rows_stream      ),
                .s_mat_cols         (h_cols_stream      ),
                .s_mat_row_first    (h_row_first_stream ),
                .s_mat_row_last     (h_row_last_stream  ),
                .s_mat_col_first    (h_col_first_stream ),
                .s_mat_col_last     (h_col_last_stream  ),
                .s_mat_de           (h_de_stream        ),
                .s_mat_user         (h_user_stream      ),
                .s_mat_data         (h_data_stream      ),
                .s_mat_valid        (h_valid_stream     ),

                .m_mat_rows         (rowbuf_rows        ),
                .m_mat_cols         (rowbuf_cols        ),
                .m_mat_row_first    (rowbuf_row_first   ),
                .m_mat_row_last     (rowbuf_row_last    ),
                .m_mat_col_first    (rowbuf_col_first   ),
                .m_mat_col_last     (rowbuf_col_last    ),
                .m_mat_de           (rowbuf_de          ),
                .m_mat_user         (rowbuf_user        ),
                .m_mat_data         (rowbuf_data        ),
                .m_mat_valid        (rowbuf_valid       )
            );


    sn_t                            v_n_count            ;
    logic                           v_row_select         ;
    logic                           v_frame_active       ;
    logic                           v_bypass_in          ;
    sn_t                            v_cur_n_count        ;
    logic                           v_row_select_in      ;
    logic                           v_select_in          ;

    s_rows_t        [V_LATENCY-1:0] v_rows_pipe          ;
    s_cols_t        [V_LATENCY-1:0] v_cols_pipe          ;
    logic           [V_LATENCY-1:0] v_row_first_pipe     ;
    logic           [V_LATENCY-1:0] v_row_last_pipe      ;
    logic           [V_LATENCY-1:0] v_col_first_pipe     ;
    logic           [V_LATENCY-1:0] v_col_last_pipe      ;
    s_de_t          [V_LATENCY-1:0] v_de_pipe            ;
    s_user_t        [V_LATENCY-1:0] v_user_pipe          ;
    logic           [V_LATENCY-1:0] v_select_pipe        ;
    logic           [V_LATENCY-1:0] v_bypass_pipe        ;

    h_sum_t [S_TAPS-1:0][S_CH_DEPTH-1:0][N-1:0] v_tree_s_data;
    v_sum_t [S_TAPS-1:0][S_CH_DEPTH-1:0]        v_tree_data  ;
    logic   [S_TAPS-1:0][S_CH_DEPTH-1:0]        v_tree_valid_i;
    logic                                        v_tree_valid ;

    assign v_bypass_in   = BYPASS_SIZE && (int'(rowbuf_rows) < N);
    assign v_cur_n_count = rowbuf_row_first && rowbuf_col_first ? '0 : v_n_count;
    assign v_row_select_in = rowbuf_col_first ? (v_bypass_in || (v_cur_n_count == sn_t'(SNC))) : v_row_select;
    assign v_select_in   = rowbuf_valid && (|rowbuf_de) && v_row_select_in;

    for ( genvar tap = 0; tap < S_TAPS; tap++ ) begin : v_tap_loop
        for ( genvar ch = 0; ch < S_CH_DEPTH; ch++ ) begin : v_ch_loop
            for ( genvar y = 0; y < N; y++ ) begin : v_y_loop
                assign v_tree_s_data[tap][ch][y] = rowbuf_data[tap][y][ch];
            end
            jelly3_sum_tree
                    #(
                        .N          (N                  ),
                        .UNIT       (TREE_UNIT          ),
                        .USER_BITS  (1                  ),
                        .S_DATA_BITS(H_SUM_BITS         ),
                        .s_data_t   (h_sum_t            ),
                        .M_DATA_BITS(V_SUM_BITS         ),
                        .m_data_t   (v_sum_t            ),
                        .LATENCY    (V_LATENCY          )
                    )
                u_sum_tree
                    (
                        .reset      (s_img.reset            ),
                        .clk        (s_img.clk              ),
                        .cke        (s_img.cke              ),
                        .s_en       ('1                     ),
                        .s_data     (v_tree_s_data[tap][ch] ),
                        .s_user     (1'b0                   ),
                        .s_valid    (rowbuf_valid           ),
                        .m_data     (v_tree_data[tap][ch]   ),
                        .m_user     (                       ),
                        .m_valid    (v_tree_valid_i[tap][ch])
                    );
        end
    end
    assign v_tree_valid = v_tree_valid_i[0][0];

    s_rows_t                         v_row_index          ;
    s_rows_t                         v_row_index_cur      ;
    s_rows_t                         v_row_index_now      ;
    logic                            v_row_start          ;
    s_rows_t                         v_rows_stream        ;
    s_cols_t                         v_cols_stream        ;
    logic                            v_row_first_stream   ;
    logic                            v_row_last_stream    ;
    logic                            v_col_first_stream   ;
    logic                            v_col_last_stream    ;
    s_de_t                           v_de_stream          ;
    s_user_t                         v_user_stream        ;
    v_sum_t [S_TAPS-1:0][S_CH_DEPTH-1:0]
                                     v_value_stream       ;
    m_data_t [S_TAPS-1:0]            v_data_stream        ;
    logic                            v_valid_stream       ;

    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset || m_img.reset ) begin
            v_n_count        <= '0;
            v_row_select     <= 1'b0;
            v_frame_active   <= 1'b0;
            v_row_index      <= '0;
            v_row_index_cur  <= '0;
            v_rows_pipe      <= 'x;
            v_cols_pipe      <= 'x;
            v_row_first_pipe <= 'x;
            v_row_last_pipe  <= 'x;
            v_col_first_pipe <= 'x;
            v_col_last_pipe  <= 'x;
            v_de_pipe        <= 'x;
            v_user_pipe      <= 'x;
            v_select_pipe    <= '0;
            v_bypass_pipe    <= '0;
        end
        else if ( s_img.cke ) begin
            if ( rowbuf_valid && rowbuf_col_first && |rowbuf_de ) begin
                if ( v_bypass_in || (v_cur_n_count == sn_t'(SN - 1)) ) begin
                    v_n_count <= '0;
                end
                else begin
                    v_n_count <= v_cur_n_count + 1'b1;
                end
                v_row_select <= v_bypass_in || (v_cur_n_count == sn_t'(SNC));
            end

            v_rows_pipe[0]      <= rowbuf_rows      ;
            v_cols_pipe[0]      <= rowbuf_cols      ;
            v_row_first_pipe[0] <= rowbuf_row_first ;
            v_row_last_pipe[0]  <= rowbuf_row_last  ;
            v_col_first_pipe[0] <= rowbuf_col_first ;
            v_col_last_pipe[0]  <= rowbuf_col_last  ;
            v_de_pipe[0]        <= rowbuf_de        ;
            v_user_pipe[0]      <= rowbuf_user      ;
            v_select_pipe[0]    <= v_select_in      ;
            v_bypass_pipe[0]    <= v_bypass_in      ;
            for ( int i = 1; i < V_LATENCY; i++ ) begin
                v_rows_pipe[i]      <= v_rows_pipe[i-1]      ;
                v_cols_pipe[i]      <= v_cols_pipe[i-1]      ;
                v_row_first_pipe[i] <= v_row_first_pipe[i-1] ;
                v_row_last_pipe[i]  <= v_row_last_pipe[i-1]  ;
                v_col_first_pipe[i] <= v_col_first_pipe[i-1] ;
                v_col_last_pipe[i]  <= v_col_last_pipe[i-1]  ;
                v_de_pipe[i]        <= v_de_pipe[i-1]        ;
                v_user_pipe[i]      <= v_user_pipe[i-1]      ;
                v_select_pipe[i]    <= v_select_pipe[i-1]    ;
                v_bypass_pipe[i]    <= v_bypass_pipe[i-1]    ;
            end

            if ( v_tree_valid && v_select_pipe[V_LATENCY-1] && v_col_first_pipe[V_LATENCY-1] ) begin
                if ( !v_frame_active ) begin
                    v_frame_active  <= 1'b1;
                    v_row_index_cur <= '0;
                    v_row_index     <= s_rows_t'(1);
                end
                else begin
                    v_row_index_cur <= v_row_index;
                    v_row_index     <= v_row_index + s_rows_t'(1);
                end
            end

            if ( v_valid_stream && v_row_last_stream && v_col_last_stream ) begin
                v_frame_active <= 1'b0;
                v_row_index    <= '0;
            end

            m_img.rows      <= m_rows_t'(v_rows_stream)      ;
            m_img.cols      <= m_cols_t'(v_cols_stream)      ;
            m_img.row_first <= v_row_first_stream            ;
            m_img.row_last  <= v_row_last_stream             ;
            m_img.col_first <= v_col_first_stream            ;
            m_img.col_last  <= v_col_last_stream             ;
            m_img.de        <= m_de_t'(v_de_stream)          ;
            m_img.user      <= m_user_t'(v_user_stream)      ;
            m_img.data      <= v_data_stream                 ;
            m_img.valid     <= v_valid_stream                ;
        end
    end

    always_comb begin
        v_row_start       = v_tree_valid && v_select_pipe[V_LATENCY-1] && v_col_first_pipe[V_LATENCY-1];
        v_row_index_now   = v_row_start ? (v_frame_active ? v_row_index : s_rows_t'('0)) : v_row_index_cur;
        v_rows_stream     = v_bypass_pipe[V_LATENCY-1] ? v_rows_pipe[V_LATENCY-1] : calc_pool_rows(v_rows_pipe[V_LATENCY-1]);
        v_cols_stream     = v_cols_pipe[V_LATENCY-1];
        v_row_first_stream = v_select_pipe[V_LATENCY-1] && (v_row_index_now == '0);
        v_row_last_stream  = v_select_pipe[V_LATENCY-1] && (v_row_index_now == v_rows_stream - s_rows_t'(1));
        v_col_first_stream = v_col_first_pipe[V_LATENCY-1];
        v_col_last_stream  = v_col_last_pipe[V_LATENCY-1];
        v_de_stream        = v_select_pipe[V_LATENCY-1] ? v_de_pipe[V_LATENCY-1] : '0;
        v_user_stream      = v_user_pipe[V_LATENCY-1];
        v_valid_stream     = v_tree_valid && (v_bypass_pipe[V_LATENCY-1] || v_select_pipe[V_LATENCY-1]);

        for ( int tap = 0; tap < S_TAPS; tap++ ) begin
            for ( int ch = 0; ch < S_CH_DEPTH; ch++ ) begin
                v_value_stream[tap][ch] = v_bypass_pipe[V_LATENCY-1] ? v_sum_t'(rowbuf_data[tap][NC][ch]) : v_tree_data[tap][ch];
                v_data_stream[tap][ch]  = scale_and_clip(v_value_stream[tap][ch]);
            end
        end
    end

    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset || m_img.reset ) begin
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
    end

    // assertion
    initial begin
        sva_taps     : assert ( m_img.TAPS     == s_img.TAPS     ) else $warning("m_img.TAPS != s_img.TAPS"        );
        sva_ch_depth : assert ( m_img.CH_DEPTH == s_img.CH_DEPTH ) else $warning("m_img.CH_DEPTH != s_img.CH_DEPTH");
    end
    always_comb begin
        sva_connect_clk : assert (m_img.clk === s_img.clk);
        sva_connect_cke : assert (m_img.cke === s_img.cke);
    end

endmodule


`default_nettype wire


// end of file
