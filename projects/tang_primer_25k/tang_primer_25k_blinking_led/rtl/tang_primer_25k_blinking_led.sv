
`default_nettype none

module tang_primer_25k_blinking_led
        (
            input   var logic           in_clk50,     // 50MHz
            output  var logic   [1:0]   led
        );
    
    logic   reset = 0;

    logic   [24:0]  counter;
    always_ff @(posedge in_clk50) begin
        counter <= counter + 1;
    end
    assign led = ~counter[24:23];

endmodule


`default_nettype wire
