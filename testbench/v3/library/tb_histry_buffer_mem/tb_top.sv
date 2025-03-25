
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        #1000000;
            $finish;
    end
    
    localparam RATE = 1000.0/200.0;

    logic   clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    logic   reset = 1'b1;
    initial #(RATE*100) reset = 1'b0;

    tb_main
        u_tb_main
            (
                .reset  ,
                .clk    
            );
    
endmodule


`default_nettype wire


// end of file
