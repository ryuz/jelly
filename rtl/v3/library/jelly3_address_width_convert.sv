// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 幅変換時のアドレスサイズ変換
module jelly3_address_width_convert
        #(
            parameter   bit     ALLOW_UNALIGNED = 1,     // UNALIGNEDあり
            parameter   int     ADDR_BITS       = 32,    // アドレスのbit幅
            parameter   type    addr_t          = logic [ADDR_BITS-1:0],
            parameter   int     USER_BITS       = 1,     // ユーザーデータのbit幅
            parameter   type    user_t          = logic [USER_BITS-1:0],
            parameter   int     S_UNIT          = 4,     // 入力データ幅のアドレス増加量
            parameter   int     M_UNIT_SIZE     = 2,     // 出力データ幅でのアドレス増加量のlog2 (0:1byte, 1:2byte, 2:4byte, ...)
            parameter   int     S_LEN_BITS      = 32,    // 入力側データ幅の点層サイズ
            parameter   type    s_len_t         = logic [S_LEN_BITS-1:0],
            parameter   int     M_LEN_BITS      = 32,    // 入力側データ幅の点層サイズ
            parameter   type    m_len_t         = logic [M_LEN_BITS-1:0],
            parameter   int     ALIGN_BITS      = M_UNIT_SIZE > 0 ? M_UNIT_SIZE : 1,
            parameter   type    align_t         = logic [ALIGN_BITS-1:0],
            parameter   bit     S_LEN_OFFSET    = 1'b1,
            parameter   bit     M_LEN_OFFSET    = 1'b1,
            parameter   bit     S_REG           = 0
        )
        (
            input   var logic                   reset,
            input   var logic                   clk,
            input   var logic                   cke,
            
            input   var addr_t                  s_addr,
            input   var s_len_t                 s_len,
            input   var user_t                  s_user,
            input   var logic                   s_valid,
            output  var logic                   s_ready,
            
            output  var addr_t                  m_addr,
            output  var align_t                 m_align,
            output  var m_len_t                 m_len,
            output  var user_t                  m_user,
            output  var logic                   m_valid,
            input   var logic                   m_ready
        );
    
    // inster FF
    typedef struct packed {
        addr_t      addr;
        s_len_t     len;
        user_t      user;
    } cmd_t;
    
    addr_t                      ff_s_addr;
    s_len_t                     ff_s_len;
    user_t                      ff_s_user;
    logic                       ff_s_valid;
    logic                       ff_s_ready;

    jelly3_stream_ff
            #(
                .data_t     (cmd_t),
                .S_REG      (S_REG),
                .M_REG      ((S_UNIT & (S_UNIT-1)) != 0)    // 2のべき乗でなければFF挿入
            )
        u_stream_ff
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             ('{
                                        s_addr,
                                        s_len,
                                        s_user
                                    }),
                .s_valid            (s_valid),
                .s_ready            (s_ready),
                
                .m_data             ('{
                                        ff_s_addr,
                                        ff_s_len,
                                        ff_s_user
                                    }),
                .m_valid            (ff_s_valid),
                .m_ready            (ff_s_ready)
            );
    
    
    // core
    addr_t                      add_mask;
    align_t                     align;
    assign add_mask = ((1 << M_UNIT_SIZE) - 1);
    assign align    = ALLOW_UNALIGNED ? align_t'(ff_s_addr & add_mask) : {ALIGN_BITS{1'b0}};
    
    addr_t                      reg_addr;
    align_t                     reg_align;
    m_len_t                     reg_len;
    user_t                      reg_user;
    logic                       reg_valid;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_addr  <= {ADDR_BITS{1'bx}};
            reg_align <= {ALIGN_BITS{1'bx}};
            reg_len   <= {M_LEN_BITS{1'bx}};
            reg_user  <= {USER_BITS{1'bx}};
            reg_valid <= 1'b0;
        end
        else if ( cke ) begin
            if ( ff_s_ready ) begin
                reg_addr  <= (ff_s_addr & ~add_mask);
                reg_align <= align;
                reg_len   <= ((m_len_t'(align) + ((m_len_t'(ff_s_len) + m_len_t'(S_LEN_OFFSET)) * m_len_t'(S_UNIT)) + ((1 << M_UNIT_SIZE) - 1)) >> M_UNIT_SIZE) - m_len_t'(M_LEN_OFFSET);
                reg_user  <= ff_s_user;
                reg_valid <= ff_s_valid;
            end
        end
    end
    
    assign ff_s_ready  = ~m_valid || m_ready;
    
    assign m_addr      = reg_addr;
    assign m_align     = reg_align;
    assign m_len       = reg_len;
    assign m_user      = reg_user;
    assign m_valid     = reg_valid;
    
    
endmodule


`default_nettype wire


// end of file