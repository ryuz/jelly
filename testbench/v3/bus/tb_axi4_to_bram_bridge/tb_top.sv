
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        #100000;
            $finish;
    end
    
    localparam RATE_AXI4 = 1000.0/120.0;
    localparam RATE_BRAM = 1000.0/333.0;

    logic   axi4_aclk = 1'b1;
    always #(RATE_AXI4/2.0)  axi4_aclk = ~axi4_aclk;

    logic   bram_clk = 1'b1;
    always #(RATE_BRAM/2.0)  bram_clk = ~bram_clk;
    
    logic   reset = 1'b1;
    initial #(RATE_AXI4*100) reset = 1'b0;

    tb_main
        u_tb_main
            (
                .axi4_aresetn   (~reset     ),
                .axi4_aclk      (axi4_aclk  ),
                .bram_reset     (reset      ),
                .bram_clk       (bram_clk   )
            );
    
endmodule


`default_nettype wire


// end of file
