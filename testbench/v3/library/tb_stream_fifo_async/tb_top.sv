
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        #1000000;
            $finish;
    end
    
    localparam RATE0 = 1000.0/200.0;
    localparam RATE1 = 1000.0/223.7;

    logic   reset = 1'b1;
    initial #(RATE0*100) reset = 1'b0;

    logic   clk0 = 1'b1;
    initial forever #(RATE0/2.0)  clk0 = ~clk0;

    logic   clk1 = 1'b1;
    initial forever #(RATE1/2.0)  clk1 = ~clk1;
    

    tb_main
        u_tb_main
            (
                .reset  ,
                .clk0   ,
                .clk1   
            );
    
endmodule


`default_nettype wire


// end of file
