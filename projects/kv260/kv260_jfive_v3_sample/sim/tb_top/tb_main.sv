
`timescale 1ns / 1ps
`default_nettype none


module tb_main
    import jelly3_jfive32_pkg::*;
        #(
            parameter   DEVICE            = "ULTRASCALE_PLUS"   ,
            parameter   SIMULATION        = "false"             ,
            parameter   DEBUG             = "false"             
        )
        (
            input   var logic   reset,
            input   var logic   clk
        );

    logic           fan_en  ;
    logic   [7:0]   pmod    ;
    
    kv260_jfive_v3_sample
            #(
                .DEVICE         (DEVICE     ),
                .SIMULATION     (SIMULATION ),
                .DEBUG          (DEBUG      )
            )
        u_top
            (
                .fan_en         ,
                .pmod           
            );
    
    always_comb force u_top.u_design_1.reset = reset;
    always_comb force u_top.u_design_1.clk   = clk;

endmodule


`default_nettype wire


// end of file
