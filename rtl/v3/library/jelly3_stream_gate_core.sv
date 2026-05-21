// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 許可した分だけデータを通すゲート(コア)
// FIFOやFFなどのバッファを持たない純粋な同期回路
// BYPASS/BYPASS_COMBINE はラッパー (jelly3_stream_gate) 側で処理する
// first や last は 上位次元でbitが立っているとき下位次元は必ず立っているとみなす
module jelly3_stream_gate_core
        #(
            parameter   int             N               = 1         ,   // 次元数(dimension)
            parameter   bit             DETECTOR_ENABLE = 0         ,   // フラグ検出器(読み飛ばし/パディング)を使うか
            parameter   bit [N-1:0]     AUTO_FIRST      = {N{1'b1}} ,   // lastの後を自動的にfirst扱いにする

            parameter   int             DATA_BITS       = 32        ,
            parameter   type            data_t          = logic [DATA_BITS-1:0],
            parameter   int             LEN_BITS        = 32        ,
            parameter   type            len_t           = logic [LEN_BITS-1:0],
            parameter   bit             LEN_OFFSET      = 1'b1      ,
            parameter   int             USER_BITS       = 1         ,
            parameter   type            user_t          = logic [USER_BITS-1:0]
        )
        (
            input   var logic           reset       ,
            input   var logic           clk         ,
            input   var logic           cke         ,

            input   var logic           skip        ,   // 非busy時に読み飛ばす
            input   var logic [N-1:0]   detect_first,
            input   var logic [N-1:0]   detect_last ,
            input   var logic           padding_en  ,
            input   var data_t          padding_data,

            // stream slave
            input   var logic [N-1:0]   s_first     ,
            input   var logic [N-1:0]   s_last      ,
            input   var data_t          s_data      ,
            input   var logic           s_valid     ,
            output  var logic           s_ready     ,

            // stream master
            output  var logic [N-1:0]   m_first     ,
            output  var logic [N-1:0]   m_last      ,
            output  var data_t          m_data      ,
            output  var user_t          m_user      ,
            output  var logic           m_valid     ,
            input   var logic           m_ready     ,

            // permit slave (clkに同期済みであること)
            input   var logic [N-1:0]   s_permit_first,
            input   var logic [N-1:0]   s_permit_last ,
            input   var len_t           s_permit_len  ,
            input   var user_t          s_permit_user ,
            input   var logic           s_permit_valid,
            output  var logic           s_permit_ready
        );

    // -----------------------------------------------------------------
    //  Gate logic
    // -----------------------------------------------------------------

    // DETECTOR_ENABLE=0 の場合は first/last 検出を無効化
    logic [N-1:0] param_detect_first ;
    logic [N-1:0] param_detect_last  ;
    logic [N-1:0] param_detect_first2;
    assign param_detect_first  = DETECTOR_ENABLE ? detect_first : {N{1'b0}};
    assign param_detect_last   = DETECTOR_ENABLE ? detect_last  : {N{1'b0}};
    assign param_detect_first2 = param_detect_first | (detect_last & AUTO_FIRST);


    // ---- auto first ----
    // s_last が来た次のビートを自動的に first 扱いにする
    logic [N-1:0]   reg_auto_first;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_auto_first <= {N{1'b1}};
        end
        else begin
            if ( s_valid && s_ready ) begin
                reg_auto_first <= (s_last & param_detect_last) & AUTO_FIRST;
            end
        end
    end

    // 入力ストリームの first/last の実効値
    logic [N-1:0] sig_s_first;
    logic [N-1:0] sig_s_last ;
    assign sig_s_first = ({N{s_valid}} & s_first & param_detect_first) | reg_auto_first;
    assign sig_s_last  =  {N{s_valid}} & s_last  & param_detect_last;


    // ---- 転送許可カウンタ ----
    logic       reg_busy;
    len_t       reg_len ;
    logic       reg_end ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_busy <= 1'b0;
            reg_len  <= 'x;
            reg_end  <= 'x;
        end
        else if ( cke ) begin
            if ( m_valid && m_ready ) begin
                if ( !reg_busy && (s_permit_len != (LEN_BITS'(1) - LEN_BITS'(LEN_OFFSET))) ) begin
                    // 2個以上の転送ならカウント開始
                    reg_busy <= 1'b1;
                    reg_len  <= s_permit_len;
                    reg_end  <= (s_permit_len == (LEN_BITS'(2) - LEN_BITS'(LEN_OFFSET)));
                end
                else begin
                    reg_len  <= reg_len - 1'b1;
                    reg_end  <= (reg_len == (LEN_BITS'(3) - LEN_BITS'(LEN_OFFSET)));
                    if ( reg_end ) begin
                        reg_busy <= 1'b0;
                        reg_len  <= 'x;
                        reg_end  <= 'x;
                    end
                end
            end
        end
    end

    logic sig_start;
    logic sig_end  ;
    assign sig_start = !reg_busy;
    assign sig_end   = (!reg_busy && (s_permit_len == (LEN_BITS'(1) - LEN_BITS'(LEN_OFFSET))))
                     || (reg_busy && reg_end);


    // ---- overflow / underflow 検出 (DETECTOR_ENABLE=1 時のみ有効) ----
    logic sig_start_overflow ;
    logic sig_start_underflow;
    assign sig_start_overflow  = DETECTOR_ENABLE && sig_start
                               && |(param_detect_first2 &  s_permit_first & ~sig_s_first); // 期待するfirstが来ていない(データ余り)
    assign sig_start_underflow = DETECTOR_ENABLE && sig_start
                               && |(param_detect_first2 & ~s_permit_first &  sig_s_first); // 期待するより先のfirstが来ている(データ不足)

    logic   reg_underflow;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_underflow <= 1'b0;
        end
        else if ( cke ) begin
            if ( m_valid && m_ready ) begin
                if ( !sig_end && (sig_s_last != '0) ) begin
                    reg_underflow <= 1'b1;  // 末尾以外で last が来た(データ不足)
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

    logic   sig_skip   ;
    logic   sig_padding;
    assign sig_skip    = sig_start_overflow;
    assign sig_padding = padding_en && (sig_start_underflow || reg_underflow);


    // ---- permit 消費 ----
    assign s_permit_ready = m_valid && m_ready && sig_end;

    // ---- 入力ストリーム消費 ----
    assign s_ready = (s_permit_valid && ((m_ready && !sig_padding) || sig_skip))
                   || (!s_permit_valid && skip);

    // ---- 出力ストリーム生成 ----
    assign m_first = sig_start   ? s_permit_first : {N{1'b0}};
    assign m_last  = sig_end     ? s_permit_last  : {N{1'b0}};
    assign m_data  = sig_padding ? padding_data   : s_data    ;
    assign m_user  = s_permit_user;
    assign m_valid = s_permit_valid && ((s_valid && !sig_skip) || sig_padding);


    // -----------------------------------------------------------------
    //  simulation counters
    // -----------------------------------------------------------------

    // verilator lint_off UNUSEDSIGNAL
    int count_s;
    int count_m;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            count_s <= 0;
            count_m <= 0;
        end
        else if ( cke ) begin
            count_s <= count_s + int'(s_valid && s_ready);
            count_m <= count_m + int'(m_valid && m_ready);
        end
    end
    // verilator lint_on UNUSEDSIGNAL


endmodule


`default_nettype wire


// end of file
