
`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    localparam RATE    = 1000.0/250.0;
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
       
        #10000000;
            $finish;
    end
    
    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    reg     reset = 1'b1;
    initial #(RATE*100.5)   reset = 1'b0;
    
    
    tb_main
        i_tb_main
            (
                .reset      (reset),
                .clk        (clk)
            );
    
    
endmodule


`default_nettype wire


// end of file
