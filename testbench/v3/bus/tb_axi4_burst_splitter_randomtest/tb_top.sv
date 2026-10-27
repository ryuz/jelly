`timescale 1ns / 1ps
`default_nettype none


module tb_top();

    initial begin
        $dumpfile("tb_top.fst");
        $dumpvars(0, tb_top);
    end

    logic clk = 1'b1;
    always #5 clk = ~clk;

    logic reset = 1'b1;
    initial #100 reset = 1'b0;

    initial begin
        #10000000;
        $fatal(1, "timeout");
    end

    tb_main u_tb_main (
        .clk   (clk),
        .reset (reset)
    );

endmodule


`default_nettype wire


// end of file