
`default_nettype none

module tang_mega_138k_pro_blinking_led
        (
            input   var logic           reset    ,
            input   var logic           clk      ,   // 50MHz

            output  var logic   [5:0]   led_n
        );
    

    logic   [29:0]  counter;
    always_ff @(posedge clk or posedge reset) begin
        if ( reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    assign led_n[5:0] = ~counter[29:24];

endmodule


`default_nettype wire
