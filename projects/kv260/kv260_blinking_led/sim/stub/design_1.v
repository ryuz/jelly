
`timescale 1 ns / 1 ps

module design_1
    (
        fan_en  ,
        reset   ,
        clk     
    );
  
  output fan_en ;
  output reset  ;
  output clk    ;

  wire fan_en ;
  wire reset_n;
  wire clk    ;

  assign fan_en  = 1'b0  ;

endmodule
