
`default_nettype none

module clkgen_pll
        (
            input   var logic   clk_in,
            output  var logic   clk_out,
            output  var logic   lock
        );

    logic   clkoutp;
    logic   clkoutd;
    logic   clkoutd3;

    rPLL
            #(
                .FCLKIN             ("27"       ),
                .DYN_IDIV_SEL       ("false"    ),
                .IDIV_SEL           (2          ),
                .DYN_FBDIV_SEL      ("false"    ),
                .FBDIV_SEL          (13         ),
                .DYN_ODIV_SEL       ("false"    ),
                .ODIV_SEL           (4          ),
                .PSDA_SEL           ("0000"     ),
                .DYN_DA_EN          ("true"     ),
                .DUTYDA_SEL         ("1000"     ),
                .CLKOUT_FT_DIR      (1'b1       ),
                .CLKOUTP_FT_DIR     (1'b1       ),
                .CLKOUT_DLY_STEP    (0          ),
                .CLKOUTP_DLY_STEP   (0          ),
                .CLKFB_SEL          ("internal" ),
                .CLKOUT_BYPASS      ("false"    ),
                .CLKOUTP_BYPASS     ("false"    ),
                .CLKOUTD_BYPASS     ("false"    ),
                .DYN_SDIV_SEL       (2          ),
                .CLKOUTD_SRC        ("CLKOUT"   ),
                .CLKOUTD3_SRC       ("CLKOUT"   ),
                .DEVICE             ("GW1NR-9C" )
            )
        u_rPLL
            (
                .CLKOUT             (clk_out    ),
                .LOCK               (lock       ),
                .CLKOUTP            (clkoutp    ),
                .CLKOUTD            (clkoutd    ),
                .CLKOUTD3           (clkoutd3   ),
                .RESET              (1'b0       ),
                .RESET_P            (1'b0       ),
                .CLKIN              (clk_in     ),
                .CLKFB              (1'b0       ),
                .FBDSEL             (6'd0       ),
                .IDSEL              (6'd0       ),
                .ODSEL              (6'd0       ),
                .PSDA               (4'd0       ),
                .DUTYDA             (4'd0       ),
                .FDLY               (4'd0       )
            );

endmodule

`default_nettype wire


