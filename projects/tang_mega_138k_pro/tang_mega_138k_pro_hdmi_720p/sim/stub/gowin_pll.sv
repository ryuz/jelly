
`default_nettype none

module Gowin_PLL
        (
            input   var logic   clkin   ,
            output  var logic   clkout0 ,
            output  var logic   clkout1 ,
            output  var logic   lock    
        );

    assign lock = 1'b1;

endmodule

`default_nettype wire


