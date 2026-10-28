`timescale 1ns / 1ps
`default_nettype none


module tb_top();

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        #2000000;
            $fatal(1, "timeout");
    end

    localparam RATE = 1000.0/333.0;

    logic clk = 1'b1;
    always #(RATE/2.0) clk = ~clk;

    logic reset = 1'b1;
    initial #(RATE*100) reset = 1'b0;

    logic [2:0] done;

    tb_main #(.DATA_BITS(8)) u_tb_8bit (
        .reset  (reset),
        .clk    (clk),
        .done   (done[0])
    );

    tb_main #(.DATA_BITS(32)) u_tb_32bit (
        .reset  (reset),
        .clk    (clk),
        .done   (done[1])
    );

    tb_main #(.DATA_BITS(512)) u_tb_512bit (
        .reset  (reset),
        .clk    (clk),
        .done   (done[2])
    );

    initial begin
        wait (&done);
        $display("tb_axi4_burst_splitter : ALL WIDTHS PASS");
        $finish;
    end

endmodule


`default_nettype wire


// end of file