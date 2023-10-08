
`default_nettype none

module tang_nano_9k_blink_led
        (
            input   var logic           reset_n,
            input   var logic           clk,

            output  var logic   [4:0]   led
        );

    logic   [26:0]  counter;
    always_ff @(posedge clk) begin
        if ( ~reset_n ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    assign led = counter[26:22];

endmodule
