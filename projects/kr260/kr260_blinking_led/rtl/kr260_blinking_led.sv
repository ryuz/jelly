
`timescale 1ns / 1ps
`default_nettype none

module kr260_blinking_led
        #(
            parameter   int COUNT_LIMIT = 25000000
        )
        (
            input   var logic           clk     ,
            output  var logic   [1:0]   led     ,
            output  var logic           fan_en
        );
    
    // Block design
    logic   reset_n;
    design_1
        u_design_1
            (
                .fan_en     (fan_en ),
                .reset_n    (reset_n)
            );
    
    // Blinking LED
    logic   [24:0]     counter; // リセットがないので初期値を設定
    always_ff @(posedge clk or negedge reset_n) begin
        if ( ~reset_n ) begin
            counter <= 0;
            led     <= 0;
        end
        else begin
            // 25MHz で 1秒間隔でカウントアップ
            if ( counter >= 25'(COUNT_LIMIT - 1) ) begin
                counter <= 0;
                led     <= led + 1;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end

endmodule

`default_nettype wire

// end of file
