
`timescale 1ns / 1ps
`default_nettype none


module tb_top
        (
            input   var logic   reset,
            input   var logic   clk
        );

    // ---------------------------------
    //  DUT
    // ---------------------------------

    logic   [7:0]   pmod    ;
    logic           fan_en  ;
    kv260_blinking_led
            #(
                .COUNT_LIMIT(25000  )   // シミュレーション時は高速にする
            )
        u_kv260_blinking_led
            (
                .pmod       (pmod   ),
                .fan_en     (fan_en )
            );
    
    always_comb force u_kv260_blinking_led.u_design_1.reset = reset;
    always_comb force u_kv260_blinking_led.u_design_1.clk   = clk  ;
    
endmodule


`default_nettype wire
