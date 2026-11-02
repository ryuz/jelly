`timescale 1ns / 1ps
`default_nettype none


module tb_top();

    logic   clk = 1'b0;
    logic   reset = 1'b1;

    always #5 clk = ~clk;

    initial begin
        repeat (10) @(posedge clk);
        reset = 1'b0;
    end

    initial begin
        #100000;
        $fatal(1, "Top-level timeout");
    end

    tb_main
        u_tb_main
            (
                .reset  (reset),
                .clk    (clk)
            );

endmodule


`default_nettype wire