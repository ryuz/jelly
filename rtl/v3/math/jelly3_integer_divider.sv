
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 整数マルチサイクル除算器 (引き放し法)
// example
//  7 /  3 =  2,  7 %  3 =  1
//  7 / -3 = -2,  7 % -3 =  1
// -7 /  3 = -2, -7 %  3 = -1
// -7 / -3 =  2, -7 % -3 = -1
module jelly3_integer_divider
        #(
            parameter   int     USER_BITS      = 1                          ,
            parameter   type    user_t         = logic [USER_BITS-1:0]      ,
            parameter   int     DIVIDEND_BITS  = 32                         ,
            parameter   type    dividend_t     = logic [DIVIDEND_BITS-1:0]  ,
            parameter   int     DIVISOR_BITS   = 32                         ,
            parameter   type    divisor_t      = logic [DIVISOR_BITS-1:0]   ,
            parameter   int     QUOTIENT_BITS  = DIVIDEND_BITS              ,
            parameter   type    quotient_t     = logic [QUOTIENT_BITS-1:0]  ,
            parameter   int     REMAINDER_BITS = DIVISOR_BITS               ,
            parameter   type    remainder_t    = logic [REMAINDER_BITS-1:0] ,
            parameter           DEVICE         = "RTL"                      ,
            parameter           SIMULATION     = "false"                    ,
            parameter           DEBUG          = "false"                     
        )
        (
            input   var logic       reset       ,
            input   var logic       clk         ,
            input   var logic       cke         ,
            
            input   var user_t      s_user      ,
            input   var logic       s_signed    ,
            input   var dividend_t  s_dividend  ,
            input   var divisor_t   s_divisor   ,
            input   var logic       s_valid     ,
            output  var logic       s_ready     ,
            
            output  var user_t      m_user      ,
            output  var quotient_t  m_quotient  ,
            output  var remainder_t m_remainder ,
            output  var logic       m_valid     ,
            input   var logic       m_ready     
        );
    

    // ---------------------------------------------
    //  localparams
    // ---------------------------------------------

    localparam  int     CYCLES     = DIVIDEND_BITS                          ;
    localparam  int     CYCLE_BITS = $clog2(CYCLES) > 0 ? $clog2(CYCLES) : 1;
    localparam  type    cycle_t    = logic        [CYCLE_BITS-1:0]          ;
    localparam  int     ACC_BITS   = DIVISOR_BITS + 2                       ;
    localparam  type    acc_t      = logic signed [ACC_BITS-1:0]            ;


    // ---------------------------------------------
    //  input (符号付き時は絶対値化)
    // ---------------------------------------------

    logic       s_dividend_sign ;
    logic       s_divisor_sign  ;
    dividend_t  s_dividend_abs  ;
    divisor_t   s_divisor_abs   ;
    assign s_dividend_sign = s_signed && s_dividend[DIVIDEND_BITS-1];
    assign s_divisor_sign  = s_signed && s_divisor [DIVISOR_BITS-1] ;
    assign s_dividend_abs  = s_dividend_sign ? dividend_t'(-s_dividend) : s_dividend;
    assign s_divisor_abs   = s_divisor_sign  ? divisor_t'(-s_divisor)   : s_divisor ;


    // ---------------------------------------------
    //  core (符号なし引き放し法)
    // ---------------------------------------------

    logic       busy        ;   // 反復実行中
    logic       fix         ;   // 最終補正サイクル
    cycle_t     cycle       ;
    user_t      user        ;
    logic       quot_sign   ;
    logic       rem_sign    ;
    divisor_t   divisor     ;   // |除数|
    acc_t       acc         ;   // 部分剰余(符号付き)
    dividend_t  shiftreg    ;   // 被除数を吐き出しながら商を詰めるシフトレジスタ

    // 1bit分の反復 (加減算選択は XOR の LUT 1段 + キャリーチェーンに写像される形)
    logic       sub         ;
    acc_t       acc_sh      ;
    acc_t       acc_next    ;
    logic       q_bit       ;
    assign sub      = ~acc[ACC_BITS-1];     // 部分剰余が非負なら減算
    assign acc_sh   = acc_t'({acc[ACC_BITS-2:0], shiftreg[DIVIDEND_BITS-1]});
    assign acc_next = acc_sh + (acc_t'(divisor) ^ {ACC_BITS{sub}}) + acc_t'(sub);
    assign q_bit    = ~acc_next[ACC_BITS-1];

    // 最終補正 (負なら剰余復元、あわせて出力符号反転)
    logic       rem_neg     ;
    acc_t       rem_fix     ;
    quotient_t  quot_abs    ;
    assign rem_neg = acc[ACC_BITS-1];
    always_comb begin
        case ( {rem_sign, rem_neg} )
        2'b00:   rem_fix =  acc                  ;
        2'b01:   rem_fix =  acc + acc_t'(divisor);
        2'b10:   rem_fix = -acc                  ;
        default: rem_fix = -acc - acc_t'(divisor);
        endcase
    end
    assign quot_abs = quotient_t'(shiftreg);

    always_ff @(posedge clk) begin
        if ( reset ) begin
            busy        <= 1'b0;
            fix         <= 1'b0;
            cycle       <= 'x  ;
            user        <= 'x  ;
            quot_sign   <= 'x  ;
            rem_sign    <= 'x  ;
            divisor     <= 'x  ;
            acc         <= 'x  ;
            shiftreg    <= 'x  ;
            m_user      <= 'x  ;
            m_quotient  <= 'x  ;
            m_remainder <= 'x  ;
            m_valid     <= 1'b0;
        end
        else if ( cke && (!m_valid || m_ready) ) begin
            m_valid <= 1'b0;
            if ( busy ) begin
                acc      <= acc_next;
                shiftreg <= dividend_t'({shiftreg, q_bit});
                cycle    <= cycle - 1'b1;
                if ( cycle == '0 ) begin
                    busy <= 1'b0;
                    fix  <= 1'b1;
                end
            end
            else if ( fix ) begin
                m_user      <= user;
                m_quotient  <= quot_sign ? quotient_t'(-quot_abs) : quot_abs;
                m_remainder <= remainder_t'(rem_fix);
                m_valid     <= 1'b1;
                fix         <= 1'b0;
            end
            else if ( s_valid && s_ready ) begin
                user      <= s_user;
                quot_sign <= s_dividend_sign ^ s_divisor_sign;
                rem_sign  <= s_dividend_sign;
                divisor   <= s_divisor_abs;
                acc       <= '0;
                shiftreg  <= s_dividend_abs;
                cycle     <= cycle_t'(CYCLES - 1);
                busy      <= 1'b1;
            end
        end
    end

    assign s_ready = !busy && !fix && (!m_valid || m_ready);

endmodule



`default_nettype wire


// end of file
