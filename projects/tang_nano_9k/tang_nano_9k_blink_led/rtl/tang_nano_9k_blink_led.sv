
module tang_nano_9k_blink_led
        (
            input   var logic   clk,
            output  var logic   led
        );

    logic   [23:0]  counter;
    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end
    assign led = counter[23];

endmodule

