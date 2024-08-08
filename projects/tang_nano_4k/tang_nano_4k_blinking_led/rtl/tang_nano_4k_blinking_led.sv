
`default_nettype none

module tang_nano_4k_blinking_led
        (
            input   var logic           in_reset_n,
            input   var logic           in_clk,

            output  var logic   [0:0]   led_n
        );
    
    logic   reset;
    logic   clk;
    assign reset = ~in_reset_n;
    assign clk   = in_clk;

    logic   [24:0]  counter;
    always_ff @(posedge clk or posedge reset) begin
        if ( reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    assign led_n = ~counter[24];

endmodule


`default_nettype wire
