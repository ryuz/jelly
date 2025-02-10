
`timescale 1ns / 1ps
`default_nettype none


module tb_top
        (
            input   var logic   reset,
            input   var logic   clk25
        );

    // ---------------------------------
    //  DUT
    // ---------------------------------

    logic   [1:0]   led     ;
    logic           fan_en  ;
    kr260_blinking_led
            #(
                .COUNT_LIMIT(25000  )   // シミュレーション時は高速にする
            )
        u_kr260_blinking_led
            (
                .clk        (clk25  ),
                .led        (led    ),
                .fan_en     (fan_en )
            );
    
    always_comb force u_kr260_blinking_led.u_design_1.reset_n  = ~reset;
    
endmodule


`default_nettype wire
