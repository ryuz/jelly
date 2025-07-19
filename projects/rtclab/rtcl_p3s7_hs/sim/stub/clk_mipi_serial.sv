
`timescale 1ns / 1ps
`default_nettype none

module clk_mipi_serial
        (
            input   var logic reset     ,
            input   var logic clk_in1   ,
            output  var logic clk_out1  ,
            output  var logic clk_out2  ,
            output  var logic clk_out3  ,
            output  var logic clkfb_out ,
            input   var logic clkfb_in  ,
            output  var logic locked    
        );

endmodule

`default_nettype wire

// end of file
