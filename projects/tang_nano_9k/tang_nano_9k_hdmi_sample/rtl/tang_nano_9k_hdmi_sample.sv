
`default_nettype none

module tang_nano_9k_hdmi_sample
        (
            input   var logic           reset_n,
            input   var logic           clk,

            output  var logic   [4:0]   led_n
        );

    logic   clk2;
    logic   lock;
    clkgen_pll
        u_clkgen_pll
            (
                .clk_in     (clk),
                .clk_out    (clk2),
                .lock       (lock)
            );

    logic   clkoutp;
    logic   clkoutd;
    logic   clkoutd3;


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
                .clk                (clk),
                .in_reset           (reset_n & lock),   // asyncrnous reset
                .out_reset          (reset)             // syncrnous reset
            );
    

    logic   [26:0]  counter;
    always_ff @(posedge clk2) begin
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
