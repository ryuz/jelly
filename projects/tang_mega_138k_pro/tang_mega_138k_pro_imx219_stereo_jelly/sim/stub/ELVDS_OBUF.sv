
`timescale 1ns / 1ps
`default_nettype none


module ELVDS_OBUF
        (
            input   var logic       I     ,
            output  var logic       O     ,
            output  var logic       OB    
        );

    assign O  = I;
    assign OB = ~I;
    
endmodule


`default_nettype wire


// end of file
