
`timescale 1ns / 1ps
`default_nettype none

module IBUFDS
        #(
            parameter DIFF_TERM  = "FALSE"          ,
            parameter IOSTANDARD = "DIFF_HSTL_I_18"
        )
        (
            input   var logic I     ,
            input   var logic IB    ,
            output  var logic O     
        );

    assign O  = I;

endmodule

`default_nettype wire

// end of file
