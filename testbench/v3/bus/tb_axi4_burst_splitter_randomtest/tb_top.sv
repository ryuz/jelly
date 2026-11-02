`timescale 1ns / 1ps
`default_nettype none


module tb_top
        #(
            parameter int DATA_BITS           = 32  ,
            parameter int NUM_TESTS           = 512 ,
            parameter int FIFO_PTR_BITS       = 5   ,
            parameter int BUSY_RATE           = 30  ,
            parameter int CKE_BUSY_RATE       = 0   ,
            parameter int MAX_OUTSTANDING     = 8   ,
            parameter int MODEL_FIFO_PTR_BITS = 0
        );

    initial begin
        $dumpfile("tb_top.fst");
        $dumpvars(0, tb_top);
    end

    logic clk = 1'b1;
    always #5 clk = ~clk;

    logic reset = 1'b1;
    initial #100 reset = 1'b0;

    initial begin
        #200000000;
        $fatal(1, "timeout");
    end

    tb_main
            #(
                .DATA_BITS           (DATA_BITS          ),
                .NUM_TESTS           (NUM_TESTS          ),
                .FIFO_PTR_BITS       (FIFO_PTR_BITS      ),
                .BUSY_RATE           (BUSY_RATE          ),
                .CKE_BUSY_RATE       (CKE_BUSY_RATE      ),
                .MAX_OUTSTANDING     (MAX_OUTSTANDING    ),
                .MODEL_FIFO_PTR_BITS (MODEL_FIFO_PTR_BITS)
            )
        u_tb_main (
                .clk   (clk),
                .reset (reset)
            );

endmodule


`default_nettype wire


// end of file