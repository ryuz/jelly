// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 許可した分だけデータを通すゲート
// first や last は 上位次元でbitが立っているとき下位次元は必ず立っているとみなす



// 境界や個数でストリーム通過を制御
module jelly2_stream_gate
        #(
            parameter   int                 N               = 1,          // 次元数(dimension)
            parameter   bit                 BYPASS          = 0,          // バイパス
            parameter   bit                 BYPASS_COMBINE  = 0,          // バイパス時にpermitもcombineするか
            parameter   bit                 DETECTOR_ENABLE = 0,          // フラグ検出器(読み飛ばし/パディング)を使うか
            parameter   bit     [N-1:0]     AUTO_FIRST      = {N{1'b1}},  // lastの後を自動的にfirst扱いにする(first利用時にあえて無視したい場合に倒す)
            
            parameter   int                 DATA_WIDTH      = 32,
            parameter   int                 LEN_WIDTH       = 32,
            parameter   bit                 LEN_OFFSET      = 1'b1,
            parameter   int                 USER_WIDTH      = 0,
            parameter   bit                 S_REGS          = 1,
            parameter   bit                 M_REGS          = 1,
            
            parameter   bit                 ASYNC           = 0,
            parameter   int                 FIFO_PTR_WIDTH  = ASYNC ? 4 : 0,
            parameter   bit                 FIFO_DOUT_REGS  = 0,
            parameter                       FIFO_RAM_TYPE   = "distributed",
            parameter   bit                 FIFO_LOW_DEALY  = 1,
            parameter   bit                 FIFO_S_REGS     = 0,
            parameter   bit                 FIFO_M_REGS     = 0,
            
            // local
            localparam  int                 USER_BITS       = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        skip,           // 非busy時に読み飛ばす
            input   wire    [N-1:0]             detect_first,
            input   wire    [N-1:0]             detect_last,
            input   wire                        padding_en,
            input   wire    [DATA_WIDTH-1:0]    padding_data,
            
            input   wire    [N-1:0]             s_first,
            input   wire    [N-1:0]             s_last,
            input   wire    [DATA_WIDTH-1:0]    s_data,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire    [N-1:0]             m_first,
            output  wire    [N-1:0]             m_last,
            output  wire    [DATA_WIDTH-1:0]    m_data,
            output  wire    [USER_BITS-1:0]     m_user,
            output  wire                        m_valid,
            input   wire                        m_ready,
            
            
            input   wire                        s_permit_reset,
            input   wire                        s_permit_clk,
            input   wire    [N-1:0]             s_permit_first,
            input   wire    [N-1:0]             s_permit_last,
            input   wire    [LEN_WIDTH-1:0]     s_permit_len,
            input   wire    [USER_BITS-1:0]     s_permit_user,
            input   wire                        s_permit_valid,
            output  wire                        s_permit_ready
        );

    (* MARK_DEBUG="true" *) wire                        dbg_skip           = skip          ;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             dbg_detect_first   = detect_first  ;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             dbg_detect_last    = detect_last   ;
    (* MARK_DEBUG="true" *) wire                        dbg_padding_en     = padding_en    ;
    (* MARK_DEBUG="true" *) wire    [DATA_WIDTH-1:0]    dbg_padding_data   = padding_data  ;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             dbg_s_first        = s_first       ;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             dbg_s_last         = s_last        ;
    (* MARK_DEBUG="true" *) wire    [DATA_WIDTH-1:0]    dbg_s_data         = s_data        ;
    (* MARK_DEBUG="true" *) wire                        dbg_s_valid        = s_valid       ;
    (* MARK_DEBUG="true" *) wire                        dbg_s_ready        = s_ready       ;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             dbg_m_first        = m_first       ;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             dbg_m_last         = m_last        ;
    (* MARK_DEBUG="true" *) wire    [DATA_WIDTH-1:0]    dbg_m_data         = m_data        ;
    (* MARK_DEBUG="true" *) wire    [USER_BITS-1:0]     dbg_m_user         = m_user        ;
    (* MARK_DEBUG="true" *) wire                        dbg_m_valid        = m_valid       ;
    (* MARK_DEBUG="true" *) wire                        dbg_m_ready        = m_ready       ;
    (* MARK_DEBUG="true" *) wire                        dbg_s_permit_reset = s_permit_reset;
    (* MARK_DEBUG="true" *) wire                        dbg_s_permit_clk   = s_permit_clk  ;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             dbg_s_permit_first = s_permit_first;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             dbg_s_permit_last  = s_permit_last ;
    (* MARK_DEBUG="true" *) wire    [LEN_WIDTH-1:0]     dbg_s_permit_len   = s_permit_len  ;
    (* MARK_DEBUG="true" *) wire    [USER_BITS-1:0]     dbg_s_permit_user  = s_permit_user ;
    (* MARK_DEBUG="true" *) wire                        dbg_s_permit_valid = s_permit_valid;
    (* MARK_DEBUG="true" *) wire                        dbg_s_permit_ready = s_permit_ready;

    logic [13:0]  s_count;
    always_ff @(posedge clk) begin
        if ( s_valid && s_ready ) begin
            if ( s_first ) begin
                s_count <= '0;
            end
            else begin
                s_count <= s_count + 1;
            end
        end
    end
    
    // clock convert
    (* MARK_DEBUG="true" *) wire    [N-1:0]             fifo_s_permit_first;
    (* MARK_DEBUG="true" *) wire    [N-1:0]             fifo_s_permit_last;
    (* MARK_DEBUG="true" *) wire    [LEN_WIDTH-1:0]     fifo_s_permit_len;
    (* MARK_DEBUG="true" *) wire    [USER_BITS-1:0]     fifo_s_permit_user;
    (* MARK_DEBUG="true" *) wire                        fifo_s_permit_valid;
    (* MARK_DEBUG="true" *) wire                        fifo_s_permit_ready;
    
    generate
    if ( !BYPASS || (BYPASS_COMBINE && ASYNC) ) begin : blk_async_fifo
        logic   [N-1:0]         fifo_s_permit_first_tmp;
        logic   [N-1:0]         fifo_s_permit_last_tmp;
        logic   [LEN_WIDTH-1:0] fifo_s_permit_len_tmp;
        logic   [USER_BITS-1:0] fifo_s_permit_user_tmp;
        // verilator lint_off PINMISSING
        jelly2_fifo_pack
                #(
                    .ASYNC              (ASYNC),
                    .DATA0_WIDTH        (N),
                    .DATA1_WIDTH        (N),
                    .DATA2_WIDTH        (LEN_WIDTH),
                    .DATA3_WIDTH        (USER_WIDTH),
                    
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .S_REGS             (FIFO_S_REGS),
                    .M_REGS             (FIFO_M_REGS)
                )
            i_fifo_pack_sr
                (
                    .s_reset            (s_permit_reset),
                    .s_clk              (s_permit_clk),
                    .s_cke              (1'b1),
                    .s_data0            (s_permit_first),
                    .s_data1            (s_permit_last),
                    .s_data2            (s_permit_len),
                    .s_data3            (s_permit_user),
                    .s_valid            (s_permit_valid),
                    .s_ready            (s_permit_ready),
                    
                    .m_reset            (reset),
                    .m_clk              (clk),
                    .m_cke              (1'b1),
                    .m_data0            (fifo_s_permit_first_tmp),
                    .m_data1            (fifo_s_permit_last_tmp),
                    .m_data2            (fifo_s_permit_len_tmp),
                    .m_data3            (fifo_s_permit_user_tmp),
                    .m_valid            (fifo_s_permit_valid),
                    .m_ready            (fifo_s_permit_ready & cke)
                );
        // verilator lint_on PINMISSING
        assign  fifo_s_permit_first = fifo_s_permit_valid ? fifo_s_permit_first_tmp : '0;
        assign  fifo_s_permit_last  = fifo_s_permit_valid ? fifo_s_permit_last_tmp  : '0;
        assign  fifo_s_permit_len   = fifo_s_permit_valid ? fifo_s_permit_len_tmp   : '0;
        assign  fifo_s_permit_user  = fifo_s_permit_valid ? fifo_s_permit_user_tmp  : '0;
    end
    else begin : blk_sync
        assign fifo_s_permit_first = s_permit_first;
        assign fifo_s_permit_last  = s_permit_last;
        assign fifo_s_permit_len   = s_permit_len;
        assign fifo_s_permit_user  = s_permit_user;
        assign fifo_s_permit_valid = s_permit_valid;
        assign s_permit_ready      = fifo_s_permit_ready;
    end
    endgenerate
    
    
    
    generate
    if ( BYPASS ) begin : blk_bypass
        assign m_first             = s_first;
        assign m_last              = s_last;
        assign m_data              = s_data;
        assign m_user              = BYPASS_COMBINE ? (fifo_s_permit_user)              : {USER_BITS{1'bx}};
        assign m_valid             = BYPASS_COMBINE ? (s_valid & fifo_s_permit_valid)   : s_valid;
        assign s_ready             = BYPASS_COMBINE ? (m_ready & fifo_s_permit_valid)   : m_ready;
        assign fifo_s_permit_ready = BYPASS_COMBINE ? (m_ready & s_valid & s_last[0])   : 1'b1;
    end
    else begin : blk_gate
        // parameter
        (* MARK_DEBUG="true" *) wire                        param_skip         = skip;
        (* MARK_DEBUG="true" *) wire    [N-1:0]             param_detect_first = DETECTOR_ENABLE ? detect_first : {N{1'b0}};
        (* MARK_DEBUG="true" *) wire    [N-1:0]             param_detect_last  = DETECTOR_ENABLE ? detect_last  : {N{1'b0}};
        (* MARK_DEBUG="true" *) wire                        param_padding_en   = DETECTOR_ENABLE ? padding_en   : 1'b0;
        
        // insert FF
        (* MARK_DEBUG="true" *) wire    [N-1:0]             ff_s_first;
        (* MARK_DEBUG="true" *) wire    [N-1:0]             ff_s_last;
        (* MARK_DEBUG="true" *) wire    [DATA_WIDTH-1:0]    ff_s_data;
        (* MARK_DEBUG="true" *) wire                        ff_s_valid;
        (* MARK_DEBUG="true" *) wire                        ff_s_ready;
        
        (* MARK_DEBUG="true" *) wire    [N-1:0]             ff_m_first;
        (* MARK_DEBUG="true" *) wire    [N-1:0]             ff_m_last;
        (* MARK_DEBUG="true" *) wire    [DATA_WIDTH-1:0]    ff_m_data;
        (* MARK_DEBUG="true" *) wire    [USER_BITS-1:0]     ff_m_user;
        (* MARK_DEBUG="true" *) wire                        ff_m_valid;
        (* MARK_DEBUG="true" *) wire                        ff_m_ready;
        
        // verilator lint_off PINMISSING
        jelly2_data_ff_pack
                #(
                    .DATA0_WIDTH    (N),
                    .DATA1_WIDTH    (N),
                    .DATA2_WIDTH    (DATA_WIDTH),
                    .S_REGS         (S_REGS),
                    .M_REGS         (0)
                )
            i_data_ff_pack_s
                (
                    .reset          (reset),
                    .clk            (clk),
                    .cke            (cke),
                    
                    .s_data0        (s_first),
                    .s_data1        (s_last),
                    .s_data2        (s_data),
                    .s_valid        (s_valid),
                    .s_ready        (s_ready),
                    
                    .m_data0        (ff_s_first),
                    .m_data1        (ff_s_last),
                    .m_data2        (ff_s_data),
                    .m_valid        (ff_s_valid),
                    .m_ready        (ff_s_ready)
                );
        // verilator lint_on PINMISSING
        
        
        // verilator lint_off PINMISSING
        jelly2_data_ff_pack
                #(
                    .DATA0_WIDTH    (N),
                    .DATA1_WIDTH    (N),
                    .DATA2_WIDTH    (DATA_WIDTH),
                    .DATA3_WIDTH    (USER_WIDTH),
                    .S_REGS         (0),
                    .M_REGS         (M_REGS)
                )
            i_data_ff_pack_m
                (
                    .reset          (reset),
                    .clk            (clk),
                    .cke            (cke),
                    
                    .s_data0        (ff_m_first),
                    .s_data1        (ff_m_last),
                    .s_data2        (ff_m_data),
                    .s_data3        (ff_m_user),
                    .s_valid        (ff_m_valid),
                    .s_ready        (ff_m_ready),
                    
                    .m_data0        (m_first),
                    .m_data1        (m_last),
                    .m_data2        (m_data),
                    .m_data3        (m_user),
                    .m_valid        (m_valid),
                    .m_ready        (m_ready)
                );
        // verilator lint_on PINMISSING

        
        // auto first
        reg     [N-1:0]     reg_auto_first;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_auto_first <= {N{1'b1}};
            end
            else begin
                if ( ff_s_valid && ff_s_ready ) begin
                    reg_auto_first <= (ff_s_last & param_detect_last) & AUTO_FIRST;
                end
            end
        end
        
        // flag detect
        (* MARK_DEBUG="true" *) wire    [N-1:0]     sig_s_first = ({N{ff_s_valid}} & ff_s_first & param_detect_first) | reg_auto_first;
        (* MARK_DEBUG="true" *) wire    [N-1:0]     sig_s_last  = ({N{ff_s_valid}} & ff_s_last  & param_detect_last);
        
        (* MARK_DEBUG="true" *) wire    [N-1:0]     param_detect_first2 = (param_detect_first | (detect_last & AUTO_FIRST));
        
        
        // len count
        (* MARK_DEBUG="true" *) reg                     reg_busy;
        (* MARK_DEBUG="true" *) reg     [LEN_WIDTH-1:0] reg_len;
        (* MARK_DEBUG="true" *) reg                     reg_end;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_busy <= 1'b0;
                reg_len  <= {LEN_WIDTH{1'bx}};
                reg_end  <= 1'bx;
            end
            else if ( cke ) begin
                if ( ff_m_valid && ff_m_ready ) begin
                    if ( !reg_busy && (fifo_s_permit_len != (LEN_WIDTH'(1) - LEN_WIDTH'(LEN_OFFSET))) ) begin
                        // 2個以上の転送ならカウント
                        reg_busy <= 1'b1;
                        reg_len  <= fifo_s_permit_len;
                        reg_end  <= (fifo_s_permit_len == (LEN_WIDTH'(2) - LEN_WIDTH'(LEN_OFFSET)));
                    end
                    else begin
                        reg_len  <= reg_len - 1'b1;
                        reg_end  <= (reg_len == (LEN_WIDTH'(3) - LEN_WIDTH'(LEN_OFFSET)));
                        if ( reg_end ) begin
                            reg_busy <= 1'b0;
                            reg_len  <= {LEN_WIDTH{1'bx}};
                            reg_end  <= 1'bx;
                        end
                    end
                end
            end
        end
        
        (* MARK_DEBUG="true" *) wire    sig_start = !reg_busy;
        (* MARK_DEBUG="true" *) wire    sig_end   = (!reg_busy && (fifo_s_permit_len == (LEN_WIDTH'(1) - LEN_WIDTH'(LEN_OFFSET)))) || (reg_busy && reg_end);
        
        (* MARK_DEBUG="true" *) wire    sig_start_overflow  = DETECTOR_ENABLE && sig_start && |(param_detect_first2 &  fifo_s_permit_first & ~sig_s_first); // 期待するfirstが来ていない(データ余り)
        (* MARK_DEBUG="true" *) wire    sig_start_underflow = DETECTOR_ENABLE && sig_start && |(param_detect_first2 & ~fifo_s_permit_first & sig_s_first); // 期待するより先のfirstが来ている(データ不足)
        
        (* MARK_DEBUG="true" *) reg                     reg_underflow;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_underflow <= 1'b0;
            end
            else if ( cke ) begin
                if ( ff_m_valid && ff_m_ready ) begin
                    if ( !sig_end && (sig_s_last != 0) ) begin
                        reg_underflow <= 1'b1;    // 末尾以外で last が来た(データ不足)
                    end
                    if ( sig_start_underflow ) begin
                        reg_underflow <= 1'b1;
                    end
                    if ( sig_end ) begin
                        reg_underflow <= 1'b0;
                    end
                end
            end
        end
        
        (* MARK_DEBUG="true" *) wire    sig_skip    = sig_start_overflow;
        (* MARK_DEBUG="true" *) wire    sig_padding = padding_en && (sig_start_underflow || reg_underflow);
        
        
        assign fifo_s_permit_ready = (ff_m_valid && ff_m_ready && sig_end);
        
        assign ff_s_ready = (fifo_s_permit_valid && ((ff_m_ready && !sig_padding) || sig_skip)) || (!fifo_s_permit_valid && skip);
        
        assign ff_m_first = sig_start   ? fifo_s_permit_first : {N{1'b0}};
        assign ff_m_last  = sig_end     ? fifo_s_permit_last  : {N{1'b0}};
        assign ff_m_data  = sig_padding ? padding_data      : ff_s_data;
        assign ff_m_user  = fifo_s_permit_user;
        assign ff_m_valid = fifo_s_permit_valid && ((ff_s_valid && !sig_skip) || sig_padding);

        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_ff_s_first         ;
        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_ff_s_last          ;
        (* MARK_DEBUG="true" *) logic    [DATA_WIDTH-1:0]   dbg2_ff_s_data          ;
        (* MARK_DEBUG="true" *) logic                       dbg2_ff_s_valid         ;
        (* MARK_DEBUG="true" *) logic                       dbg2_ff_s_ready         ;

        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_ff_m_first          ;
        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_ff_m_last           ;
        (* MARK_DEBUG="true" *) logic    [DATA_WIDTH-1:0]   dbg2_ff_m_data           ;
        (* MARK_DEBUG="true" *) logic    [USER_BITS-1:0]    dbg2_ff_m_user           ;
        (* MARK_DEBUG="true" *) logic                       dbg2_ff_m_valid          ;
        (* MARK_DEBUG="true" *) logic                       dbg2_ff_m_ready          ;
        (* MARK_DEBUG="true" *) logic                       dbg2_sig_skip            ;
        (* MARK_DEBUG="true" *) logic                       dbg2_sig_padding         ;

        (* MARK_DEBUG="true" *) logic                       dbg2_skip               ;
        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_detect_first       ;
        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_detect_last        ;
        (* MARK_DEBUG="true" *) logic                       dbg2_padding_en         ;
        (* MARK_DEBUG="true" *) logic    [DATA_WIDTH-1:0]   dbg2_padding_data       ;
        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_sig_s_first        ;
        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_sig_s_last         ;
        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_param_detect_first2;
        (* MARK_DEBUG="true" *) logic    [N-1:0]            dbg2_param_detect_first ;
        
        ////
        (* MARK_DEBUG="true" *) logic                       dbg2_sig_start              ;
        (* MARK_DEBUG="true" *) logic                       dbg2_sig_end                ;
        (* MARK_DEBUG="true" *) logic                       dbg2_sig_start_overflow     ;
        (* MARK_DEBUG="true" *) logic                       dbg2_sig_start_underflow    ;
        (* MARK_DEBUG="true" *) logic                       dbg2_reg_underflow          ;

        (* MARK_DEBUG="true" *) logic                       dbg2_reg_busy               ;
        (* MARK_DEBUG="true" *) logic    [LEN_WIDTH-1:0]    dbg2_reg_len                ;
        (* MARK_DEBUG="true" *) logic                       dbg2_reg_end                ;

        (* MARK_DEBUG="true" *) logic  [N-1:0]              dbg2_s_first                ;
        (* MARK_DEBUG="true" *) logic  [N-1:0]              dbg2_s_last                 ;
        (* MARK_DEBUG="true" *) logic  [DATA_WIDTH-1:0]     dbg2_s_data                 ;
        (* MARK_DEBUG="true" *) logic                       dbg2_s_valid                ;
        (* MARK_DEBUG="true" *) logic                       dbg2_s_ready                ;
        (* MARK_DEBUG="true" *) logic [13:0]                dbg2_s_count                ;

        (* MARK_DEBUG="true" *) logic   [N-1:0]             dbg2_fifo_s_permit_first    ;
        (* MARK_DEBUG="true" *) logic   [N-1:0]             dbg2_fifo_s_permit_last     ;
        (* MARK_DEBUG="true" *) logic   [LEN_WIDTH-1:0]     dbg2_fifo_s_permit_len      ;
        (* MARK_DEBUG="true" *) logic   [USER_BITS-1:0]     dbg2_fifo_s_permit_user     ;
        (* MARK_DEBUG="true" *) logic                       dbg2_fifo_s_permit_valid    ;
        (* MARK_DEBUG="true" *) logic                       dbg2_fifo_s_permit_ready    ;

        always_ff @(posedge clk) begin
            dbg2_ff_s_first          <= ff_s_first          ;
            dbg2_ff_s_last           <= ff_s_last           ;
            dbg2_ff_s_data           <= ff_s_data           ;
            dbg2_ff_s_valid          <= ff_s_valid          ;
            dbg2_ff_s_ready          <= ff_s_ready          ;

            dbg2_ff_m_first          <= ff_m_first         ;
            dbg2_ff_m_last           <= ff_m_last          ;
            dbg2_ff_m_data           <= ff_m_data          ;
            dbg2_ff_m_user           <= ff_m_user          ;
            dbg2_ff_m_valid          <= ff_m_valid         ;
            dbg2_ff_m_ready          <= ff_m_ready         ;
            dbg2_sig_skip            <= sig_skip           ;
            dbg2_sig_padding         <= sig_padding        ;

            dbg2_skip                <= skip               ;
            dbg2_detect_first        <= detect_first       ;
            dbg2_detect_last         <= detect_last        ;
            dbg2_padding_en          <= padding_en         ;
            dbg2_padding_data        <= padding_data       ;
            dbg2_sig_s_first         <= sig_s_first        ;
            dbg2_sig_s_last          <= sig_s_last         ;
            dbg2_param_detect_first2 <= param_detect_first2;
            dbg2_param_detect_first  <= param_detect_first ;

            dbg2_s_first             <= s_first;
            dbg2_s_last              <= s_last ;
            dbg2_s_data              <= s_data ;
            dbg2_s_valid             <= s_valid;
            dbg2_s_ready             <= s_ready;
            dbg2_s_count             <= s_count;

            dbg2_sig_start           <= sig_start           ;
            dbg2_sig_end             <= sig_end             ;
            dbg2_sig_start_overflow  <= sig_start_overflow  ;
            dbg2_sig_start_underflow <= sig_start_underflow ;
            dbg2_reg_underflow       <= reg_underflow       ;
            dbg2_reg_busy            <= reg_busy            ;
            dbg2_reg_len             <= reg_len             ;
            dbg2_reg_end             <= reg_end             ;
            dbg2_s_first             <= s_first             ;
            dbg2_s_last              <= s_last              ;
            dbg2_s_data              <= s_data              ;
            dbg2_s_valid             <= s_valid             ;
            dbg2_s_ready             <= s_ready             ;
            dbg2_s_count             <= s_count             ;
            dbg2_fifo_s_permit_first <= fifo_s_permit_first ;
            dbg2_fifo_s_permit_last  <= fifo_s_permit_last  ;
            dbg2_fifo_s_permit_len   <= fifo_s_permit_len   ;
            dbg2_fifo_s_permit_user  <= fifo_s_permit_user  ;
            dbg2_fifo_s_permit_valid <= fifo_s_permit_valid ;
            dbg2_fifo_s_permit_ready <= fifo_s_permit_ready ;
        end
    end
    endgenerate
    
    
    
    // for simulation
    integer count_permit_len;
    always_ff @(posedge s_permit_clk) begin
        if ( s_permit_reset ) begin
            count_permit_len <= 0;
        end
        else begin
            if ( s_permit_valid & s_permit_ready ) begin
                count_permit_len <= count_permit_len + integer'(s_permit_len) + int'(LEN_OFFSET);
            end
        end
    end
    
    integer count_s;
    integer count_m;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            count_s <= 0;
            count_m <= 0;
        end
        else if ( cke ) begin
            count_s <= count_s + integer'(s_valid && s_ready);
            count_m <= count_m + integer'(m_valid && m_ready);
        end
    end
    
    
endmodule


`default_nettype wire


// end of file
