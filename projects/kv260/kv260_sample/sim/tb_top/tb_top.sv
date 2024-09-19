

`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #10000000
        $finish;
    end
    
    // ---------------------------------
    //  clock
    // ---------------------------------

    localparam RATE100 = 1000.0/100.00;

    logic       clk100 = 1'b1;
    always #(RATE100/2.0) clk100 <= ~clk100;

    
    // ---------------------------------
    //  main
    // ---------------------------------

    tb_main
        u_tb_main
            (
                .clk100
            );
    
    
endmodule


`default_nettype wire
