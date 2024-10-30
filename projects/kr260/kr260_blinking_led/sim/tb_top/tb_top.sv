

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

    localparam RATE25 = 1000.0/25.00;

    logic       clk25 = 1'b1;
    always #(RATE25/2.0) clk25 <= ~clk25;

    
    // ---------------------------------
    //  main
    // ---------------------------------

    tb_main
        u_tb_main
            (
                .clk25
            );
    
    
endmodule


`default_nettype wire
