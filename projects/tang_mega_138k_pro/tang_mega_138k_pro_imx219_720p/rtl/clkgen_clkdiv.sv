
`default_nettype none

module clkgen_clkdiv
        (
            input   var logic   reset_n,
            input   var logic   clk_in,
            output  var logic   clk_out
        );

    CLKDIV
            #(
                .DIV_MODE   ("5"    ),
                .GSREN      ("false")
            )
        u_CLKDIV
            (
                .CLKOUT     (clk_out),
                .HCLKIN     (clk_in),
                .RESETN     (reset_n),
                .CALIB      (1'b0)
            );

endmodule


`default_nettype wire


