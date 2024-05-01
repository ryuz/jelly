// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_address_generator_nd
        #(
            parameter   int     N          = 3,
            parameter   int     ADDR_WIDTH = 32,
            parameter   int     STEP_WIDTH = 32,
            parameter   int     LEN_WIDTH  = 32,
            parameter   bit     LEN_OFFSET = 1'b1,
            parameter   int     USER_WIDTH = 0,
            parameter   bit     S_REGS     = 0,
            
            // loacal
            localparam  int     USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire    [ADDR_WIDTH-1:0]        s_addr,
            input   wire    [N-1:0][STEP_WIDTH-1:0] s_step,
            input   wire    [N-1:0][LEN_WIDTH-1:0]  s_len,
            input   wire    [USER_BITS-1:0]         s_user,
            input   wire                            s_valid,
            output  wire                            s_ready,
            
            output  wire    [ADDR_WIDTH-1:0]        m_addr,
            output  wire    [N-1:0]                 m_first,
            output  wire    [N-1:0]                 m_last,
            output  wire    [USER_BITS-1:0]         m_user,
            output  wire                            m_valid,
            input   wire                            m_ready
        );
    
    
    // insert FF
    logic   [ADDR_WIDTH-1:0]        ff_s_addr;
    logic   [N-1:0][STEP_WIDTH-1:0] ff_s_step;
    logic   [N-1:0][LEN_WIDTH-1:0]  ff_s_len;
    logic   [USER_BITS-1:0]         ff_s_user;
    logic                           ff_s_valid;
    logic                           ff_s_ready;
    
    // verilator lint_off PINMISSING
    jelly2_data_ff_pack
            #(
                .DATA0_WIDTH    (ADDR_WIDTH),
                .DATA1_WIDTH    (N*STEP_WIDTH),
                .DATA2_WIDTH    (N*LEN_WIDTH),
                .DATA3_WIDTH    (USER_WIDTH),
                .S_REGS         (S_REGS),
                .M_REGS         (S_REGS)
            )
        i_data_ff_pack
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data0        (s_addr),
                .s_data1        (s_step),
                .s_data2        (s_len),
                .s_data3        (s_user),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_data0        (ff_s_addr),
                .m_data1        (ff_s_step),
                .m_data2        (ff_s_len),
                .m_data3        (ff_s_user),
                .m_valid        (ff_s_valid),
                .m_ready        (ff_s_ready)
            );
    // verilator lint_on PINMISSING
    
    
    // core
//    logic                             tmp_last;
    
    logic   [N-1:0][ADDR_WIDTH-1:0]     reg_addr,  next_addr;
    logic   [N-1:0][LEN_WIDTH-1:0]      reg_len,   next_len;
    logic   [N-1:0]                     reg_first, next_first;
    logic   [N-1:0]                     reg_last,  next_last;
    logic   [USER_BITS-1:0]             reg_user,  next_user;
    logic                               reg_valid, next_valid;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_addr  <= 'x;
            reg_len   <= 'x;
            reg_first <= 'x;
            reg_last  <= 'x;
            reg_user  <= 'x;
            reg_valid <= 1'b0;
        end
        else if ( cke ) begin
            reg_addr  <= next_addr;
            reg_len   <= next_len;
            reg_first <= next_first;
            reg_last  <= next_last;
            reg_user  <= next_user;
            reg_valid <= next_valid;
        end
    end
    
    always_comb begin
        automatic   logic   tmp_last;
        tmp_last   = 1'bx;

        next_addr  = reg_addr;
        next_len   = reg_len;
        next_first = reg_first;
        next_last  = reg_last;
        next_user  = reg_user;
        next_valid = reg_valid;
        
        // 開始
        if ( !m_valid && ff_s_valid ) begin
            for ( int i = 0; i < N; ++i ) begin
                next_addr [i] = ff_s_addr;
                next_len  [i] = ff_s_len[i] - (LEN_WIDTH'(1) - LEN_WIDTH'(LEN_OFFSET));
                next_first[i] = 1'b1;
                next_last [i] = 1'b0;
                next_user     = ff_s_user;
            end
            next_valid = 1'b1;
        end
        
        if ( m_valid && m_ready ) begin
            // 終了
            if ( m_last[N-1] ) begin
                next_valid = 1'b0;
            end
            else begin
                // 1つ前の次元がlastなら進める
                tmp_last = 1'b1;
                for ( int i = 0; i < N; ++i ) begin
                    next_first[i] = 1'b0;
                    if ( tmp_last ) begin
                        tmp_last = reg_last[i];
                        if ( tmp_last && i < N-1 ) begin
//                          next_addr [0] = reg_addr[i];
                            next_len  [i] = ff_s_len[i] - (LEN_WIDTH'(1) - LEN_WIDTH'(LEN_OFFSET));
                            next_first[i] = 1'b1;
                        end
                        else begin
//                          next_addr[i] = reg_addr[i] + ff_s_step[i];
                            next_len [i] = reg_len [i] - LEN_WIDTH'(1);
                        end
                    end
                end
                
                for ( int i = N-1; i >= 0; --i ) begin
                    if ( i == 0 || reg_last[i-1] ) begin
                        next_addr[i] = reg_addr[i] + ff_s_step[i];
                    end
                end
                for ( int i = N-2; i >= 0; --i ) begin
                    if ( reg_last[i] ) begin
                        next_addr[i] = next_addr[i+1];
                    end
                end
            end
        end
        
        // last フラグ
        tmp_last = 1'b1;
        for ( int i = 0; i < N; ++i ) begin
            tmp_last = tmp_last && (next_len[i] == 0);
            next_last[i] = tmp_last;
        end

        // idle
        if ( !next_valid ) begin
            next_addr   = 'x;
            next_len    = 'x;
            next_first  = 'x;
            next_last   = 'x;
            next_user   = 'x;
        end
    end
    
    assign ff_s_ready  = m_valid && m_ready && m_last[N-1];
    
    assign m_addr      = reg_addr[0];
    assign m_first     = reg_first;
    assign m_last      = reg_last;
    assign m_user      = reg_user;
    assign m_valid     = reg_valid;
    
endmodule


`default_nettype wire


// end of file
