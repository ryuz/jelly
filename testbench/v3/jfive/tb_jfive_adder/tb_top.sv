
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        #10000;
            $finish;
    end

`ifdef __VERILATOR__
    localparam           DEVICE      = "RTL"            ;
`else
    localparam           DEVICE      = "ULTRASCALE_PLUS";
`endif
    localparam           SIMULATION  = "false"          ;
    localparam           DEBUG       = "false"          ;

    
    // rese & clock
    localparam RATE = 1000.0/200.0;

    logic   clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    logic   reset = 1'b1;
    initial #(RATE*100) reset = 1'b0;

    // test
    tb_main
            #(
                .DEVICE     (DEVICE     ),
                .SIMULATION (SIMULATION ),
                .DEBUG      (DEBUG      )
            )
        u_tb_main
            (
                .reset  ,
                .clk    
            );
    
endmodule


`default_nettype wire


// end of file
