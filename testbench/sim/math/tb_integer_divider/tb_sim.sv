
`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    localparam RATE  = 1000.0 / 100.0;
    
    
    initial begin
        $dumpfile("tb_sim.vcd"); 
        $dumpvars(0, tb_sim);
//      $dumpvars(3, tb_sim);
        
        #1000000;
            $finish;
    end
    
    
    reg     reset = 1'b1;
    initial #(RATE*100)      reset = 1'b0;
    
    reg     clk = 1'b1;
    always #(RATE/2.0)       clk = ~clk;
    

    // -----------------------------------------
    //  main
    // -----------------------------------------

    tb_main
        i_tb_main
            (
                .reset,
                .clk
            );
    
    
endmodule


`default_nettype wire


// end of file
