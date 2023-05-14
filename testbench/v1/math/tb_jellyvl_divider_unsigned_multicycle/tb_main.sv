
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire        reset,
            input   wire        clk
        );

    logic   cke;
    always_ff @(posedge clk) cke <= 1'({$random()});

    
    localparam DIVIDEND_WIDTH = 32;
    localparam DIVISOR_WIDTH  = 16;
//    localparam QUOTIENT_WIDTH  = 18;
    localparam QUOTIENT_WIDTH  = DIVIDEND_WIDTH;
    localparam REMAINDER_WIDTH = DIVISOR_WIDTH;

    logic   [DIVIDEND_WIDTH-1:0]    s_dividend;
    logic   [DIVISOR_WIDTH-1:0]     s_divisor;
    logic                           s_valid = 1'b1;
    logic                           s_ready;

    logic   [QUOTIENT_WIDTH-1:0]    m_quotient;
    logic   [REMAINDER_WIDTH-1:0]   m_remainder;
    logic                           m_valid;
    logic                           m_ready = 1'b1;

    jellyvl_divider_unsigned_multicycle
            #(
                .DIVIDEND_WIDTH     (DIVIDEND_WIDTH),
                .DIVISOR_WIDTH      (DIVISOR_WIDTH),
                .QUOTIENT_WIDTH     (QUOTIENT_WIDTH),
                .REMAINDER_WIDTH    (REMAINDER_WIDTH)
            )
        i_divider_unsigned_multicycle
            (
                .reset,
                .clk,
                .cke,

                .s_dividend         (s_dividend),
                .s_divisor          (s_divisor),
                .s_valid            (s_valid),
                .s_ready            (s_ready),

                .m_quotient         (m_quotient),
                .m_remainder        (m_remainder),
                .m_valid            (m_valid),
                .m_ready            (m_ready)
            );

    always_ff @(posedge clk) begin
        if ( reset ) begin
            s_valid <= 1'b0;
            s_dividend <= 'x;
            s_divisor  <= 'x;
        end
        else if ( cke ) begin
//            s_dividend <= DIVIDEND_WIDTH'({$random()});
            s_dividend <= QUOTIENT_WIDTH'({$random()});
            s_divisor  <= DIVISOR_WIDTH'({$random()});
            s_valid    <= 1'b1;

            if ( s_valid && s_ready ) begin
                $display("%d / %d", s_dividend, s_divisor);
                $display("exp   : %10d  %10d", 32'(s_dividend) / 32'(s_divisor), 32'(s_dividend)%32'(s_divisor));
            end
            if ( m_valid && m_ready ) begin
                $display("result: %10d  %10d", 32'(m_quotient), 32'(m_remainder));
            end
        end
    end


endmodule


`default_nettype wire


// end of file
