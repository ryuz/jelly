
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    localparam RATE = 10.0;
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #2000000
        $finish();
    end

    reg     reset = 1'b1;
    always #(RATE*100)  reset = 1'b0;

    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    

    // -----------------------------
    //  main
    // -----------------------------

    tb_main
        i_main
            (
                .reset,
                .clk
            );
    
endmodule


`default_nettype wire


// end of file
