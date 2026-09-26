`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset   ,
            input   var logic   clk
        );

    // -----------------------------
    //  target
    // -----------------------------

    parameter   bit     RAND_BUSY      = 1                              ;

    localparam  int     DIVIDEND_BITS  = 8                              ;
    localparam  type    dividend_t     = logic [DIVIDEND_BITS-1:0]      ;
    localparam  int     DIVISOR_BITS   = 4                              ;
    localparam  type    divisor_t      = logic [DIVISOR_BITS-1:0]       ;
    localparam  int     QUOTIENT_BITS  = DIVIDEND_BITS                  ;
    localparam  type    quotient_t     = logic [QUOTIENT_BITS-1:0]      ;
    localparam  int     REMAINDER_BITS = DIVISOR_BITS                   ;
    localparam  type    remainder_t    = logic [REMAINDER_BITS-1:0]     ;

    // user で期待値を搬送
    localparam  int     USER_BITS      = QUOTIENT_BITS + REMAINDER_BITS ;
    localparam  type    user_t         = logic [USER_BITS-1:0]          ;

    logic       cke = 1'b1;
    always_ff @(posedge clk) begin
        cke <= RAND_BUSY ? 1'($urandom) : 1'b1;
    end

    logic       s_signed    ;
    user_t      s_user      ;
    dividend_t  s_dividend  ;
    divisor_t   s_divisor   ;
    logic       s_valid     ;
    logic       s_ready     ;

    user_t      m_user      ;
    quotient_t  m_quotient  ;
    remainder_t m_remainder ;
    logic       m_valid     ;
    logic       m_ready     ;

    jelly3_integer_divider
            #(
                .USER_BITS      (USER_BITS      ),
                .user_t         (user_t         ),
                .DIVIDEND_BITS  (DIVIDEND_BITS  ),
                .dividend_t     (dividend_t     ),
                .DIVISOR_BITS   (DIVISOR_BITS   ),
                .divisor_t      (divisor_t      ),
                .QUOTIENT_BITS  (QUOTIENT_BITS  ),
                .quotient_t     (quotient_t     ),
                .REMAINDER_BITS (REMAINDER_BITS ),
                .remainder_t    (remainder_t    )
            )
        u_integer_divider
            (
                .reset          ,
                .clk            ,
                .cke            ,

                .s_user         ,
                .s_signed       ,
                .s_dividend     ,
                .s_divisor      ,
                .s_valid        ,
                .s_ready        ,

                .m_user         ,
                .m_quotient     ,
                .m_remainder    ,
                .m_valid        ,
                .m_ready        
            );


    // -----------------------------
    //  stimulus
    // -----------------------------

    // {signed, divisor, dividend} の全組合せ (除数0はスキップ)
    localparam  type    count_t = logic [1 + DIVISOR_BITS + DIVIDEND_BITS - 1:0];
    localparam  int     TOTAL   = 2 * ((1 << DIVISOR_BITS) - 1) * (1 << DIVIDEND_BITS);

    count_t     count       ;
    count_t     next_count  ;
    logic       s_end       ;
    assign s_signed   = count[DIVIDEND_BITS + DIVISOR_BITS]  ;
    assign s_dividend = count[0             +: DIVIDEND_BITS];
    assign s_divisor  = count[DIVIDEND_BITS +: DIVISOR_BITS] ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            count   <= count_t'(1) << DIVIDEND_BITS;    // 除数1から開始
            s_valid <= 1'b0;
            s_end   <= 1'b0;
        end
        else if ( cke ) begin
            if ( !s_valid || s_ready ) begin
                s_valid <= !s_end && (RAND_BUSY ? 1'($urandom) : 1'b1);
            end
            if ( s_valid && s_ready ) begin
                if ( count == '1 ) begin
                    s_end   <= 1'b1;
                    s_valid <= 1'b0;
                end
                else begin
                    next_count = count + 1'b1;
                    if ( next_count[DIVIDEND_BITS +: DIVISOR_BITS] == '0 ) begin
                        next_count[DIVIDEND_BITS +: DIVISOR_BITS] = 'd1;    // 除数0はスキップ
                    end
                    count <= next_count;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        m_ready <= RAND_BUSY ? 1'($urandom) : 1'b1;
    end

    // 期待値
    int     exp_dividend, exp_divisor;
    always_comb begin
        if ( s_signed ) begin
            exp_dividend = int'(signed'(s_dividend));
            exp_divisor  = int'(signed'(s_divisor)) ;
        end
        else begin
            exp_dividend = int'({1'b0, s_dividend});
            exp_divisor  = int'({1'b0, s_divisor}) ;
        end
    end
    assign s_user = {quotient_t'(exp_dividend / exp_divisor), remainder_t'(exp_dividend % exp_divisor)};


    // -----------------------------
    //  checker
    // -----------------------------

    quotient_t  exp_quotient    ;
    remainder_t exp_remainder   ;
    assign {exp_quotient, exp_remainder} = m_user;

    int     ok_count = 0;
    always_ff @(posedge clk) begin
        if ( !reset && cke && m_valid && m_ready ) begin
            if ( m_quotient !== exp_quotient || m_remainder !== exp_remainder ) begin
                $error("error! q=%h (exp:%h) r=%h (exp:%h)", m_quotient, exp_quotient, m_remainder, exp_remainder);
            end
            else begin
                ok_count <= ok_count + 1;
                if ( ok_count + 1 >= TOTAL ) begin
                    $display("ALL-OK");
                    $finish();
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file
