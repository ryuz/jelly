
`timescale 1ns / 1ps
`default_nettype none

module rtcl_p3s7_blinking_led
        #(
            parameter   int COUNT_LIMIT = 50_000_000
        )
        (
            input   var logic           clk50   ,
            input   var logic           clk72   ,
            output  var logic   [1:0]   led     ,
            output  var logic   [7:0]   pmod    
        );
    
    
    // Blinking LED
    logic   [24:0]     clk50_counter; // リセットがないので初期値を設定
    always_ff @(posedge clk50) begin
        clk50_counter <= clk50_counter + 1;
    end

    logic   [24:0]     clk72_counter; // リセットがないので初期値を設定
    always_ff @(posedge clk72) begin
        clk72_counter <= clk72_counter + 1;
    end

    assign led[0] = clk50_counter[24];
    assign led[1] = clk72_counter[24];

    assign pmod[7:0] = clk50_counter[15:8];

endmodule

`default_nettype wire

// end of file
