// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_data_packing
        #(
            parameter UNIT_WIDTH       = 8,
            parameter S_NUM            = 3,
            parameter M_NUM            = 4,
            parameter FIRST_FORCE_LAST = 1,  // firstで前方吐き出し時に残変換があれば強制的にlastを付与
            parameter FIRST_OVERWRITE  = 0,  // first時前方に残変換があれば吐き出さずに上書き
            parameter S_REGS           = (S_NUM != M_NUM),
            
            // local
            parameter S_DATA_WIDTH     = S_NUM*UNIT_WIDTH,
            parameter M_DATA_WIDTH     = M_NUM*UNIT_WIDTH
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        endian,
            input   wire    [M_DATA_WIDTH-1:0]  padding_data,
            
            input   wire                        s_first,
            input   wire                        s_last,
            input   wire    [S_DATA_WIDTH-1:0]  s_data,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire                        m_first,
            output  wire                        m_last,
            output  wire    [M_DATA_WIDTH-1:0]  m_data,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
    
    
    // -----------------------------------------
    //  localparam
    // -----------------------------------------
    
    localparam  BUF_NUM     = S_NUM + M_NUM - 1;
    localparam  BUF_WIDTH   = BUF_NUM * UNIT_WIDTH;
    localparam  COUNT_WIDTH = BUF_NUM <     2 ?  1 :
                              BUF_NUM <     4 ?  2 :
                              BUF_NUM <     8 ?  3 :
                              BUF_NUM <    16 ?  4 :
                              BUF_NUM <    32 ?  5 :
                              BUF_NUM <    64 ?  6 :
                              BUF_NUM <   128 ?  7 :
                              BUF_NUM <   256 ?  8 :
                              BUF_NUM <   512 ?  9 :
                              BUF_NUM <  1024 ? 10 :
                              BUF_NUM <  2048 ? 11 :
                              BUF_NUM <  4096 ? 12 :
                              BUF_NUM <  8192 ? 13 :
                              BUF_NUM < 16384 ? 14 :
                              BUF_NUM < 32768 ? 15 : 16;
    
    
    // -----------------------------------------
    //  insert FF
    // -----------------------------------------
    
    wire                            ff_s_first;
    wire                            ff_s_last;
    wire    [S_DATA_WIDTH-1:0]      ff_s_data;
    wire                            ff_s_valid;
    wire                            ff_s_ready;
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH     (1 + 1 + S_DATA_WIDTH),
                .SLAVE_REGS     (S_REGS),
                .MASTER_REGS    (S_REGS)
            )
        i_pipeline_insert_ff_s
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data         ({s_last, s_first, s_data}),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_data         ({ff_s_last, ff_s_first, ff_s_data}),
                .m_valid        (ff_s_valid),
                .m_ready        (ff_s_ready),
                
                .buffered       (),
                .s_ready_next   ()
            );
    
    
    // -----------------------------------------
    //  convert
    // -----------------------------------------
    
    generate
    if ( S_DATA_WIDTH != M_DATA_WIDTH ) begin : blk_packing
        
        integer                     i;
        
        reg     [COUNT_WIDTH-1:0]   reg_count, next_count;
        reg     [BUF_WIDTH-1:0]     reg_buf,   next_buf;
        reg                         reg_final, next_final;
        reg                         reg_lflag, next_lflag;
        
        reg                         sig_ready;
        
        reg                         reg_first, next_first;
        reg                         reg_last,  next_last;
        reg     [M_DATA_WIDTH-1:0]  sig_data;
        reg                         reg_valid, next_valid;
        
        always @(posedge clk) begin
            if ( reset ) begin
                reg_count <= 0;
                reg_buf   <= {BUF_WIDTH{1'bx}};
                reg_final <= 1'b0;
                reg_lflag <= 1'b0;
                reg_first <= 1'b0;
                reg_last  <= 1'b0;
                reg_valid <= 1'b0;
            end
            else if ( cke ) begin
                reg_count <= next_count;
                reg_buf   <= next_buf;
                reg_final <= next_final;
                reg_lflag <= next_lflag;
                reg_first <= next_first;
                reg_last  <= next_last;
                reg_valid <= next_valid;
            end
        end
        
        always @* begin
            next_count = reg_count;
            next_buf   = reg_buf;
            next_final = reg_final;
            next_lflag = reg_lflag;
            next_first = reg_first;
            next_last  = reg_last;
            next_valid = reg_valid;
            
            // 出力完了処理
            if ( m_ready ) begin
                next_valid = 1'b0;
                
                if ( m_valid  ) begin
                    // 出力実施の場合
                    next_first = 1'b0;
                    if ( reg_last ) begin
                        // 最後なら初期化
                        next_final = 1'b0;
                        next_lflag = 1'b0;
                        next_buf   = {BUF_WIDTH{1'bx}};
                        next_count = 0;
                    end
                    else begin
                        // データシフト
                        if ( endian ) begin
                            next_buf = {next_buf, {M_DATA_WIDTH{1'bx}}};                    // big endian
                        end
                        else begin
                            next_buf = {{M_DATA_WIDTH{1'bx}}, next_buf} >> M_DATA_WIDTH;    // little endian
                        end
                        next_count = next_count - M_NUM;
                    end
                end
            end
            
            
            // 入力データ受付可否
            if ( FIRST_OVERWRITE ) begin
                // first 時は残があっても受け入れ(上書き)
                sig_ready = (!next_final && (BUF_NUM - next_count >= S_NUM) || ((!m_valid || m_ready) && ff_s_valid && ff_s_first));
            end
            else begin
                // first 時は残があれば吐き出し待ち
                if ( ff_s_valid && ff_s_first && next_count > 0 ) begin
                    next_final = 1'b1;
                    next_lflag = FIRST_FORCE_LAST;
                end
                sig_ready = (!next_final && (BUF_NUM - next_count >= S_NUM));
            end
            
            // 入力受付
            if ( ff_s_valid && sig_ready ) begin
                if ( ff_s_first ) begin
                    // 初期化
                    next_count = 0;
                    next_first = 1'b1;
                    next_buf   = {BUF_WIDTH{1'bx}};
                end
                if ( ff_s_last ) begin
                    next_final = 1'b1;
                    next_lflag = 1'b1;
                end
                
                // データ格納
                if ( endian ) begin
                    next_buf[(BUF_WIDTH-1) - (next_count*UNIT_WIDTH) -: S_DATA_WIDTH] = ff_s_data;  // big endian
                end
                else begin
                    next_buf[next_count*UNIT_WIDTH +: S_DATA_WIDTH] = ff_s_data;                    // little endian
                end
                next_count = next_count + S_NUM;
            end
            
            // 残部分をパディング
            for ( i = 0; i < M_DATA_WIDTH; i = i+1 ) begin
                if ( i >= next_count*UNIT_WIDTH ) begin
                    if ( endian ) begin
                        next_buf[BUF_WIDTH-1 - i] = padding_data[M_DATA_WIDTH-1 - i];
                    end
                    else begin
                        next_buf[i] = padding_data[i];
                    end
                end
            end
            
            // 出力判定
            if ( next_count >= M_NUM || next_final ) begin
                next_last  = (next_count <= M_NUM) && next_final;
                next_valid = 1'b1;
            end
        end
        
        assign ff_s_ready = sig_ready;
        assign m_first    = reg_first;
        assign m_last     = reg_last & reg_lflag;
        assign m_data     = endian ? reg_buf[BUF_WIDTH-1 -: M_DATA_WIDTH] : reg_buf[0 +: M_DATA_WIDTH];
        assign m_valid    = reg_valid;
    end
    else begin : blk_bypass
        assign ff_s_ready = m_ready;
        assign m_first    = ff_s_first;
        assign m_last     = ff_s_last;
        assign m_data     = ff_s_data;
        assign m_valid    = ff_s_valid;
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
