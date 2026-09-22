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

    parameter   bit     RAND_BUSY         = 1                                       ;

    localparam  int     MULTIPLICAND_BITS = 8                                       ;
    localparam  type    multiplicand_t    = logic [MULTIPLICAND_BITS-1:0]           ;
    localparam  int     MULTIPLIER_BITS   = 4                                       ;
    localparam  type    multiplier_t      = logic [MULTIPLIER_BITS-1:0]             ;
    localparam  int     PRODUCT_BITS      = MULTIPLICAND_BITS + MULTIPLIER_BITS     ;
    localparam  type    product_t         = logic [PRODUCT_BITS-1:0]                ;

    // user で期待値を搬送
    localparam  int     USER_BITS         = PRODUCT_BITS                            ;
    localparam  type    user_t            = logic [USER_BITS-1:0]                   ;

    logic       cke = 1'b1;
    always_ff @(posedge clk) begin
        cke <= RAND_BUSY ? 1'($urandom) : 1'b1;
    end

    logic           s_signed        ;
    user_t          s_user          ;
    multiplicand_t  s_multiplicand  ;
    multiplier_t    s_multiplier    ;
    logic           s_valid         ;
    logic           s_ready         ;

    user_t          m_user          ;
    product_t       m_product       ;
    logic           m_valid         ;
    logic           m_ready         ;

    jelly3_integer_multiplier
            #(
                .USER_BITS          (USER_BITS          ),
                .user_t             (user_t             ),
                .MULTIPLICAND_BITS  (MULTIPLICAND_BITS  ),
                .multiplicand_t     (multiplicand_t     ),
                .MULTIPLIER_BITS    (MULTIPLIER_BITS    ),
                .multiplier_t       (multiplier_t       ),
                .PRODUCT_BITS       (PRODUCT_BITS       ),
                .product_t          (product_t          )
            )
        u_integer_multiplier
            (
                .reset          ,
                .clk            ,
                .cke            ,

                .s_user         ,
                .s_signed       ,
                .s_multiplicand ,
                .s_multiplier   ,
                .s_valid        ,
                .s_ready        ,

                .m_user         ,
                .m_product      ,
                .m_valid        ,
                .m_ready        
            );


    // -----------------------------
    //  stimulus
    // -----------------------------

    // {signed, multiplier, multiplicand} の全組合せ
    localparam  type    count_t = logic [1 + MULTIPLIER_BITS + MULTIPLICAND_BITS - 1:0];
    localparam  int     TOTAL   = 2 * (1 << MULTIPLIER_BITS) * (1 << MULTIPLICAND_BITS);

    count_t     count       ;
    logic       s_end       ;
    assign s_signed       = count[MULTIPLICAND_BITS + MULTIPLIER_BITS]      ;
    assign s_multiplicand = count[0                 +: MULTIPLICAND_BITS]   ;
    assign s_multiplier   = count[MULTIPLICAND_BITS +: MULTIPLIER_BITS]     ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            count   <= '0;
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
                    count <= count + 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        m_ready <= RAND_BUSY ? 1'($urandom) : 1'b1;
    end

    // 期待値
    int     exp_multiplicand, exp_multiplier;
    always_comb begin
        if ( s_signed ) begin
            exp_multiplicand = int'(signed'(s_multiplicand));
            exp_multiplier   = int'(signed'(s_multiplier))  ;
        end
        else begin
            exp_multiplicand = int'({1'b0, s_multiplicand});
            exp_multiplier   = int'({1'b0, s_multiplier})  ;
        end
    end
    assign s_user = product_t'(exp_multiplicand * exp_multiplier);


    // -----------------------------
    //  checker
    // -----------------------------

    product_t   exp_product;
    assign exp_product = m_user;

    int     ok_count = 0;
    always_ff @(posedge clk) begin
        if ( !reset && cke && m_valid && m_ready ) begin
            if ( m_product !== exp_product ) begin
                $error("error! p=%h (exp:%h)", m_product, exp_product);
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
