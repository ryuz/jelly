
`timescale 1ns / 1ps
`default_nettype none

module tb_top();
    
    initial begin
        $dumpfile("tb_top.fst");
        $dumpvars(0, tb_top);
        
    #10000000
        $finish;
    end
    
    // ---------------------------------
    //  reset and clock
    // ---------------------------------

    localparam RATE = 1000.0/100.00;

    logic       reset = 1'b1;
    initial #(RATE * 20) reset = 1'b0;

    logic       clk = 1'b1;
    initial forever #(RATE/2.0) clk = ~clk;

    
    // ---------------------------------
    //  DUT
    // ---------------------------------

    logic           fan_en  ;
    logic   [7:0]   pmod    ;
    kv260_rpu_sample
            #(
                .COUNT_LIMIT(100000  )   // シミュレーション時は高速にする
            )
        u_kv260_rpu_sample
            (
                .pmod       (pmod   ),
                .fan_en     (fan_en )
            );
    
    always_comb force u_kv260_rpu_sample.u_design_1.reset  = reset;
    always_comb force u_kv260_rpu_sample.u_design_1.clk    = clk;

endmodule

`default_nettype wire
