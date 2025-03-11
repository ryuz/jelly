// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_mat_buf_mem
        #(
            parameter   int     N            = 2                                ,
            parameter   int     C            = 0                                ,
            parameter   int     BUF_SIZE     = 640 * 480                        ,
            parameter   bit     SDP          = BUF_SIZE > 64                    ,
            parameter           RAM_TYPE     = SDP ? "block" : "distributed"    ,
            parameter   bit     DOUT_REG     = SDP                              
        )
        (
            jelly3_mat_if.s     s_mat,
            jelly3_mat_if.m     m_mat
        );

    localparam  int     TAPS        = s_mat.TAPS                ;
    localparam  int     CH_BITS     = s_mat.CH_BITS             ;
    localparam  int     CH_DEPTH    = s_mat.CH_DEPTH            ;
    localparam  int     DE_BITS     = s_mat.DE_BITS             ;
    localparam  int     USER_BITS   = s_mat.USER_BITS           ;
    localparam  int     ROWS_BITS   = s_mat.ROWS_BITS           ;
    localparam  int     COLS_BITS   = s_mat.COLS_BITS           ;
    localparam  type    ch_t        = logic [CH_BITS-1:0]       ;
    localparam  type    data_t      = ch_t  [CH_DEPTH-1:0]      ;
    localparam  type    de_t        = logic [DE_BITS-1:0]       ;
    localparam  type    user_t      = logic [USER_BITS-1:0]     ;
    localparam  type    rows_t      = logic [ROWS_BITS-1:0]     ;
    localparam  type    cols_t      = logic [COLS_BITS-1:0]     ;

    localparam  int     M_CH_BITS   = m_mat.CH_BITS             ;
    localparam  int     M_CH_DEPTH  = m_mat.CH_DEPTH            ;
    localparam  int     M_DE_BITS   = m_mat.DE_BITS             ;
    localparam  int     M_USER_BITS = m_mat.USER_BITS           ;
    localparam  int     M_ROWS_BITS = m_mat.ROWS_BITS           ;
    localparam  int     M_COLS_BITS = m_mat.COLS_BITS           ;
    localparam  type    m_ch_t      = logic [M_CH_BITS-1:0]     ;
    localparam  type    m_data_t    = m_ch_t[M_CH_DEPTH-1:0]    ;
    localparam  type    m_de_t      = logic [M_DE_BITS-1:0]     ;
    localparam  type    m_user_t    = logic [M_USER_BITS-1:0]   ;
    localparam  type    m_rows_t    = logic [M_ROWS_BITS-1:0]   ;
    localparam  type    m_cols_t    = logic [M_COLS_BITS-1:0]   ;


    typedef struct packed {
        rows_t  rows        ;
        cols_t  cols        ;
        de_t    de          ;
        logic   row_first   ;
        logic   row_last    ;
        logic   col_first   ;
        logic   col_last    ;
    } hist_user_t;

    typedef struct packed {
        user_t              user        ;
        data_t  [TAPS-1:0]  data        ;
    } hist_data_t;

    logic                   hist_s_first ;
    hist_user_t             hist_s_user  ;
    hist_data_t             hist_s_data  ;
    logic                   hist_s_valid ;

    logic                   hist_m_first ;
    hist_user_t             hist_m_user  ;
    hist_data_t [N-1:0]     hist_m_data  ;
    logic       [N-1:0]     hist_m_valid ;

    jelly3_histry_buffer_mem
            #(
                .N              (N                  ),
                .user_t         (hist_user_t        ),
                .data_t         (hist_data_t        ),
                .BUF_SIZE       (BUF_SIZE           ),
                .SDP            (SDP                ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (DOUT_REG           )
            )
        u_histry_buffer_mem
            (
                .reset          (s_mat.reset        ),
                .clk            (s_mat.clk          ),
                .cke            (s_mat.cke          ),

                .s_first        (hist_s_first       ),
                .s_user         (hist_s_user        ),
                .s_flag         ('x                 ),
                .s_data         (hist_s_data        ),
                .s_valid        (hist_s_valid       ),

                .m_first        (hist_m_first       ),
                .m_user         (hist_m_user        ),
                .m_flag         (                   ),
                .m_data         (hist_m_data        ),
                .m_valid        (hist_m_valid       )
            );

    assign hist_s_first          = s_mat.row_first && s_mat.col_first;
    assign hist_s_user.rows      = s_mat.rows       ;
    assign hist_s_user.cols      = s_mat.cols       ;
    assign hist_s_user.de        = s_mat.de         ;
    assign hist_s_user.col_first = s_mat.col_first  ;
    assign hist_s_user.col_last  = s_mat.col_last   ;
    assign hist_s_user.row_first = s_mat.row_first  ;
    assign hist_s_user.row_last  = s_mat.row_last   ;
    assign hist_s_data.user      = s_mat.user       ;
    assign hist_s_data.data      = s_mat.data       ;
    assign hist_s_valid          = s_mat.valid      ;

    user_t  [N-1:0]             m_user  ;
    data_t  [N-1:0][TAPS-1:0]   m_data  ;
    for ( genvar i = 0; i < N; i++ ) begin
        assign m_user[i] = hist_m_data[i].user;
        assign m_data[i] = hist_m_data[i].data;
    end

    assign m_mat.rows      = hist_m_user.rows           ;
    assign m_mat.cols      = hist_m_user.cols           ;
    assign m_mat.row_first = hist_m_user.row_first      ;
    assign m_mat.row_last  = hist_m_user.row_last       ;
    assign m_mat.col_first = hist_m_user.col_first      ;
    assign m_mat.col_last  = hist_m_user.col_last       ;
    assign m_mat.de        = m_de_t'(hist_m_user.de)    ;
    assign m_mat.data      = m_data_t'(m_data)          ;
    assign m_mat.user      = m_user_t'(m_user)          ;
    assign m_mat.valid     = hist_m_valid[C]            ;
    
endmodule

`default_nettype wire

// end of file
