
`timescale 1ns / 1ps
`default_nettype none

module kr260_blinking_led
            (
                input   var logic           clk,
                output  var logic   [1:0]   led
            );
    
    
    logic   [24:0]     counter = 0;
    always_ff @(posedge clk) begin
        // 25MHz で 1秒間隔でカウントアップ
        if ( counter >= 25000000 - 1 ) begin
            counter <= 0;
            led     <= led + 1;
        end
        else begin
            counter <= counter + 1;
        end
    end
    
endmodule

`default_nettype wire

// end of file
