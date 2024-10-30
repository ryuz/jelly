

`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   clk100
        );
    
    logic           fan_en  ;
    logic   [7:0]   pmod    ;
    kv260_sample
        u_kv260_sample
            (
                .fan_en     (fan_en ),
                .pmod       (pmod   )
            );
    
    // force の仕様が verilator で異なるので毎回実行する
    always_comb force u_kv260_sample.u_design_1.clk  = clk100;

endmodule

`default_nettype wire
