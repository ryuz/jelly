
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        #100000;
            $finish;
    end
    
    localparam RATE0 = 1000.0/100.0;
    localparam RATE1 = 1000.0/321.9;

    logic   reset0 = 1'b1;
    initial #(RATE0*100) reset0 = 1'b0;

    logic   clk0 = 1'b1;
    initial forever #(RATE0/2.0)  clk0 = ~clk0;

    logic   reset1 = 1'b1;
    initial #(RATE1*100) reset1 = 1'b0;

    logic   clk1 = 1'b1;
    initial forever #(RATE1/2.0)  clk1 = ~clk1;
    

    tb_main
        u_tb_main
            (
                .reset0 ,
                .clk0   ,

                .reset1 ,
                .clk1
            );
    
endmodule


`default_nettype wire


// end of file
