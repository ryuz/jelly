// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly3_stream_width_convert
        #(
            parameter   int     UNIT_BITS        = 8                                    ,
            parameter   type    unit_t           = logic [UNIT_BITS-1:0]                ,
            parameter   int     S_NUM            = 1                                    ,
            parameter   int     M_NUM            = 1                                    ,
            parameter   bit     USE_FIRST        = 0                                    ,   // first を備える
            parameter   bit     USE_LAST         = 0                                    ,   // last を備える
            parameter   bit     USE_STRB         = 0                                    ,   // strb を備える
            parameter   bit     USE_KEEP         = 0                                    ,   // keep を備える
            parameter   bit     AUTO_FIRST       = !USE_FIRST                           ,   // last の次を自動的に first とする
            parameter   bit     USE_ALIGN_S      = 0                                    ,   // slave 側のアライメントを指定する
            parameter   bit     USE_ALIGN_M      = 0                                    ,   // master 側のアライメントを指定する
            parameter   bit     FIRST_OVERWRITE  = 0                                    ,   // first時前方に残変換があれば吐き出さずに上書き
            parameter   bit     FIRST_FORCE_LAST = 1                                    ,   // first時前方に残変換があれば強制的にlastを付与(残が無い場合はlastはつかない)
            parameter   bit     REDUCE_KEEP      = 0                                    ,
            parameter   int     ALIGN_S_BITS     = $clog2(S_NUM) > 0 ? $clog2(S_NUM) : 1,
            parameter   type    align_s_t        = logic [ALIGN_S_BITS-1:0]             ,
            parameter   int     ALIGN_M_BITS     = $clog2(M_NUM) > 0 ? $clog2(M_NUM) : 1,
            parameter   type    align_m_t        = logic [ALIGN_M_BITS-1:0]             ,
            parameter   int     USER_F_BITS      = 1                                    ,
            parameter   type    user_f_t         = logic [USER_F_BITS-1:0]              ,
            parameter   int     USER_L_BITS      = 1                                    ,
            parameter   type    user_l_t         = logic [USER_L_BITS-1:0]              ,
            parameter   bit     S_REG            = 1                                    ,
            parameter   bit     M_REG            = 1                                    
        )
        (
            input   var logic                   reset       ,
            input   var logic                   clk         ,
            input   var logic                   cke         ,
            
            input   var logic                   endian      ,
            input   var unit_t                  padding     ,
            
            input   var align_s_t               s_align_s   ,
            input   var align_m_t               s_align_m   ,
            input   var logic                   s_first     ,   // アライメント先頭
            input   var logic                   s_last      ,   // アライメント末尾
            input   var unit_t  [S_NUM-1:0]     s_data      ,
            input   var logic   [S_NUM-1:0]     s_strb      ,
            input   var logic   [S_NUM-1:0]     s_keep      ,
            input   var user_f_t                s_user_f    ,   // アライメント先頭前提で伝搬するユーザーデータ
            input   var user_l_t                s_user_l    ,   // アライメント末尾前提で伝搬するユーザーデータ
            input   var logic                   s_valid     ,
            output  var logic                   s_ready     ,
            
            output  var logic                   m_first     ,
            output  var logic                   m_last      ,
            output  var unit_t [M_NUM-1:0]      m_data      ,
            output  var logic  [M_NUM-1:0]      m_strb      ,
            output  var logic  [M_NUM-1:0]      m_keep      ,
            output  var user_f_t                m_user_f    ,
            output  var user_l_t                m_user_l    ,
            output  var logic                   m_valid     ,
            input   var logic                   m_ready     
        );
    
    
    // -----------------------------------------
    //  localparam
    // -----------------------------------------

    localparam  int     S_DATA_BITS = S_NUM * $bits(unit_t)                          ;
    localparam  type    s_data_t    = logic [S_DATA_BITS-1:0]                        ;
    localparam  int     M_DATA_BITS = M_NUM * $bits(unit_t)                          ;
    localparam  type    m_data_t    = logic [M_DATA_BITS-1:0]                        ;
    localparam  int     BUF_NUM     = S_NUM != M_NUM ? (S_NUM + M_NUM - 1) : S_NUM   ;
    localparam  int     BUF_BITS    = BUF_NUM * $bits(unit_t)                        ;
    localparam  type    buf_t       = logic [BUF_BITS-1:0]                           ;
    localparam  int     COUNT_BITS  = $clog2(BUF_NUM+1) > 0 ? $clog2(BUF_NUM+1) : 1  ;
    localparam  type    count_t     = logic [COUNT_BITS-1:0]                         ;
    
    
    
    // -----------------------------------------
    //  functions
    // -----------------------------------------
     
    // strb to data
    function automatic buf_t strb_to_data(
                                        input [BUF_NUM-1:0] strb
                                    );
        for ( int i = 0; i < $bits(buf_t) ; i++ ) begin
            strb_to_data[i] = strb[i] ? '1 : '0;
        end
    endfunction
    
    
    // set data
    function automatic buf_t set_data(
                                        input logic     endian  ,
                                        input buf_t     orgn    ,
                                        input s_data_t  data    ,
                                        input count_t   position
                                    );
        set_data = orgn;
        for ( int i = 0; i < $bits(s_data_t); i++ ) begin
            if ( endian ) begin
                set_data[($bits(buf_t)-1) - (int'(position)*$bits(unit_t) + i)] = data[$bits(s_data_t)-1 - i];
            end
            else begin
                set_data[int'(position)*$bits(unit_t) + i] = data[i];
            end
        end
    endfunction
    
    // set strb
    function automatic logic [BUF_NUM-1:0] set_strb(
                                        input logic                     endian  ,
                                        input logic     [BUF_NUM-1:0]   orgn    ,
                                        input logic     [S_NUM-1:0]     strb    ,
                                        input count_t                   position
                                    );
        set_strb = orgn;
        for ( int i = 0; i < S_NUM; i++ ) begin
            if ( endian ) begin
                set_strb[(BUF_NUM-1) - int'(position) + i] = strb[S_NUM-1 - i];
            end
            else begin
                set_strb[int'(position) + i] = strb[i];
            end
        end
    endfunction
    
    
    // get data
    function automatic m_data_t get_data(
                                        input logic     endian  ,
                                        input buf_t     data    ,
                                        input count_t   position
                                    );
        get_data = '0;
        for ( int i = 0; i < $bits(m_data_t); i++ ) begin
            if ( position*$bits(unit_t) + i < $bits(buf_t) ) begin
                if ( endian ) begin
                    get_data[$bits(m_data_t)-1 - i] = data[$bits(buf_t)-1 - (int'(position)*$bits(unit_t) + i)];
                end
                else begin
                    get_data[i] = data[int'(position)*$bits(unit_t) + i];
                end
            end
        end
    endfunction

    // get strb
    function automatic logic [M_NUM-1:0] get_strb(
                                        input logic                 endian  ,
                                        input logic [BUF_NUM-1:0]   strb    ,
                                        input count_t               position
                                    );
        get_strb = '0;
        for (int i = 0; i < M_NUM; ++i) begin
            if (int'(position) + i < BUF_NUM) begin
                if (endian) begin
                    get_strb[M_NUM-1 - i] = strb[BUF_NUM-1 - (int'(position) + i)];
                end else begin
                    get_strb[i] = strb[int'(position) + i];
                end
            end
        end
    endfunction

    // shift strb
    function automatic logic [BUF_NUM-1:0] shift_strb(
                                        input logic                 endian  ,
                                        input logic   [BUF_NUM-1:0] strb    ,
                                        input count_t               count
                                    );
        return  endian ? (strb << count) : (strb >> count);
    endfunction

    // shift data
    function automatic buf_t shift_data(
                                        input logic                 endian  ,
                                        input unit_t [BUF_NUM-1:0]  data    ,
                                        input count_t               count
                                    );
        return endian ? (data << (count * $bits(unit_t))) : (data >> (count * $bits(unit_t)));
    endfunction

    // data strb
    function automatic unit_t [M_NUM-1:0] strb_data(
                input unit_t [M_NUM-1:0] orgn,
                input unit_t [M_NUM-1:0] data,
                input logic  [M_NUM-1:0] strb
            );
        for (int i = 0; i < M_NUM; i++) begin
            strb_data[i] = strb[i] ? data[i] : orgn[i];
        end
    endfunction
    
    
    
    // -----------------------------------------
    //  insert FF
    // -----------------------------------------
    
    // auto first flag
    logic    reg_auto_first;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_auto_first <= 1'b1;
        end
        else if ( cke ) begin
            if ( s_valid && s_ready ) begin
                reg_auto_first <= (USE_LAST && s_last);
            end
        end
    end
    logic    auto_first = (AUTO_FIRST && USE_LAST && reg_auto_first);
    
    typedef struct packed {
        unit_t   [S_NUM-1:0]    data    ;
        logic    [S_NUM-1:0]    strb    ;
        logic    [S_NUM-1:0]    keep    ;
        user_f_t                user_f  ;
        user_l_t                user_l  ;
        logic                   first   ;
        logic                   last    ;
        align_s_t               align_s ;
        align_m_t               align_m ;
    } s_pack_t;

    s_pack_t     s_packet   ;
    assign s_packet.data    = s_data                                        ;
    assign s_packet.strb    = USE_STRB ? s_strb : '1                        ;
    assign s_packet.keep    = USE_KEEP ? s_keep : '1                        ;
    assign s_packet.user_f  = s_user_f                                      ;
    assign s_packet.user_l  = s_user_l                                      ;
    assign s_packet.first   = (USE_FIRST  ? s_first   : 1'b0) | auto_first  ;
    assign s_packet.last    = USE_LAST    ? s_last    : 1'b0                ;
    assign s_packet.align_s = USE_ALIGN_S ? s_align_s : '0                  ;
    assign s_packet.align_m = USE_ALIGN_M ? s_align_m : '0                  ;

    s_pack_t     ff_s_packet;
    logic        ff_s_valid ;
    logic        ff_s_ready ;

    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(s_pack_t)    ),
                .data_t         (s_pack_t           ),
                .S_REG          (S_REG              ),
                .M_REG          (1                  )
            )
        u_stream_ff_s
            (
                .reset          (reset              ),
                .clk            (clk                ),
                .cke            (cke                ),

                .s_data         (s_packet           ),
                .s_valid        (s_valid            ),
                .s_ready        (s_ready            ),

                .m_data         (ff_s_packet        ),
                .m_valid        (ff_s_valid         ),
                .m_ready        (ff_s_ready         )
            );

    
    // -----------------------------------------
    //  stage0 alignment
    // -----------------------------------------
    
    // alignment
    unit_t   [S_NUM-1:0]        st0_data    ;
    logic    [S_NUM-1:0]        st0_strb    ;
    logic    [S_NUM-1:0]        st0_keep    ;
    user_f_t                    st0_user_f  ;
    user_l_t                    st0_user_l  ;
    logic                       st0_first   ;
    logic                       st0_last    ;
    count_t                     st0_count   ;
    logic                       st0_valid   ;
    logic                       st0_ready   ;
    
    if ( USE_ALIGN_S || USE_ALIGN_M ) begin : st0_align
        unit_t  [S_NUM-1:0]     tmp_data    ;
        logic   [S_NUM-1:0]     tmp_strb    ;
        logic   [S_NUM-1:0]     tmp_keep    ;
        
        unit_t  [S_NUM-1:0]     reg_data    ;
        logic   [S_NUM-1:0]     reg_strb    ;
        logic   [S_NUM-1:0]     reg_keep    ;
        user_f_t                reg_user_f  ;
        user_l_t                reg_user_l  ;
        logic                   reg_first   ;
        logic                   reg_last    ;
        count_t                 reg_count   ;
        logic                   reg_valid   ;
        always_ff @(posedge clk) begin
            if ( cke && ff_s_ready ) begin
                if ( ff_s_packet.first ) begin
                    if ( endian ) begin
                        tmp_data = (ff_s_packet.data >> (ff_s_packet.align_s * $bits(unit_t)));
                        tmp_strb = (ff_s_packet.strb >> ff_s_packet.align_s);
                        tmp_keep = (ff_s_packet.keep >> ff_s_packet.align_s);
                    end
                    else begin
                        tmp_data = (ff_s_packet.data << (ff_s_packet.align_s * $bits(unit_t)));
                        tmp_strb = (ff_s_packet.strb << ff_s_packet.align_s);
                        tmp_keep = (ff_s_packet.keep << ff_s_packet.align_s);
                    end
                end
                else begin
                    tmp_data = ff_s_packet.data;
                    tmp_strb = ff_s_packet.strb;
                    tmp_keep = ff_s_packet.keep;
                end
                
                reg_data   <= tmp_data          ;
                reg_strb   <= tmp_strb          ;
                reg_keep   <= tmp_keep          ;
                reg_user_f <= ff_s_packet.user_f;
                reg_user_l <= ff_s_packet.user_l;
                reg_first  <= ff_s_packet.first ;
                reg_last   <= ff_s_packet.last  ;
                reg_count  <= ff_s_packet.first ? (count_t'(S_NUM) - count_t'(ff_s_packet.align_s) + count_t'(ff_s_packet.align_m)) : count_t'(S_NUM);
            end
        end
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_valid <= 1'b0;
            end
            else if ( cke && ff_s_ready ) begin
                reg_valid <= ff_s_valid;
            end
        end
        
        assign ff_s_ready  = !st0_valid || st0_ready;
        
        assign st0_data    = reg_data   ;
        assign st0_strb    = reg_strb   ;
        assign st0_keep    = reg_keep   ;
        assign st0_user_f  = reg_user_f ;
        assign st0_user_l  = reg_user_l ;
        assign st0_first   = reg_first  ;
        assign st0_last    = reg_last   ;
        assign st0_count   = reg_count  ;
        assign st0_valid   = reg_valid  ;
    end
    else begin : st0_bypass
        assign ff_s_ready  = st0_ready          ;
        
        assign st0_data    = ff_s_packet.data   ;
        assign st0_strb    = ff_s_packet.strb   ;
        assign st0_keep    = ff_s_packet.keep   ;
        assign st0_user_f  = ff_s_packet.user_f ;
        assign st0_user_l  = ff_s_packet.user_l ;
        assign st0_first   = ff_s_packet.first  ;
        assign st0_last    = ff_s_packet.last   ;
        assign st0_count   = count_t'(S_NUM)    ;
        assign st0_valid   = ff_s_valid         ;
    end
    

    
    // -----------------------------------------
    //  stage1 data buffer
    // -----------------------------------------
    
    count_t                     st1_count   ;
    unit_t   [BUF_NUM-1:0]      st1_data    ;
    logic    [BUF_NUM-1:0]      st1_strb    ;
    logic    [BUF_NUM-1:0]      st1_keep    ;
    user_f_t                    st1_user_f  ;
    user_l_t                    st1_user_l  ;
    logic                       st1_first   ;
    logic                       st1_last    ;
    logic                       st1_valid   ;
    logic                       st1_ready   ;
    
    if ( S_NUM != M_NUM ) begin : st1_buffer
        count_t                     reg_count   , next_count    ;
        unit_t  [BUF_NUM-1:0]       reg_data    , next_data     ;
        logic   [BUF_NUM-1:0]       reg_strb    , next_strb     ;
        logic   [BUF_NUM-1:0]       reg_keep    , next_keep     ;
        user_f_t                    reg_user_f  , next_user_f   ;
        user_l_t                    reg_user_l  , next_user_l   ;
        logic                       reg_first   , next_first    ;
        logic                       reg_last    , next_last     ;
        logic                       reg_flag_l  , next_flag_l   ;   // フラグ予約
        logic                       reg_flush   , next_flush    ;   // 最終データがバッファに入ったフラグ
        logic                       reg_empty   , next_empty    ;   // 完全に空
        logic                       reg_free    , next_free     ;   // 即時受け入れ可
        logic                       reg_ready   , next_ready    ;   // 今のデータが吐き出せれば受け入れ可
        logic                       reg_valid   , next_valid    ;
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_count  <= '0    ;
                reg_data   <= 'x    ;
                reg_strb   <= '0    ;
                reg_keep   <= '0    ;
                reg_user_f <= '0    ;
                reg_user_l <= '0    ;
                reg_first  <= 1'b0  ;
                reg_last   <= 1'b0  ;
                reg_flag_l <= 1'b1  ;
                reg_flush  <= 1'b0  ;
                reg_empty  <= 1'b1  ;
                reg_free   <= 1'b1  ;
                reg_valid  <= 1'b0  ;
            end
            else if ( cke ) begin
                reg_count  <= next_count    ;
                reg_data   <= next_data     ;
                reg_strb   <= next_strb     ;
                reg_keep   <= next_keep     ;
                reg_user_f <= next_user_f   ;
                reg_user_l <= next_user_l   ;
                reg_first  <= next_first    ;
                reg_last   <= next_last     ;
                reg_flag_l <= next_flag_l   ;
                reg_flush  <= next_flush    ;
                reg_empty  <= next_empty    ;
                reg_free   <= next_free     ;
                reg_ready  <= next_ready    ;
                reg_valid  <= next_valid    ;
            end
        end
        
        always_comb begin
            next_count  = reg_count     ;
            next_data   = reg_data      ;
            next_strb   = reg_strb      ;
            next_keep   = reg_keep      ;
            next_user_f = reg_user_f    ;
            next_user_l = reg_user_l    ;
            next_first  = reg_first     ;
            next_last   = reg_last      ;
            next_flag_l = reg_flag_l    ;
            next_flush  = reg_flush     ;
            next_empty  = reg_empty     ;
            next_free   = reg_free      ;
            next_ready  = reg_ready     ;
            next_valid  = reg_valid     ;
            
            
            // 出力があればサイズを減らしてフラグクリア
            if ( st1_valid & st1_ready ) begin
                next_count  = (int'(next_count) > M_NUM) ? (next_count - count_t'(M_NUM)) : 0;
                next_first  = 1'b0;
                if ( reg_last ) begin
                    next_last  = 1'b0;
                    next_flush = 1'b0;
                end
            end
            
            // 上書きモード以外でバッファ残があるときにfirstが来たら強制的にflush開始
            if ( !reg_flush && next_count > 0 && st0_valid && st0_first ) begin
                next_flush  = 1'b1;
                next_flag_l = FIRST_FORCE_LAST;
                next_user_l = '0;
            end
            
            if ( st0_ready & st0_valid ) begin
                if ( st0_first ) begin
                    // 先頭ならリフレッシュ
                    next_data   = 'x        ;
                    next_strb   = '0        ;
                    next_keep   = '0        ;
                    next_count  = st0_count ;
                    next_user_f = st0_user_f;
                    next_flush  = 1'b0      ;
                    next_first  = 1'b1      ;
                end
                else begin
                    // 継続ならシフト
                    next_data   = shift_data(endian, next_data, count_t'(S_NUM));
                    next_strb   = shift_strb(endian, next_strb, count_t'(S_NUM));
                    next_keep   = shift_strb(endian, next_keep, count_t'(S_NUM));
                    next_count  = next_count + st0_count;
                end
                
                next_data = set_data(endian, next_data, st0_data, count_t'(BUF_NUM-S_NUM));
                next_strb = set_strb(endian, next_strb, st0_strb, count_t'(BUF_NUM-S_NUM));
                next_keep = set_strb(endian, next_keep, st0_keep, count_t'(BUF_NUM-S_NUM));
                
                // last ならフラグを立てる
                if ( st0_last ) begin
                    next_user_l = st0_user_l;
                    next_flush  = 1'b1;
                    next_flag_l = 1'b1;
                end
            end
            
            next_empty = (next_count == 0);
            next_free  = (BUF_NUM - int'(next_count) >= S_NUM) && !next_flush;
            next_last  = (next_flush && int'(next_count) <= M_NUM);
            
            next_valid = (int'(next_count) >= M_NUM) || next_flush;
            next_ready = ((BUF_NUM - int'(next_count) + M_NUM >= S_NUM) && next_valid && !next_flush) || (next_valid && next_last && int'(next_count) <= M_NUM);
        end
        
        assign st0_ready  = ((reg_ready && st1_ready) || reg_free) && (FIRST_OVERWRITE || !USE_FIRST || !(!reg_empty && st0_valid && st0_first));
        
        assign st1_count  = reg_count                   ;
        assign st1_data   = reg_data                    ;
        assign st1_strb   = reg_strb                    ;
        assign st1_keep   = reg_keep                    ;
        assign st1_user_f = reg_first ? reg_user_f : '0 ;
        assign st1_user_l = reg_last  ? reg_user_l : '0 ;
        assign st1_first  = reg_first                   ;
        assign st1_last   = reg_last & reg_flag_l       ;
        assign st1_valid  = reg_valid                   ;
    end
    else begin : st1_bypass
        assign st0_ready  = st1_ready                   ;
        
        assign st1_count  = count_t'(S_NUM)             ;
        assign st1_data   = st0_data                    ;
        assign st1_strb   = st0_strb                    ;
        assign st1_keep   = st0_keep                    ;
        assign st1_user_f = st0_user_f                  ;
        assign st1_user_l = st0_user_l                  ;
        assign st1_first  = st0_first                   ;
        assign st1_last   = st0_last                    ;
        assign st1_valid  = st0_valid                   ;
    end
    
    
    
    
    // -----------------------------------------
    //  stage2 multiplexer
    // -----------------------------------------
    
    unit_t  [M_NUM-1:0]     st2_data    ;
    logic   [M_NUM-1:0]     st2_strb    ;
    logic   [M_NUM-1:0]     st2_keep    ;
    user_f_t                st2_user_f  ;
    user_l_t                st2_user_l  ;
    logic                   st2_first   ;
    logic                   st2_last    ;
    logic                   st2_none    ;
    logic                   st2_valid   ;
    logic                   st2_ready   ;
    
    if ( S_NUM != M_NUM ) begin : st2_multiplexer
        unit_t  [M_NUM-1:0]     reg_data    , next_data     ;
        logic   [M_NUM-1:0]     reg_strb    , next_strb     ;
        logic   [M_NUM-1:0]     reg_keep    , next_keep     ;
        user_f_t                reg_user_f  , next_user_f   ;
        user_l_t                reg_user_l  , next_user_l   ;
        logic                   reg_first   , next_first    ;
        logic                   reg_last    , next_last     ;
        logic                   reg_none    , next_none     ;
        logic                   reg_valid   , next_valid    ;
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_data   <= 'x    ;
                reg_strb   <= '0    ;
                reg_keep   <= '0    ;
                reg_user_f <= '0    ;
                reg_user_l <= '0    ;
                reg_first  <= 1'b0  ;
                reg_last   <= 1'b0  ;
                reg_none   <= 1'b0  ;
                reg_valid  <= 1'b0  ;
            end
            else if ( cke ) begin
                reg_data   <= next_data     ;
                reg_strb   <= next_strb     ;
                reg_keep   <= next_keep     ;
                reg_user_f <= next_user_f   ;
                reg_user_l <= next_user_l   ;
                reg_first  <= next_first    ;
                reg_last   <= next_last     ;
                reg_none   <= next_none     ;
                reg_valid  <= next_valid    ;
            end
        end
        
        always_comb begin
            next_data   = reg_data      ;
            next_strb   = reg_strb      ;
            next_keep   = reg_keep      ;
            next_user_f = reg_user_f    ;
            next_user_l = reg_user_l    ;
            next_first  = reg_first     ;
            next_last   = reg_last      ;
            next_none   = reg_none      ;
            next_valid  = reg_valid     ;
            
            if ( st2_ready ) begin
                next_valid = 1'b0;
            end
            
            if ( st1_ready & st1_valid ) begin
                next_data = get_data(endian, st1_data, count_t'(BUF_NUM) - st1_count);
                next_strb = get_strb(endian, st1_strb, count_t'(BUF_NUM) - st1_count);
                next_keep = get_strb(endian, st1_keep, count_t'(BUF_NUM) - st1_count);
                
                next_user_f = st1_user_f;
                next_user_l = st1_user_l;
                next_first  = st1_first ;
                next_last   = st1_last  ;
                next_valid  = st1_valid ;
            end
            
            next_none = ((next_keep == 0) && REDUCE_KEEP);
        end
        
        assign st1_ready  = (!st2_valid || st2_ready);
        
        assign st2_data   = reg_data    ;
        assign st2_strb   = reg_strb    ;
        assign st2_keep   = reg_keep    ;
        assign st2_user_f = reg_user_f  ;
        assign st2_user_l = reg_user_l  ;
        assign st2_first  = reg_first   ;
        assign st2_last   = reg_last    ;
        assign st2_none   = reg_none    ;
        assign st2_valid  = reg_valid   ;
    end
    else begin : st2_bypass
        assign st1_ready  = st2_ready;
        
        assign st2_data   = st1_data                        ;
        assign st2_strb   = st1_strb                        ;
        assign st2_keep   = st1_keep                        ;
        assign st2_user_f = st1_user_f                      ;
        assign st2_user_l = st1_user_l                      ;
        assign st2_first  = st1_first                       ;
        assign st2_last   = st1_last                        ;
        assign st2_none   = ((st1_keep == 0) && REDUCE_KEEP);
        assign st2_valid  = st1_valid                       ;
    end
    
    
    
    // -----------------------------------------
    //  insert FF
    // -----------------------------------------
    


    typedef struct packed {
        unit_t [M_NUM-1:0]  data    ;
        logic  [M_NUM-1:0]  strb    ;
        logic  [M_NUM-1:0]  keep    ;
        user_f_t            user_f  ;
        user_l_t            user_l  ;
        logic               last    ;
        logic               first   ;
    } m_pack_t;

    m_pack_t    ff_m_packet ;
    logic       ff_m_valid  ;
    logic       ff_m_ready  ;

    assign  ff_m_packet.data   = strb_data({M_NUM{padding}}, st2_data, st2_strb)    ;
    assign  ff_m_packet.strb   = st2_strb                                           ;
    assign  ff_m_packet.keep   = USE_KEEP ? st2_keep : '1                           ;
    assign  ff_m_packet.user_f = st2_user_f                                         ;
    assign  ff_m_packet.user_l = st2_user_l                                         ;
    assign  ff_m_packet.last   = st2_last                                           ;
    assign  ff_m_packet.first  = st2_first                                          ;
    assign  ff_m_valid         = st2_valid & ~st2_none                              ;
    assign  st2_ready          = (ff_m_ready | st2_none)                            ;

    m_pack_t    m_packet;
    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(m_packet)    ),
                .data_t         (m_pack_t           ),
                .S_REG          (1                  ),
                .M_REG          (M_REG              )
            )
        u_stream_ff_m
            (
                .reset          (reset              ),
                .clk            (clk                ),
                .cke            (cke                ),

                .s_data         (ff_m_packet        ),
                .s_valid        (ff_m_valid         ),
                .s_ready        (ff_m_ready         ),

                .m_data         (m_packet           ),
                .m_valid        (m_valid            ),
                .m_ready        (m_ready            )
            );

   assign   m_first  = m_packet.first    ;
   assign   m_last   = m_packet.last     ;
   assign   m_data   = m_packet.data     ;
   assign   m_strb   = m_packet.strb     ;
   assign   m_keep   = m_packet.keep     ;
   assign   m_user_f = m_packet.user_f   ;
   assign   m_user_l = m_packet.user_l   ;

endmodule


`default_nettype wire


// end of file
