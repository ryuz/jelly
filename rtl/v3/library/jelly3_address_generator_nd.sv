// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_address_generator_nd
        #(
            parameter   int     N          = 3,
            parameter   int     ADDR_BITS  = 32,
            parameter   type    addr_t     = logic [ADDR_BITS-1:0],
            parameter   int     STEP_BITS  = 32,
            parameter   type    step_t     = logic [STEP_BITS-1:0],
            parameter   int     LEN_BITS   = 32,
            parameter   type    len_t      = logic [LEN_BITS-1:0],
            parameter   bit     LEN_OFFSET = 1'b1,
            parameter   int     USER_BITS  = 1,
            parameter   type    user_t     = logic [USER_BITS-1:0],
            parameter   bit     S_REG      = 0
        )
        (
            input   var logic                       reset,
            input   var logic                       clk,
            input   var logic                       cke,
            
            input   var addr_t                      s_addr,
            input   var step_t  [N-1:0]             s_step,
            input   var len_t   [N-1:0]             s_len,
            input   var user_t                      s_user,
            input   var logic                       s_valid,
            output  var logic                       s_ready,
            
            output  var addr_t                      m_addr,
            output  var logic   [N-1:0]             m_first,
            output  var logic   [N-1:0]             m_last,
            output  var user_t                      m_user,
            output  var logic                       m_valid,
            input   var logic                       m_ready
        );
    
    
    // insert FF
    typedef struct packed {
        addr_t                      addr;
        step_t  [N-1:0]             step;
        len_t   [N-1:0]             len;
        user_t                      user;
    } cmd_t;
    
    addr_t                      ff_s_addr;
    step_t  [N-1:0]             ff_s_step;
    len_t   [N-1:0]             ff_s_len;
    user_t                      ff_s_user;
    logic                       ff_s_valid;
    logic                       ff_s_ready;
    
    jelly3_stream_ff
            #(
                .data_t     (cmd_t),
                .S_REG      (S_REG),
                .M_REG      (0)
            )
        u_stream_ff
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             ('{
                                        s_addr,
                                        s_step,
                                        s_len,
                                        s_user
                                    }),
                .s_valid            (s_valid),
                .s_ready            (s_ready),
                
                .m_data             ('{
                                        ff_s_addr,
                                        ff_s_step,
                                        ff_s_len,
                                        ff_s_user
                                    }),
                .m_valid            (ff_s_valid),
                .m_ready            (ff_s_ready)
            );
    
    
    // core
//    logic                             tmp_last;
    
    addr_t  [N-1:0]                   reg_addr,  next_addr;
    len_t   [N-1:0]                   reg_len,   next_len;
    logic   [N-1:0]                   reg_first, next_first;
    logic   [N-1:0]                   reg_last,  next_last;
    user_t                            reg_user,  next_user;
    logic                             reg_valid, next_valid;
    
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
            for ( int i = 0; i < N; i++ ) begin
                next_addr [i] = ff_s_addr;
                next_len  [i] = ff_s_len[i] - (len_t'(1) - len_t'(LEN_OFFSET));
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
                for ( int i = 0; i < N; i++ ) begin
                    next_first[i] = 1'b0;
                    if ( tmp_last ) begin
                        tmp_last = reg_last[i];
                        if ( tmp_last && i < N-1 ) begin
//                          next_addr [0] = reg_addr[i];
                            next_len  [i] = ff_s_len[i] - (len_t'(1) - len_t'(LEN_OFFSET));
                            next_first[i] = 1'b1;
                        end
                        else begin
//                          next_addr[i] = reg_addr[i] + ff_s_step[i];
                            next_len [i] = reg_len [i] - len_t'(1);
                        end
                    end
                end
                
                for ( int i = N-1; i >= 0; i-- ) begin
                    if ( i == 0 || reg_last[i-1] ) begin
                        next_addr[i] = reg_addr[i] + ff_s_step[i];
                    end
                end
                for ( int i = N-2; i >= 0; i-- ) begin
                    if ( reg_last[i] ) begin
                        next_addr[i] = next_addr[i+1];
                    end
                end
            end
        end
        
        // last フラグ
        tmp_last = 1'b1;
        for ( int i = 0; i < N; i++ ) begin
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