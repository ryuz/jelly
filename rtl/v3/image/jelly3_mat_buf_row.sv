// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (A) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


//   フレーム期間中のデータ入力の無い期間は cke を落とすことを
// 前提としてデータ稠密で、メモリを READ_FIRST モードで最適化
//   フレーム末尾で吐き出しのためにブランクデータを入れる際は
// line_first と line_last は正しく制御が必要

module jelly3_mat_buf_row
        #(
            parameter   int     TAPS         = 1                        ,
            parameter   int     ROWS_BITS    = 16                           ,
            parameter   type    rows_t       = logic [ROWS_BITS-1:0]        ,
            parameter   int     COLS_BITS    = 16                           ,
            parameter   type    cols_t       = logic [COLS_BITS-1:0]        ,
            parameter   int     DE_BITS      = TAPS                         ,
            parameter   type    de_t         = logic [DE_BITS-1:0]          ,
            parameter   int     USER_BITS    = 1                            ,
            parameter   type    user_t       = logic [USER_BITS-1:0]        ,
            parameter   int     DATA_BITS    = 3*8                          ,
            parameter   type    data_t       = logic [DATA_BITS-1:0]        ,
            parameter   int     ROWS         = 3                            ,
            parameter   int     ANCHOR       = (ROWS-1) / 2                 ,
            parameter   int     MAX_COLS     = 1024                         ,
            parameter           BORDER_MODE  = "REPLICATE"                  ,   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   data_t  BORDER_VALUE = '0                           ,   // BORDER_MODE == "CONSTANT"
            parameter   bit     SDP          = MAX_COLS > 64                ,
            parameter           RAM_TYPE     = SDP ? "block" : "distributed",
            parameter   bit     DOUT_REG     = SDP                          ,
            parameter   bit     BYPASS_SIZE  = 1'b1                         ,
            parameter   bit     ENDIAN       = 0                            // 0: little, 1:big
        )
        (
            input   var logic                           reset               ,
            input   var logic                           clk                 ,
            input   var logic                           cke                 ,
            input   var rows_t                          s_mat_rows          ,
            input   var cols_t                          s_mat_cols          ,
            input   var logic                           s_mat_row_first     ,
            input   var logic                           s_mat_row_last      ,
            input   var logic                           s_mat_col_first     ,
            input   var logic                           s_mat_col_last      ,
            input   var de_t                            s_mat_de            ,
            input   var user_t                          s_mat_user          ,
            input   var data_t  [TAPS-1:0]              s_mat_data          ,
            input   var logic                           s_mat_valid         ,
            
            output  var rows_t                          m_mat_rows          ,
            output  var cols_t                          m_mat_cols          ,
            output  var logic                           m_mat_row_first     ,
            output  var logic                           m_mat_row_last      ,
            output  var logic                           m_mat_col_first     ,
            output  var logic                           m_mat_col_last      ,
            output  var de_t                            m_mat_de            ,
            output  var user_t                          m_mat_user          ,
            output  var data_t  [TAPS-1:0][ROWS-1:0]    m_mat_data          ,
            output  var logic                           m_mat_valid         
        );
    
    localparam  int     A             = ENDIAN ? ANCHOR : ROWS-1 - ANCHOR   ;
    localparam  int     MEM_ADDR_BITS = $clog2(MAX_COLS)                    ;
    localparam  int     MEM_DATA_BITS = $bits(user_t) + $bits(data_t) * TAPS;
    localparam  int     MEMS          = ROWS - 1                            ;
    localparam  int     LINE_SEL_BITS = $clog2(MEMS)                        ;
    localparam  int     POS_BITS      = $clog2(MEMS+1)                      ;

    localparam  type    mem_we_t      = logic [MEMS-1:0]                    ;
    localparam  type    mem_addr_t    = logic [MEM_ADDR_BITS-1:0]           ;
    localparam  type    mem_data_t    = logic [MEM_DATA_BITS-1:0]           ;
    localparam  type    line_sel_t    = logic [LINE_SEL_BITS-1:0]           ;
    localparam  type    pos_t         = logic [POS_BITS-1:0]                ;
    
    if ( ROWS > 1 ) begin : blk_buffer

        typedef struct packed {
            rows_t  rows    ;
            cols_t  cols    ;
            logic   first   ;
            logic   last    ;
            de_t    de      ;
        } row_t;

        typedef struct packed {
            logic   first   ;
            logic   last    ;
            user_t  user    ;
        } col_t;

        row_t       s_row;
        col_t       s_col;
        assign s_row.rows  = s_mat_rows         ;
        assign s_row.cols  = s_mat_cols         ;
        assign s_row.first = s_mat_row_first    ;
        assign s_row.last  = s_mat_row_last     ;
        assign s_col.first = s_mat_col_first    ;
        assign s_col.last  = s_mat_col_last     ;
        assign s_row.de    = s_mat_de           ;
        assign s_col.user  = s_mat_user         ;

        row_t   [ROWS-1:0]              buf_row         ;
        col_t                           buf_col         ;
        data_t  [ROWS-1:0][TAPS-1:0]    buf_data        ;
        logic   [ROWS-1:0]              buf_valid       ;
        jelly3_histry_buffer_mem
                #(
                    .N          (ROWS                   ),
                    .USER_BITS  ($bits(col_t)           ),
                    .FLAG_BITS  ($bits(row_t)           ),
                    .DATA_BITS  (TAPS * $bits(data_t)   ),
                    .BUF_SIZE   (MAX_COLS               ),
                    .SDP        (SDP                    ),
                    .RAM_TYPE   (RAM_TYPE               ),
                    .DOUT_REG   (DOUT_REG               )
                )
            u_histry_buffer_mem
                (
                    .reset   ,
                    .clk     ,
                    .cke     ,

                    .s_first    (s_mat_col_first),
                    .s_user     (s_col          ),
                    .s_flag     (s_row          ),
                    .s_data     (s_mat_data     ),
                    .s_valid    (s_mat_valid    ),
                    
                    .m_first    (               ),
                    .m_user     (buf_col        ),
                    .m_flag     (buf_row        ),
                    .m_data     (buf_data       ),
                    .m_valid    (buf_valid      )
                );

        localparam int   INDEX_BITS = $clog2(ROWS);
        localparam type  index_t    = logic [INDEX_BITS-1:0];

        index_t [ROWS-1:0]              st0_index       ;
        row_t   [ROWS-1:0]              st0_row         ;
        col_t                           st0_col         ;
        data_t  [ROWS-1:0][TAPS-1:0]    st0_data        ;
        logic                           st0_valid       ;

        index_t [ROWS-1:0]              st1_index       ;
        row_t   [ROWS-1:0]              st1_row         ;
        col_t                           st1_col         ;
        data_t  [ROWS-1:0][TAPS-1:0]    st1_data        ;
        logic                           st1_valid       ;

        always_ff @(posedge clk) begin
            if ( cke ) begin
                // stage 0
                for ( int i = 0; i < ROWS; i++ ) begin
                    st0_index[i] <= index_t'(i);
                end
                st0_row   <= buf_row    ;
                st0_col   <= buf_col    ;
                st0_data  <= buf_data   ;

                begin
                    automatic logic first_detect = 1'b0;
                    automatic int   first_idx = 0;
                    for ( int idx = ANCHOR; idx >= 0; idx-- ) begin
                        if ( buf_row[idx].first ) begin
                            first_detect = 1'b1;
                            first_idx    = idx;
                        end
                        else if ( first_detect ) begin
                            if ( string'(BORDER_MODE) == "REPLICATE" ) begin
                                st0_index[idx] <= index_t'(first_idx);
                            end
                            else if ( string'(BORDER_MODE) == "REFLECT" ) begin
                                st0_index[idx] <= index_t'(first_idx + (first_idx - idx) - 1);
                            end
                            else if ( string'(BORDER_MODE) == "REFLECT_101" ) begin
                                st0_index[idx] <= index_t'(first_idx + (first_idx - idx));
                            end
                            else if ( string'(BORDER_MODE) == "CONSTANT" ) begin
                                st0_data[idx] <= {TAPS{BORDER_VALUE}};
                            end
                            else begin
                                st0_data[idx] <= 'x;
                            end
                        end
                    end
                end
                
                begin
                    automatic logic last_detect = 1'b0;
                    automatic int   last_idx = 0;
                    for ( int idx = ANCHOR; idx < ROWS; idx++ ) begin
                        if ( buf_row[idx].last ) begin
                            last_detect = 1'b1;
                            last_idx    = idx;
                        end
                        else if ( last_detect ) begin
                            if ( string'(BORDER_MODE) == "REPLICATE" ) begin
                                st0_index[idx] <= index_t'(last_idx);
                            end
                            else if ( string'(BORDER_MODE) == "REFLECT" ) begin
                                st0_index[idx] <= index_t'(last_idx - (idx - last_idx) + 1);
                            end
                            else if ( string'(BORDER_MODE) == "REFLECT_101" ) begin
                                st0_index[idx] <= index_t'(last_idx - (idx - last_idx));
                            end
                            else if ( string'(BORDER_MODE) == "CONSTANT" ) begin
                                st0_data[idx] <= BORDER_VALUE;
                            end
                            else begin
                                st0_data[idx] <= 'x;
                            end
                        end
                    end
                end

                // stage 1
                st1_row   <= st0_row    ;
                st1_col   <= st0_col    ;
                for ( int i = 0; i < ROWS; i++ ) begin
                    st1_data[i] <= st0_data[st0_index[i]];
                end
            end
        end

        always_ff @(posedge clk) begin
            if ( reset ) begin
                st0_valid <= 1'b0;
                st1_valid <= 1'b0;
            end
            else if ( cke ) begin
                st0_valid <= buf_valid[ANCHOR];
                st1_valid <= st0_valid;
            end
        end

        assign m_mat_rows      = st1_row[ANCHOR].rows   ;
        assign m_mat_cols      = st1_row[ANCHOR].cols   ;
        assign m_mat_row_first = st1_row[ANCHOR].first  ;
        assign m_mat_row_last  = st1_row[ANCHOR].last   ;
        assign m_mat_col_first = st1_col.first          ;
        assign m_mat_col_last  = st1_col.last           ;
        assign m_mat_de        = st1_row[ANCHOR].de     ;
        assign m_mat_user      = st1_col.user           ;
        assign m_mat_valid     = st1_valid              ;
        for ( genvar y = 0; y < ROWS; y++ ) begin
            for ( genvar i = 0; i < TAPS; i++ ) begin
                if ( ENDIAN ) begin
                    assign m_mat_data[i][y] = st1_data[ROWS-1-y][TAPS-1-i];
                end
                else begin
                    assign m_mat_data[i][y] = st1_data[y][i];
                end
            end
        end
    end
    else begin : blk_bypass
        assign m_mat_rows      = s_mat_rows     ;
        assign m_mat_cols      = s_mat_cols     ;
        assign m_mat_row_first = s_mat_row_first;
        assign m_mat_row_last  = s_mat_row_last ;
        assign m_mat_col_first = s_mat_col_first;
        assign m_mat_col_last  = s_mat_col_last ;
        assign m_mat_de        = s_mat_de       ;
        assign m_mat_user      = s_mat_user     ;
        assign m_mat_data      = s_mat_data     ;
        assign m_mat_valid     = s_mat_valid    ;
    end
    
endmodule


`default_nettype wire


// end of file
