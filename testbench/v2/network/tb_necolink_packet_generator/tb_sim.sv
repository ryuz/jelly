
`timescale 1ns / 1ps
`default_nettype none


module tb_sim();

    // -----------------------------
    //  simulation setting
    // -----------------------------

    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
        
    #20000
        $finish();
    end

    localparam RATE = 1000.0/300.0;
//  localparam RATE = 1000.0/250.0;

    reg     reset = 1'b1;
    always #(RATE*100)  reset = 1'b0;

    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;



    tb_main
        i_tb_main
            (
                .reset      (reset),
                .clk        (clk)
            );
    
    
endmodule


`default_nettype wire


// end of file
