
`default_nettype none

module tang_nano_9k_blink_led
        (
            input   var logic           reset_n,
            input   var logic           clk,

            output  var logic   [4:0]   led_n
        );

    logic   [26:0]  counter;
    always_ff @(posedge clk or negedge reset_n) begin
        if ( ~reset_n ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    assign led_n = ~counter[26:22];

endmodule


`default_nettype wire
