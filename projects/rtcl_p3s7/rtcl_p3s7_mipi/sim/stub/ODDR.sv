
`timescale 1ns / 1ps
`default_nettype none

module ODDR
        #(
            parameter DDR_CLK_EDGE = "SAME_EDGE"  
        )
        (
            output  var logic Q     ,
            input   var logic C     ,
            input   var logic CE    ,
            input   var logic D1    ,
            input   var logic D2    ,
            input   var logic R     ,
            input   var logic S     
        );

    always @( C ) begin
        Q <= C ? D1 : D2;
    end

endmodule

`default_nettype wire

// end of file
