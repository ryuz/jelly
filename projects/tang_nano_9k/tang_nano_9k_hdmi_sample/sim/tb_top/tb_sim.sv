
`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
        
    #1000000
        $finish;
    end
    

    // ---------------------------------
    //  clock & reset
    // ---------------------------------

    localparam RATE27  =    27.0/100.00;
    localparam RATE126 =   126.0/200.00;
    localparam RATE25  = 5*126.0/250.00;

    reg         in_reset_n = 1'b0;
    initial #100 in_reset_n = 1'b1;

    reg         in_clk = 1'b1;
    always #(RATE27/2.0) in_clk <= ~in_clk;

    reg			clk = 1'b1;
    always #(RATE25/2.0) clk <= ~clk;

    reg			clk_x5 = 1'b1;
    always #(RATE126/2.0) clk_x5 <= ~clk_x5;


    
    // ---------------------------------
    //  main
    // ---------------------------------

    tb_main
        i_tb_main
            (
                .in_reset_n,
                .in_clk,
                .clk,
                .clk_x5
            );
    
    
endmodule


`default_nettype wire


// end of file
