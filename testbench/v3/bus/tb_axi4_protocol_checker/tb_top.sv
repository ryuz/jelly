`timescale 1ns / 1ps
`default_nettype none


module tb_top();

    logic clk = 1'b1;
    always #5 clk = ~clk;

    logic reset = 1'b1;
    initial begin
        #20 reset = 1'b0;
    end

    initial begin
        #10000;
        $fatal(1, "timeout");
    end

    tb_main u_tb_main (
        .clk   (clk),
        .reset (reset)
    );

endmodule


`default_nettype wire


// end of file