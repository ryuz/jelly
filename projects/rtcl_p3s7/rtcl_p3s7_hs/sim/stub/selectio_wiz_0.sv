
`timescale 1ns / 1ps
`default_nettype none

module selectio_wiz_0
        (
            input   var logic           clk_reset   ,
            input   var logic           io_reset    ,

            input   var logic           clk_in_p            ,
            input   var logic           clk_in_n            ,
            input   var logic   [4:0]   data_in_from_pins_p ,
            input   var logic   [4:0]   data_in_from_pins_n ,

            output  var logic           clk_div_out         ,
            output  var logic   [19:0]  data_in_to_device   ,
            input   var logic   [4:0]   bitslip
        );

endmodule

`default_nettype wire

// end of file
