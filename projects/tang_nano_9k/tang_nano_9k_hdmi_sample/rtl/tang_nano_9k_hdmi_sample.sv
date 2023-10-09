
`default_nettype none

module tang_nano_9k_hdmi_sample
        (
            input   var logic           in_reset_n,
            input   var logic           in_clk,

            output  var logic           dvi_tx_clk_p,
            output  var logic           dvi_tx_clk_n,
            output  var logic   [2:0]   dvi_tx_data_p,
            output  var logic   [2:0]   dvi_tx_data_n,

            output  var logic   [4:0]   led_n
        );

    // PLL
    logic   clk_x5;
    logic   lock;
    clkgen_pll
        u_clkgen_pll
            (
                .clk_in     (in_clk         ),
                .clk_out    (clk_x5         ),
                .lock       (lock           )
            );

    // CLKDIV
    logic   clk;
    clkgen_clkdiv
        u_clkgen_clkdiv
            (
                .reset_n    (in_reset_n     ),
                .clk_in     (clk_x5         ),
                .clk_out    (clk            )
            );

    // reset sync
    logic   reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1),
                .OUT_LOW_ACTIVE     (0),
                .INPUT_REGS         (2)
            )
        u_reset
            (
                .clk                (clk                ),
                .in_reset           (in_reset_n & lock  ),   // asyncrnous reset
                .out_reset          (reset              )    // syncrnous reset
            );

    // DVI TX
    dvi_tx
        u_dvi_tx
            (
                .reset          (reset  ),
                .clk            (clk    ),
                .clk_x5         (clk_x5 ),

                .in_vsync       ('0),
                .in_hsync       ('0),
                .in_de          ('0),
                .in_data        ('0),
                .in_ctl         ('0),

                .out_clk_p      (dvi_tx_clk_p),
                .out_clk_n      (dvi_tx_clk_n),
                .out_data_p     (dvi_tx_data_p),
                .out_data_n     (dvi_tx_data_n)
            );
    

    // LED
    logic   [26:0]  counter;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    assign led_n = ~counter[26:22];

endmodule

`default_nettype wire
