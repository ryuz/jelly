
`timescale 1ns / 1ps
`default_nettype none


module IOBUF
        (
            input   var logic       OEN   ,
            input   var logic       I     ,
            inout   tri logic       IO    ,
            output  var logic       O     
        );

    assign O  = IO;
    assign IO = OEN ? 1'bz : I;
    
endmodule


`default_nettype wire


// end of file
