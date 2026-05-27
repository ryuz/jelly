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
            parameter   bit     BYPASS_SIZE = 1'b1          ,
            parameter   bit     IS_SIGNED   = 1'b0          
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
    localparam  int     TREE_UNIT = 2                       ;
    localparam  int     H_LATENCY = (M > 1) ? (($clog2(M) + $clog2(TREE_UNIT) - 1) / $clog2(TREE_UNIT)) : 1 ;
    localparam  int     V_LATENCY = (N > 1) ? (($clog2(N) + $clog2(TREE_UNIT) - 1) / $clog2(TREE_UNIT)) : 1 ;
    localparam  int     REDUCED_MAX_COLS = (MAX_COLS + M - 1) / M ;
    localparam  type    n_t       = logic [N_BITS-1:0]      ;
    localparam  type    m_t       = logic [M_BITS-1:0]      ;

    function automatic cols_t calc_pool_cols(input cols_t cols);
        int v;
        begin
            v = int'(cols);
            if ( BYPASS_SIZE && v < M ) begin
                calc_pool_cols = cols;
            end
            else begin
                calc_pool_cols = cols_t'(v / M);
            end
        end
    endfunction

    function automatic rows_t calc_pool_rows(input rows_t rows);
        int v;
        begin
            v = int'(rows);
            if ( BYPASS_SIZE && v < N ) begin
                calc_pool_rows = rows;
            end
            else begin
                calc_pool_rows = rows_t'(v / N);
            end
        end
    endfunction


    rows_t                          colbuf_rows           ;
    cols_t                          colbuf_cols           ;
    logic                           colbuf_row_first      ;
    logic                           colbuf_row_last       ;
    logic                           colbuf_col_first      ;
    logic                           colbuf_col_last       ;
    de_t                            colbuf_de             ;
    user_t                          colbuf_user           ;
    data_t  [TAPS-1:0][M-1:0]       colbuf_data           ;
    logic                           colbuf_valid          ;

    jelly3_mat_buf_col
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


    m_t                             h_m_count            ;
    logic                           h_bypass_in          ;
    m_t                             h_cur_m_count        ;
    logic                           h_select_in          ;

    rows_t          [H_LATENCY-1:0] h_rows_pipe          ;
    cols_t          [H_LATENCY-1:0] h_cols_pipe          ;
    logic           [H_LATENCY-1:0] h_row_first_pipe     ;
    logic           [H_LATENCY-1:0] h_row_last_pipe      ;
    logic           [H_LATENCY-1:0] h_col_first_pipe     ;
    logic           [H_LATENCY-1:0] h_col_last_pipe      ;
    de_t            [H_LATENCY-1:0] h_de_pipe            ;
    user_t          [H_LATENCY-1:0] h_user_pipe          ;
    logic           [H_LATENCY-1:0] h_select_pipe        ;
    logic           [H_LATENCY-1:0] h_bypass_pipe        ;

    ch_t    [TAPS-1:0][CH_DEPTH-1:0][M-1:0] h_tree_s_data;
    ch_t    [TAPS-1:0][CH_DEPTH-1:0] h_tree_data         ;
    logic   [TAPS-1:0][CH_DEPTH-1:0] h_tree_valid_i      ;
    logic                            h_tree_valid        ;

    assign h_bypass_in   = BYPASS_SIZE && (int'(colbuf_cols) < M);
    assign h_cur_m_count = colbuf_col_first ? '0 : h_m_count;
    assign h_select_in   = colbuf_valid && (|colbuf_de) && (h_bypass_in || (h_cur_m_count == m_t'(MC)));

    for ( genvar tap = 0; tap < TAPS; tap++ ) begin : h_tap_loop
        for ( genvar ch = 0; ch < CH_DEPTH; ch++ ) begin : h_ch_loop
            for ( genvar x = 0; x < M; x++ ) begin : h_x_loop
                assign h_tree_s_data[tap][ch][x] = colbuf_data[tap][x][ch];
            end
            jelly3_max_tree
                    #(
                        .N          (M                  ),
                        .UNIT       (TREE_UNIT          ),
                        .USER_BITS  (1                  ),
                        .DATA_BITS  (CH_BITS            ),
                        .data_t     (ch_t               ),
                        .IS_SIGNED  (IS_SIGNED          ),
                        .LATENCY    (H_LATENCY          )
                    )
                u_max_tree
                    (
                        .reset      (s_img.reset        ),
                        .clk        (s_img.clk          ),
                        .cke        (s_img.cke          ),
                        .s_en       ('1                 ),
                        .s_data     (h_tree_s_data[tap][ch]),
                        .s_user     (1'b0               ),
                        .s_valid    (colbuf_valid       ),
                        .m_data     (h_tree_data[tap][ch]),
                        .m_user     (                   ),
                        .m_valid    (h_tree_valid_i[tap][ch])
                    );
        end
    end
    assign h_tree_valid = h_tree_valid_i[0][0];

    cols_t                          h_col_index          ;
    rows_t                          h_rows_stream        ;
    cols_t                          h_cols_stream        ;
    logic                           h_row_first_stream   ;
    logic                           h_row_last_stream    ;
    logic                           h_col_first_stream   ;
    logic                           h_col_last_stream    ;
    de_t                            h_de_stream          ;
    user_t                          h_user_stream        ;
    data_t  [TAPS-1:0]              h_data_stream        ;
    logic                           h_valid_stream       ;

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
                if ( h_bypass_in || (h_cur_m_count == m_t'(M - 1)) ) begin
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
                h_col_index <= h_col_index + cols_t'(1);
            end
        end
    end

    always_comb begin
        h_rows_stream      = h_rows_pipe[H_LATENCY-1];
        h_cols_stream      = h_bypass_pipe[H_LATENCY-1] ? h_cols_pipe[H_LATENCY-1] : calc_pool_cols(h_cols_pipe[H_LATENCY-1]);
        h_row_first_stream = h_row_first_pipe[H_LATENCY-1];
        h_row_last_stream  = h_row_last_pipe[H_LATENCY-1];
        h_col_first_stream = h_select_pipe[H_LATENCY-1] && (h_col_index == '0);
        h_col_last_stream  = h_select_pipe[H_LATENCY-1] && (h_col_index == h_cols_stream - cols_t'(1));
        h_de_stream        = h_select_pipe[H_LATENCY-1] ? h_de_pipe[H_LATENCY-1] : '0;
        h_user_stream      = h_user_pipe[H_LATENCY-1];
        h_valid_stream     = h_tree_valid && h_select_pipe[H_LATENCY-1];
        for ( int tap = 0; tap < TAPS; tap++ ) begin
            for ( int ch = 0; ch < CH_DEPTH; ch++ ) begin
                h_data_stream[tap][ch] = h_bypass_pipe[H_LATENCY-1] ? colbuf_data[tap][MC][ch] : h_tree_data[tap][ch];
            end
        end
    end


    rows_t                          rowbuf_rows          ;
    cols_t                          rowbuf_cols          ;
    logic                           rowbuf_row_first     ;
    logic                           rowbuf_row_last      ;
    logic                           rowbuf_col_first     ;
    logic                           rowbuf_col_last      ;
    de_t                            rowbuf_de            ;
    user_t                          rowbuf_user          ;
    data_t  [TAPS-1:0][N-1:0]       rowbuf_data          ;
    logic                           rowbuf_valid         ;

    jelly3_mat_buf_row
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


    n_t                             v_n_count            ;
    logic                           v_row_select         ;
    logic                           v_frame_active       ;
    logic                           v_bypass_in          ;
    n_t                             v_cur_n_count        ;
    logic                           v_row_select_in      ;
    logic                           v_select_in          ;

    rows_t          [V_LATENCY-1:0] v_rows_pipe          ;
    cols_t          [V_LATENCY-1:0] v_cols_pipe          ;
    logic           [V_LATENCY-1:0] v_row_first_pipe     ;
    logic           [V_LATENCY-1:0] v_row_last_pipe      ;
    logic           [V_LATENCY-1:0] v_col_first_pipe     ;
    logic           [V_LATENCY-1:0] v_col_last_pipe      ;
    de_t            [V_LATENCY-1:0] v_de_pipe            ;
    user_t          [V_LATENCY-1:0] v_user_pipe          ;
    logic           [V_LATENCY-1:0] v_select_pipe        ;
    logic           [V_LATENCY-1:0] v_bypass_pipe        ;

    ch_t    [TAPS-1:0][CH_DEPTH-1:0][N-1:0] v_tree_s_data;
    ch_t    [TAPS-1:0][CH_DEPTH-1:0] v_tree_data         ;
    logic   [TAPS-1:0][CH_DEPTH-1:0] v_tree_valid_i      ;
    logic                            v_tree_valid        ;

    assign v_bypass_in   = BYPASS_SIZE && (int'(rowbuf_rows) < N);
    assign v_cur_n_count = rowbuf_row_first && rowbuf_col_first ? '0 : v_n_count;
    assign v_row_select_in = rowbuf_col_first ? (v_bypass_in || (v_cur_n_count == n_t'(NC))) : v_row_select;
    assign v_select_in   = rowbuf_valid && (|rowbuf_de) && v_row_select_in;

    for ( genvar tap = 0; tap < TAPS; tap++ ) begin : v_tap_loop
        for ( genvar ch = 0; ch < CH_DEPTH; ch++ ) begin : v_ch_loop
            for ( genvar y = 0; y < N; y++ ) begin : v_y_loop
                assign v_tree_s_data[tap][ch][y] = rowbuf_data[tap][y][ch];
            end
            jelly3_max_tree
                    #(
                        .N          (N                  ),
                        .UNIT       (TREE_UNIT          ),
                        .USER_BITS  (1                  ),
                        .DATA_BITS  (CH_BITS            ),
                        .data_t     (ch_t               ),
                        .IS_SIGNED  (IS_SIGNED          ),
                        .LATENCY    (V_LATENCY          )
                    )
                u_max_tree
                    (
                        .reset      (s_img.reset        ),
                        .clk        (s_img.clk          ),
                        .cke        (s_img.cke          ),
                        .s_en       ('1                 ),
                        .s_data     (v_tree_s_data[tap][ch]),
                        .s_user     (1'b0               ),
                        .s_valid    (rowbuf_valid       ),
                        .m_data     (v_tree_data[tap][ch]),
                        .m_user     (                   ),
                        .m_valid    (v_tree_valid_i[tap][ch])
                    );
        end
    end
    assign v_tree_valid = v_tree_valid_i[0][0];

    rows_t                          v_row_index          ;
    rows_t                          v_row_index_cur      ;
    rows_t                          v_row_index_now      ;
    logic                           v_row_start          ;
    rows_t                          v_rows_stream        ;
    cols_t                          v_cols_stream        ;
    logic                           v_row_first_stream   ;
    logic                           v_row_last_stream    ;
    logic                           v_col_first_stream   ;
    logic                           v_col_last_stream    ;
    de_t                            v_de_stream          ;
    user_t                          v_user_stream        ;
    data_t  [TAPS-1:0]              v_data_stream        ;
    logic                           v_valid_stream       ;

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
            v_row_index      <= '0;
        end
        else if ( s_img.cke ) begin
            if ( rowbuf_valid && rowbuf_col_first && |rowbuf_de ) begin
                if ( v_bypass_in || (v_cur_n_count == n_t'(N - 1)) ) begin
                    v_n_count <= '0;
                end
                else begin
                    v_n_count <= v_cur_n_count + 1'b1;
                end
                v_row_select <= v_bypass_in || (v_cur_n_count == n_t'(NC));
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
                    v_row_index     <= rows_t'(1);
                end
                else begin
                    v_row_index_cur <= v_row_index;
                    v_row_index     <= v_row_index + rows_t'(1);
                end
            end

            if ( v_valid_stream && v_row_last_stream && v_col_last_stream ) begin
                v_frame_active <= 1'b0;
                v_row_index    <= '0;
            end

            m_img.rows      <= v_rows_stream      ;
            m_img.cols      <= v_cols_stream      ;
            m_img.row_first <= v_row_first_stream ;
            m_img.row_last  <= v_row_last_stream  ;
            m_img.col_first <= v_col_first_stream ;
            m_img.col_last  <= v_col_last_stream  ;
            m_img.de        <= v_de_stream        ;
            m_img.user      <= v_user_stream      ;
            m_img.data      <= v_data_stream      ;
            m_img.valid     <= v_valid_stream     ;
        end
    end

    always_comb begin
        v_row_start       = v_tree_valid && v_select_pipe[V_LATENCY-1] && v_col_first_pipe[V_LATENCY-1];
        v_row_index_now   = v_row_start ? (v_frame_active ? v_row_index : rows_t'('0)) : v_row_index_cur;
        v_rows_stream      = v_bypass_pipe[V_LATENCY-1] ? v_rows_pipe[V_LATENCY-1] : calc_pool_rows(v_rows_pipe[V_LATENCY-1]);
        v_cols_stream      = v_cols_pipe[V_LATENCY-1];
        v_row_first_stream = v_select_pipe[V_LATENCY-1] && (v_row_index_now == '0);
        v_row_last_stream  = v_select_pipe[V_LATENCY-1] && (v_row_index_now == v_rows_stream - rows_t'(1));
        v_col_first_stream = v_col_first_pipe[V_LATENCY-1];
        v_col_last_stream  = v_col_last_pipe[V_LATENCY-1];
        v_de_stream        = v_select_pipe[V_LATENCY-1] ? v_de_pipe[V_LATENCY-1] : '0;
        v_user_stream      = v_user_pipe[V_LATENCY-1];
        v_valid_stream     = v_tree_valid && (v_bypass_pipe[V_LATENCY-1] || v_select_pipe[V_LATENCY-1]);
        for ( int tap = 0; tap < TAPS; tap++ ) begin
            for ( int ch = 0; ch < CH_DEPTH; ch++ ) begin
                v_data_stream[tap][ch] = v_bypass_pipe[V_LATENCY-1] ? rowbuf_data[tap][NC][ch] : v_tree_data[tap][ch];
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
