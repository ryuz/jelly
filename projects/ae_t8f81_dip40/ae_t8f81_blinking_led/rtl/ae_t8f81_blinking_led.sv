
`timescale 1ns / 1ps
`default_nettype none

module ae_t8f81_blinking_led
        #(
            parameter   int COUNT_LIMIT = 25000000
        )
        (
            input   var logic           clk     ,
            output  var logic   [3:0]   led     
        );
    
    // Blinking LED
    logic   [24:0]     counter;
    always_ff @(posedge clk) begin
        // 25MHz で 1秒間隔でカウントアップ
        if ( counter >= 25'(COUNT_LIMIT - 1) ) begin
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
