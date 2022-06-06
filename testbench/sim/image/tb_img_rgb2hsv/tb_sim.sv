
`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    localparam RATE = 10.0;
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
        
    #2000000
        $finish();
    end

    logic   reset = 1'b1;
    always #(RATE*100)  reset = 1'b0;

    logic   clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    

    // -----------------------------
    //  main
    // -----------------------------

    tb_main
        i_sim_main
            (
                .*
            );
    
    
endmodule


`default_nettype wire


// end of file
