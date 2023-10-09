
`default_nettype none

module clkgen_pll
        (
            input   var logic   clk_in,
            output  var logic   clk_out,
            output  var logic   lock
        );

    assign lock = 1'b1;

endmodule

`default_nettype wire


