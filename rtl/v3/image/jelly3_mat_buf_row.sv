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
            parameter   int     ROWS_BITS    = 16                       ,
            parameter   type    rows_t       = logic [ROWS_BITS-1:0]    ,
            parameter   int     COLS_BITS    = 16                       ,
            parameter   type    cols_t       = logic [COLS_BITS-1:0]    ,
            parameter   int     DE_BITS      = TAPS                     ,
            parameter   type    de_t         = logic [DE_BITS-1:0]      ,
            parameter   int     USER_BITS    = 1                        ,
            parameter   type    user_t       = logic [USER_BITS-1:0]    ,
            parameter   int     DATA_BITS    = 3*8                      ,
            parameter   type    data_t       = logic [DATA_BITS-1:0]    ,
            parameter   int     ROWS         = 3                        ,
            parameter   int     ANCHOR       = (ROWS-1) / 2             ,
            parameter   int     MAX_COLS     = 1024                     ,
            parameter           BORDER_MODE  = "REPLICATE"              ,   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   data_t  BORDER_VALUE = '0                       ,   // BORDER_MODE == "CONSTANT"
            parameter           RAM_TYPE     = "block"                  ,
            parameter   bit     BYPASS_SIZE  = 1'b1                     ,
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
    
    generate
    if ( ROWS > 1 ) begin : blk_buffer
        // memory
        mem_we_t                            mem_we      ;
        mem_addr_t                          mem_addr    ;
        user_t                              mem_wuser   ;
        data_t   [TAPS-1:0]                 mem_wdata   ;
        logic                               mem_wfirst  ;
        logic                               mem_wlast   ;
        user_t   [MEMS-1:0]                 mem_ruser   ;
        data_t   [MEMS-1:0][TAPS-1:0]       mem_rdata   ;
        
        for ( genvar i = 0; i < MEMS; i = i+1 ) begin : mem_loop
            
            // USER_WIDTHが0の時の為にキャスト
            mem_data_t          wdata;
            mem_data_t          rdata;
            assign wdata = {mem_wuser, mem_wdata};
            assign {mem_ruser[i], mem_rdata[i]} = rdata;
            
            jelly2_ram_singleport
                    #(
                        .ADDR_WIDTH     (MEM_ADDR_BITS  ),
                        .DATA_WIDTH     (MEM_DATA_BITS  ),
                        .MEM_SIZE       (MAX_COLS       ),
                        .RAM_TYPE       (RAM_TYPE       ),
                        .DOUT_REGS      (1              ),
                        .MODE           ("READ_FIRST"   )  // <- important!
                    )
                i_ram_singleport
                    (
                        .clk            (clk            ),
                        .en             (cke            ),
                        .regcke         (cke            ),
                        .we             (mem_we[i]      ),
                        .addr           (mem_addr       ),
                        .din            (wdata          ),
                        .dout           (rdata          )
                    );
        end
        
        
        // control
        mem_we_t                            st0_we          ;
        mem_addr_t                          st0_addr        ;
        rows_t                              st0_rows        ;
        cols_t                              st0_cols        ;
        logic                               st0_row_first   ;
        logic                               st0_row_last    ;
        logic                               st0_col_first   ;
        logic                               st0_col_last    ;
        de_t                                st0_de          ;
        user_t                              st0_user        ;
        data_t  [TAPS-1:0]                  st0_data        ;
        logic                               st0_valid       ;
        
        rows_t                              st1_rows        ;
        cols_t                              st1_cols        ;
        logic                               st1_row_first   ;
        logic                               st1_row_last    ;
        logic                               st1_col_first   ;
        logic                               st1_col_last    ;
        de_t                                st1_de          ;
        user_t                              st1_user        ;
        data_t  [TAPS-1:0]                  st1_data        ;
        logic                               st1_valid       ;
        
        rows_t                              st2_rows        ;
        cols_t                              st2_cols        ;
        line_sel_t                          st2_sel         ;
        logic                               st2_row_first   ;
        logic                               st2_row_last    ;
        logic                               st2_col_first   ;
        logic                               st2_col_last    ;
        de_t                                st2_de          ;
        user_t                              st2_user        ;
        data_t  [TAPS-1:0]                  st2_data        ;
        logic                               st2_valid       ;
        
        rows_t  [ROWS-1:0]                  st3_rows        ;
        cols_t  [ROWS-1:0]                  st3_cols        ;
        logic   [ROWS-1:0]                  st3_row_first   ;
        logic   [ROWS-1:0]                  st3_row_last    ;
        logic                               st3_col_first   ;
        logic                               st3_col_last    ;
        de_t    [ROWS-1:0]                  st3_de          ;
        user_t  [ROWS-1:0]                  st3_user        ;
        data_t  [ROWS-1:0][TAPS-1:0]        st3_data        ;
        logic                               st3_valid       ;
        
        rows_t                              st4_rows        ;
        cols_t                              st4_cols        ;
        logic                               st4_row_first   ;
        logic                               st4_row_last    ;
        logic                               st4_col_first   ;
        logic                               st4_col_last    ;
        de_t                                st4_de          ;
        user_t                              st4_user        ;
        data_t   [ROWS-1:0][TAPS-1:0]       st4_data        ;
        pos_t                               st4_pos_first   ;
        pos_t                               st4_pos_last    ;
        logic                               st4_valid       ;
        
        rows_t                              st5_rows        ;
        cols_t                              st5_cols        ;
        logic                               st5_row_first   ;
        logic                               st5_row_last    ;
        logic                               st5_col_first   ;
        logic                               st5_col_last    ;
        de_t                                st5_de          ;
        user_t                              st5_user        ;
        data_t  [ROWS-1:0][TAPS-1:0]        st5_data        ;
        pos_t   [ROWS-1:0]                  st5_pos_data    ;
        logic                               st5_valid       ;
        
        rows_t                              st6_rows        ;
        cols_t                              st6_cols        ;
        logic                               st6_row_first   ;
        logic                               st6_row_last    ;
        logic                               st6_col_first   ;
        logic                               st6_col_last    ;
        de_t                                st6_de          ;
        logic   [USER_BITS-1:0]             st6_user        ;
        data_t  [ROWS-1:0][TAPS-1:0]        st6_data        ;
        logic                               st6_valid       ;
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st0_we            <= '0     ;
                st0_we[MEMS-1]    <= 1'b1   ;
                st0_addr          <= '0     ;
                st0_rows          <= 'x     ;
                st0_cols          <= 'x     ;
                st0_row_first     <= 1'b0   ;
                st0_row_last      <= 1'b0   ;
                st0_col_first     <= 1'b0   ;
                st0_col_last      <= 1'b0   ;
                st0_de            <= '0     ;
                st0_user          <= 'x     ;
                st0_data          <= 'x     ;
                st0_valid         <= 1'b0   ;
                
                st1_rows          <= 'x     ;
                st1_cols          <= 'x     ;
                st1_row_first     <= 1'b0   ;
                st1_row_last      <= 1'b0   ;
                st1_col_first     <= 1'b0   ;
                st1_col_last      <= 1'b0   ;
                st1_de            <= '0     ;
                st1_user          <= 'x     ;
                st1_data          <= 'x     ;
                st1_valid         <= 1'b0   ;
                
                st2_rows          <= 'x     ;
                st2_cols          <= 'x     ;
                st2_sel           <= '0     ;
                st2_row_first     <= 1'b0   ;
                st2_row_last      <= 1'b0   ;
                st2_col_first     <= 1'b0   ;
                st2_col_last      <= 1'b0   ;
                st2_de            <= '0     ;
                st2_user          <= 'x     ;
                st2_data          <= 'x     ;
                st2_valid         <= 1'b0   ;
                
                st3_rows          <= 'x     ;
                st3_cols          <= 'x     ;
                st3_row_first     <= '0     ;
                st3_row_last      <= '0     ;
                st3_col_first     <= 1'b0   ;
                st3_col_last      <= 1'b0   ;
                st3_de            <= '0     ;
                st3_user          <= 'x     ;
                st3_data          <= 'x     ;
                st3_valid         <= 1'b0   ;
                
                st4_rows          <= 'x     ;
                st4_cols          <= 'x     ;
                st4_row_first     <= 1'b0   ;
                st4_row_last      <= 1'b0   ;
                st4_col_first     <= 1'b0   ;
                st4_col_last      <= 1'b0   ;
                st4_de            <= '0     ;
                st4_user          <= 'x     ;
                st4_data          <= 'x     ;
                st4_pos_first     <= 'x     ;
                st4_pos_last      <= 'x     ;
                st4_valid         <= 1'b0   ;
                
                st5_rows          <= 'x     ;
                st5_cols          <= 'x     ;
                st5_row_first     <= 1'b0   ;
                st5_row_last      <= 1'b0   ;
                st5_col_first     <= 1'b0   ;
                st5_col_last      <= 1'b0   ;
                st5_de            <= '0     ;
                st5_user          <= 1'bx   ;
                st5_data          <= 'x     ;
                st5_pos_data      <= 'x     ;
                st5_valid         <= 1'b0   ;
                
                st6_rows          <= 'x     ;
                st6_cols          <= 'x     ;
                st6_row_first     <= 1'b0   ;
                st6_row_last      <= 1'b0   ;
                st6_col_first     <= 1'b0   ;
                st6_col_last      <= 1'b0   ;
                st6_de            <= '0     ;
                st6_user          <= 'x     ;
                st6_data          <= 'x     ;
                st6_valid         <= 1'b0   ;
            end
            else if ( cke ) begin
                // stage 0
                if ( s_mat_valid && s_mat_col_first ) begin
                    st0_we   <= MEMS'({2{st0_we}} >> 1);
                    st0_addr <= '0;
                end
                else begin
                    st0_addr <= st0_addr + 1'b1;
                end
                
                st0_rows      <= s_mat_rows     ;
                st0_cols      <= s_mat_cols     ;
                st0_row_first <= s_mat_valid ? s_mat_row_first : '0;
                st0_row_last  <= s_mat_valid ? s_mat_row_last  : '0;
                st0_col_first <= s_mat_valid ? s_mat_col_first : '0;
                st0_col_last  <= s_mat_valid ? s_mat_col_last  : '0;
                st0_de        <= s_mat_valid ? s_mat_de        : '0;
                st0_user      <= s_mat_user     ;
                st0_data      <= s_mat_data     ;
                st0_valid     <= s_mat_valid    ;
                

                // stage1
                st1_rows      <= st0_rows       ;
                st1_cols      <= st0_cols       ;
                st1_row_first <= st0_row_first  ;
                st1_row_last  <= st0_row_last   ;
                st1_col_first <= st0_col_first  ;
                st1_col_last  <= st0_col_last   ;
                st1_de        <= st0_de         ;
                st1_user      <= st0_user       ;
                st1_data      <= st0_data       ;
                st1_valid     <= st0_valid      ;
                

                // stage2
                if ( st1_valid && st1_col_first ) begin
                    st2_sel <= st2_sel - 1'b1;
                    if ( st2_sel == '0 ) begin
                        st2_sel <= line_sel_t'(MEMS-1);
                    end
                end
                st2_rows      <= st1_rows       ;
                st2_cols      <= st1_cols       ;
                st2_row_first <= st1_row_first  ;
                st2_row_last  <= st1_row_last   ;
                st2_col_first <= st1_col_first  ;
                st2_col_last  <= st1_col_last   ;
                st2_de        <= st1_de         ;
                st2_user      <= st1_user       ;
                st2_data      <= st1_data       ;
                st2_valid     <= st1_valid      ;
                

                // stage3
                if ( st2_valid && st2_col_first ) begin
                    st3_rows     [0] <= st2_rows        ;
                    st3_cols     [0] <= st2_cols        ;
                    st3_row_first[0] <= st2_row_first   ;
                    st3_row_last [0] <= st2_row_last    ;
                    st3_de       [0] <= st2_de          ;
                end
                st3_user     [0] <= st2_user        ;
                st3_data     [0] <= st2_data        ;
                for ( int i = 1; i < ROWS; ++i ) begin
                    if ( st2_valid && st2_col_first ) begin
                        st3_rows     [i] <= st3_rows     [i-1];
                        st3_cols     [i] <= st3_cols     [i-1];
                        st3_row_first[i] <= st3_row_first[i-1];
                        st3_row_last [i] <= st3_row_last [i-1];
                        st3_de       [i] <= st3_de       [i-1];
                    end
                    st3_user[i] <= mem_ruser[(i-1 + int'(st2_sel)) % MEMS];
                    st3_data[i] <= mem_rdata[(i-1 + int'(st2_sel)) % MEMS];
                end
                st3_col_first <= st2_col_first;
                st3_col_last  <= st2_col_last;
                st3_valid     <= st2_valid;
                

                // stage4
                st4_rows      <= st3_rows       [A] ;
                st4_cols      <= st3_cols       [A] ;
               if ( BYPASS_SIZE && st3_row_first[A] && st3_row_last[A] && st3_valid ) begin
                    st4_rows <= s_mat_rows;
                    st4_cols <= s_mat_cols;
                end

                st4_row_first <= st3_row_first  [A] ;
                st4_row_last  <= st3_row_last   [A] ;
                st4_col_first <= st3_col_first      ;
                st4_col_last  <= st3_col_last       ;
                st4_de        <= st3_de         [A] ;
                st4_user      <= st3_user       [A] ;
                st4_data      <= st3_data           ;
                st4_pos_first <= pos_t'(ROWS-1)     ;
                st4_pos_last  <= pos_t'(0)          ;
                st4_valid     <= st3_valid          ;
                
                begin : search_first
                    for ( int y = A; y < ROWS; y = y+1 ) begin
                        if ( st3_row_first[y] ) begin
                            st4_pos_first <= pos_t'(y);
                            disable search_first;
                        end
                    end
                end
                
                begin : search_last
                    for ( int y = A; y >= 0; y = y-1 ) begin
                        if ( st3_row_last[y] ) begin
                            st4_pos_last <= pos_t'(y);
                            disable search_last;
                        end
                    end
                end
                
                
                // stage5
                st5_rows      <= st4_rows       ;
                st5_cols      <= st4_cols       ;
                st5_row_first <= st4_row_first  ;
                st5_row_last  <= st4_row_last   ;
                st5_col_first <= st4_col_first  ;
                st5_col_last  <= st4_col_last   ;
                st5_de        <= st4_de         ;
                st5_user      <= st4_user       ;
                st5_data      <= st4_data       ;
                st5_valid     <= st4_valid      ;
                
                for ( int y = 0; y < ROWS; y = y+1 ) begin
                    st5_pos_data[y] <= POS_BITS'(y);
                    if ( y > A ) begin
                        if ( y > st4_pos_first ) begin
                            if      ( string'(BORDER_MODE) == "CONSTANT"    ) begin st5_pos_data[y] <= pos_t'(ROWS);                    end
                            else if ( string'(BORDER_MODE) == "REPLICATE"   ) begin st5_pos_data[y] <= st4_pos_first;                   end
                            else if ( string'(BORDER_MODE) == "REFLECT"     ) begin st5_pos_data[y] <= pos_t'(st4_pos_first*2 - y + 1); end
                            else if ( string'(BORDER_MODE) == "REFLECT_101" ) begin st5_pos_data[y] <= pos_t'(st4_pos_first*2 - y);     end
                        end
                    end
                    else if ( y < A ) begin
                        if ( y < st4_pos_last ) begin
                            if      ( string'(BORDER_MODE) == "CONSTANT"    ) begin st5_pos_data[y] <= pos_t'(ROWS);                    end
                            else if ( string'(BORDER_MODE) == "REPLICATE"   ) begin st5_pos_data[y] <= st4_pos_last;                    end
                            else if ( string'(BORDER_MODE) == "REFLECT"     ) begin st5_pos_data[y] <= pos_t'(st4_pos_last*2 - y - 1);  end
                            else if ( string'(BORDER_MODE) == "REFLECT_101" ) begin st5_pos_data[y] <= pos_t'(st4_pos_last*2 - y);      end
                        end
                    end
                end
                

                // stage6
                st6_rows      <= st5_rows       ;
                st6_cols      <= st5_cols       ;
               if ( BYPASS_SIZE && st5_row_first && st5_col_first && st5_valid ) begin
                    st6_rows <= s_mat_rows;
                    st6_cols <= s_mat_cols;
                end
                st6_row_first <= st5_row_first  ;
                st6_row_last  <= st5_row_last   ;
                st6_col_first <= st5_col_first  ;
                st6_col_last  <= st5_col_last   ;
                st6_de        <= st5_de         ;
                st6_user      <= st5_user       ;
                st6_data      <= st5_data       ;
                for ( int y = 0; y < ROWS; y = y+1 ) begin
                    st6_data[y] <= ($bits(data_t)*TAPS)'({{TAPS{BORDER_VALUE}}, st5_data} >> (($bits(data_t)*TAPS) * st5_pos_data[y]));
                end
                st6_valid     <= st5_valid;
            end
        end
        
        assign mem_we     = st0_we          ;
        assign mem_addr   = st0_addr        ;
        assign mem_wuser  = st0_user        ;
        assign mem_wdata  = st0_data        ;
        assign mem_wfirst = st0_row_first   ;
        assign mem_wlast  = st0_row_last    ;
        
        
        rows_t                          out_rows        ;
        cols_t                          out_cols        ;
        logic                           out_row_first   ;
        logic                           out_row_last    ;
        logic                           out_col_first   ;
        logic                           out_col_last    ;
        de_t                            out_de          ;
        user_t                          out_user        ;
        data_t  [ROWS-1:0][TAPS-1:0]    out_data        ;
        logic                           out_valid       ;
        
        if ( BORDER_MODE == "NONE" ) begin
            assign out_rows      = st4_rows         ;
            assign out_cols      = st4_cols         ;
            assign out_row_first = st4_row_first    ;
            assign out_row_last  = st4_row_last     ;
            assign out_col_first = st4_col_first    ;
            assign out_col_last  = st4_col_last     ;
            assign out_de        = st4_de           ;
            assign out_user      = st4_user         ;
            assign out_data      = st4_data         ;
            assign out_valid     = st4_valid        ;
        end
        else begin
            assign out_rows      = st6_rows         ;
            assign out_cols      = st6_cols         ;
            assign out_row_first = st6_row_first    ;
            assign out_row_last  = st6_row_last     ;
            assign out_col_first = st6_col_first    ;
            assign out_col_last  = st6_col_last     ;
            assign out_de        = st6_de           ;
            assign out_user      = st6_user         ;
            assign out_data      = st6_data         ;
            assign out_valid     = st6_valid        ;
        end

        assign m_mat_rows      = out_rows       ;
        assign m_mat_cols      = out_cols       ;
        assign m_mat_row_first = out_row_first  ;
        assign m_mat_row_last  = out_row_last   ;
        assign m_mat_col_first = out_col_first  ;
        assign m_mat_col_last  = out_col_last   ;
        assign m_mat_de        = out_de         ;
        assign m_mat_user      = out_user       ;
        for ( genvar tap = 0; tap < TAPS; tap++ ) begin :loop_tap
            for ( genvar i = 0; i < ROWS; i++ ) begin :loop_endian
                if ( ENDIAN ) begin
                    assign m_mat_data[tap][i] = out_data[i][TAPS-1-tap];
                end
                else begin
                    assign m_mat_data[tap][i] = out_data[ROWS-1-i][tap];
                end
            end
        end
        assign m_mat_valid       = out_valid;
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
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file
