
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   clk25
        );
    
    logic   [1:0]   led     ;
    logic           fan_en  ;
    kr260_blinking_led
        u_kr260_blinking_led
            (
                .clk        (clk25  ),
                .led        (led    ),
                .fan_en     (fan_en )
            );
    
endmodule


`default_nettype wire
