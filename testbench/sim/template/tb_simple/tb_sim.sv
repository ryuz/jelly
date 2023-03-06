// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(1, tb_sim);
        
    #10000
        $finish;
    end
    
    // ---------------------------------
    //  clock & reset
    // ---------------------------------

    localparam CLK_RATE = 1000.0/100.00;

    reg         reset = 1;
    initial #100 reset = 0;

    reg         clk = 1'b1;
    always #(CLK_RATE/2.0) clk <= ~clk;


    // ---------------------------------
    //  main
    // ---------------------------------

    tb_main
        i_tb_main
            (
                .reset,
                .clk
            );
    
endmodule


`default_nettype wire


// end of file
