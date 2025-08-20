
`timescale 1ns / 1ps
`default_nettype none

module BUFIO
        (
            input   var logic I     ,
            output  var logic O     
        );

    assign O  = I;

endmodule

`default_nettype wire

// end of file
