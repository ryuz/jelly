// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_selector_core
        #(
            parameter   int     NUM             = 2                         ,
            parameter   int     SEL_BITS        = $clog2(NUM)               ,
            parameter   type    sel_t           = logic [SEL_BITS-1:0]      
        )
        (
            input   var sel_t   sel             ,
            
            jelly3_mat_if.s     s_img   [NUM]   ,
            jelly3_mat_if.m     m_img           
        );
    
    // DIP-SW の接続なども考慮
    (* ASYNC_REG="true" *)  sel_t   ff0_sel, ff1_sel;
    always_ff @(posedge m_img.clk) begin
        ff0_sel <= sel;
        ff1_sel <= ff0_sel;
    end
    
    logic   busy;
    sel_t   next_sel;
    sel_t   current_sel;
    assign next_sel = ff1_sel;


    localparam  int     TAPS      = m_img.TAPS     ;
    localparam  int     DE_BITS   = m_img.DE_BITS  ;
    localparam  int     CH_DEPTH  = m_img.CH_DEPTH ;
    localparam  int     CH_BITS   = m_img.CH_BITS  ;
    localparam  int     ROWS_BITS = m_img.ROWS_BITS;
    localparam  int     COLS_BITS = m_img.COLS_BITS;
    localparam  int     DATA_BITS = m_img.DATA_BITS;
    localparam  int     USER_BITS = m_img.USER_BITS;

    localparam  type    ch_t      = logic [CH_BITS-1:0]     ;
    localparam  type    data_t    = ch_t  [CH_DEPTH-1:0]    ;
    localparam  type    de_t      = logic [DE_BITS-1:0]     ;
    localparam  type    user_t    = logic [USER_BITS-1:0]   ;
    localparam  type    rows_t    = logic [ROWS_BITS-1:0]   ;
    localparam  type    cols_t    = logic [COLS_BITS-1:0]   ;

    rows_t              s_img_rows        [0:NUM-1]   ;
    cols_t              s_img_cols        [0:NUM-1]   ;
    logic               s_img_row_first   [0:NUM-1]   ;
    logic               s_img_row_last    [0:NUM-1]   ;
    logic               s_img_col_first   [0:NUM-1]   ;
    logic               s_img_col_last    [0:NUM-1]   ;
    de_t                s_img_de          [0:NUM-1]   ;
    data_t  [TAPS-1:0]  s_img_data        [0:NUM-1]   ;
    user_t              s_img_user        [0:NUM-1]   ;
    logic               s_img_valid       [0:NUM-1]   ;

    rows_t              img_next_rows           ;
    cols_t              img_next_cols           ;
    logic               img_next_row_first      ;
    logic               img_next_row_last       ;
    logic               img_next_col_first      ;
    logic               img_next_col_last       ;
    de_t                img_next_de             ;
    data_t  [TAPS-1:0]  img_next_data           ;
    user_t              img_next_user           ;
    logic               img_next_valid          ;

    rows_t              img_current_rows        ;
    cols_t              img_current_cols        ;
    logic               img_current_row_first   ;
    logic               img_current_row_last    ;
    logic               img_current_col_first   ;
    logic               img_current_col_last    ;
    de_t                img_current_de          ;
    data_t  [TAPS-1:0]  img_current_data        ;
    user_t              img_current_user        ;
    logic               img_current_valid       ;

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign s_img_rows       [i] = s_img[i].rows       ;
        assign s_img_cols       [i] = s_img[i].cols       ;
        assign s_img_row_first  [i] = s_img[i].row_first  ;
        assign s_img_row_last   [i] = s_img[i].row_last   ;
        assign s_img_col_first  [i] = s_img[i].col_first  ;
        assign s_img_col_last   [i] = s_img[i].col_last   ;
        assign s_img_de         [i] = s_img[i].de         ;
        assign s_img_data       [i] = s_img[i].data       ;
        assign s_img_user       [i] = s_img[i].user       ;
        assign s_img_valid      [i] = s_img[i].valid      ;
    end

    assign img_next_rows            = s_img_rows      [next_sel]    ;
    assign img_next_cols            = s_img_cols      [next_sel]    ;
    assign img_next_row_first       = s_img_row_first [next_sel]    ;
    assign img_next_row_last        = s_img_row_last  [next_sel]    ;
    assign img_next_col_first       = s_img_col_first [next_sel]    ;
    assign img_next_col_last        = s_img_col_last  [next_sel]    ;
    assign img_next_de              = s_img_de        [next_sel]    ;
    assign img_next_data            = s_img_data      [next_sel]    ;
    assign img_next_user            = s_img_user      [next_sel]    ;
    assign img_next_valid           = s_img_valid     [next_sel]    ;

    assign img_current_rows         = s_img_rows      [current_sel] ;
    assign img_current_cols         = s_img_cols      [current_sel] ;
    assign img_current_row_first    = s_img_row_first [current_sel] ;
    assign img_current_row_last     = s_img_row_last  [current_sel] ;
    assign img_current_col_first    = s_img_col_first [current_sel] ;
    assign img_current_col_last     = s_img_col_last  [current_sel] ;
    assign img_current_de           = s_img_de        [current_sel] ;
    assign img_current_data         = s_img_data      [current_sel] ;
    assign img_current_user         = s_img_user      [current_sel] ;
    assign img_current_valid        = s_img_valid     [current_sel] ;

    logic   next_frame_start    ;
    logic   current_frame_end   ;
    assign  next_frame_start    =   (img_next_valid & img_next_row_first & img_next_col_first);
    assign  current_frame_end   =   (m_img.valid & m_img.row_last  & m_img.col_last);

    always_ff @(posedge m_img.clk) begin
        if ( m_img.reset ) begin
            busy            <= 1'b0     ;
            current_sel     <= ff1_sel  ;
            m_img.rows      <= '0       ;
            m_img.cols      <= '0       ;
            m_img.row_first <= 1'b0     ;
            m_img.row_last  <= 1'b0     ;
            m_img.col_first <= 1'b0     ;
            m_img.col_last  <= 1'b0     ;
            m_img.de        <= 1'b0     ;
            m_img.user      <= 'x       ;
            m_img.data      <= 'x       ;
            m_img.valid     <= 1'b0     ;
        end
        else if ( m_img.cke ) begin
            if ( !busy || current_frame_end ) begin
                busy            <= next_frame_start     ;
                current_sel     <= next_sel             ;

                m_img.rows      <= img_next_rows        ;
                m_img.cols      <= img_next_cols        ;
                m_img.row_first <= img_next_row_first   ;
                m_img.row_last  <= img_next_row_last    ;
                m_img.col_first <= img_next_col_first   ;
                m_img.col_last  <= img_next_col_last    ;
                m_img.de        <= img_next_de          ;
                m_img.data      <= img_next_data        ;
                m_img.user      <= img_next_user        ;
                m_img.valid     <= img_next_valid       ;
            end
            else begin
                m_img.rows      <= img_current_rows     ;
                m_img.cols      <= img_current_cols     ;
                m_img.row_first <= img_current_row_first;
                m_img.row_last  <= img_current_row_last ;
                m_img.col_first <= img_current_col_first;
                m_img.col_last  <= img_current_col_last ;
                m_img.de        <= img_current_de       ;
                m_img.data      <= img_current_data     ;
                m_img.user      <= img_current_user     ;
                m_img.valid     <= img_current_valid    ;
            end
        end
    end
    
endmodule


`default_nettype wire


// end of file
