// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 整数マルチサイクル乗算器 (シフト加算)
module jelly3_integer_multiplier
        #(
            parameter   int     USER_BITS         = 1                                   ,
            parameter   type    user_t            = logic [USER_BITS-1:0]               ,
            parameter   int     MULTIPLICAND_BITS = 32                                  ,
            parameter   type    multiplicand_t    = logic [MULTIPLICAND_BITS-1:0]       ,
            parameter   int     MULTIPLIER_BITS   = 32                                  ,
            parameter   type    multiplier_t      = logic [MULTIPLIER_BITS-1:0]         ,
            parameter   int     PRODUCT_BITS      = MULTIPLICAND_BITS + MULTIPLIER_BITS ,
            parameter   type    product_t         = logic [PRODUCT_BITS-1:0]            ,
            parameter           DEVICE            = "RTL"                               ,
            parameter           SIMULATION        = "false"                             ,
            parameter           DEBUG             = "false"                              
        )
        (
            input   var logic           reset           ,
            input   var logic           clk             ,
            input   var logic           cke             ,
            
            input   var user_t          s_user          ,
            input   var logic           s_signed        ,
            input   var multiplicand_t  s_multiplicand  ,
            input   var multiplier_t    s_multiplier    ,
            input   var logic           s_valid         ,
            output  var logic           s_ready         ,
            
            output  var user_t          m_user          ,
            output  var product_t       m_product       ,
            output  var logic           m_valid         ,
            input   var logic           m_ready         
        );
    

    // ---------------------------------------------
    //  localparams
    // ---------------------------------------------

    localparam  int     CYCLES     = MULTIPLIER_BITS                        ;
    localparam  int     CYCLE_BITS = $clog2(CYCLES) > 0 ? $clog2(CYCLES) : 1;
    localparam  type    cycle_t    = logic [CYCLE_BITS-1:0]                 ;
    localparam  int     FULL_BITS  = MULTIPLICAND_BITS + MULTIPLIER_BITS    ;
    localparam  type    full_t     = logic [FULL_BITS-1:0]                  ;
    localparam  type    sum_t      = logic [MULTIPLICAND_BITS:0]            ;


    // ---------------------------------------------
    //  input (符号付き時は絶対値化)
    // ---------------------------------------------

    logic           s_multiplicand_sign ;
    logic           s_multiplier_sign   ;
    multiplicand_t  s_multiplicand_abs  ;
    multiplier_t    s_multiplier_abs    ;
    assign s_multiplicand_sign = s_signed && s_multiplicand[MULTIPLICAND_BITS-1];
    assign s_multiplier_sign   = s_signed && s_multiplier  [MULTIPLIER_BITS-1]  ;
    assign s_multiplicand_abs  = s_multiplicand_sign ? multiplicand_t'(-s_multiplicand) : s_multiplicand;
    assign s_multiplier_abs    = s_multiplier_sign   ? multiplier_t'(-s_multiplier)     : s_multiplier  ;


    // ---------------------------------------------
    //  core (符号なしシフト加算)
    // ---------------------------------------------

    logic           busy        ;   // 反復実行中
    logic           fix         ;   // 最終補正サイクル
    cycle_t         cycle       ;
    user_t          user        ;
    logic           prod_sign   ;
    multiplicand_t  multiplicand;   // |被乗数|
    full_t          shiftreg    ;   // 乗数を吐き出しながら積を詰めるシフトレジスタ

    // 1bit分の反復 (加算対象選択は AND の LUT 1段 + キャリーチェーンに写像される形)
    multiplicand_t              addend          ;
    sum_t                       sum             ;
    logic   [FULL_BITS:0]       shift_tmp       ;
    full_t                      shiftreg_next   ;
    assign addend        = multiplicand & {MULTIPLICAND_BITS{shiftreg[0]}};
    assign sum           = sum_t'(shiftreg[FULL_BITS-1 -: MULTIPLICAND_BITS]) + sum_t'(addend);
    assign shift_tmp     = {sum, shiftreg[MULTIPLIER_BITS-1:0]};
    assign shiftreg_next = full_t'(shift_tmp >> 1);

    // 最終補正 (符号反転)
    product_t   prod_abs;
    assign prod_abs = product_t'(shiftreg);

    always_ff @(posedge clk) begin
        if ( reset ) begin
            busy         <= 1'b0;
            fix          <= 1'b0;
            cycle        <= 'x  ;
            user         <= 'x  ;
            prod_sign    <= 'x  ;
            multiplicand <= 'x  ;
            shiftreg     <= 'x  ;
            m_user       <= 'x  ;
            m_product    <= 'x  ;
            m_valid      <= 1'b0;
        end
        else if ( cke && (!m_valid || m_ready) ) begin
            m_valid <= 1'b0;
            if ( busy ) begin
                shiftreg <= shiftreg_next;
                cycle    <= cycle - 1'b1;
                if ( cycle == '0 ) begin
                    busy <= 1'b0;
                    fix  <= 1'b1;
                end
            end
            else if ( fix ) begin
                m_user    <= user;
                m_product <= prod_sign ? product_t'(-prod_abs) : prod_abs;
                m_valid   <= 1'b1;
                fix       <= 1'b0;
            end
            else if ( s_valid && s_ready ) begin
                user         <= s_user;
                prod_sign    <= s_multiplicand_sign ^ s_multiplier_sign;
                multiplicand <= s_multiplicand_abs;
                shiftreg     <= full_t'(s_multiplier_abs);
                cycle        <= cycle_t'(CYCLES - 1);
                busy         <= 1'b1;
            end
        end
    end

    assign s_ready = !busy && !fix && (!m_valid || m_ready);

endmodule



`default_nettype wire


// end of file
