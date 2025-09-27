
`timescale 1ns / 1ps
`default_nettype none

module BUFR
        #(
            parameter SIM_DEVICE  = "",
            parameter BUFR_DIVIDE = "BYPASS"
        )
        (
            input   var logic I     ,
            input   var logic CE    ,
            input   var logic CLR   ,
            output  var logic O     
        );

    assign O  = I;

endmodule

`default_nettype wire

// end of file
