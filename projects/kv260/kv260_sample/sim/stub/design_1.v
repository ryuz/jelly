
`timescale 1 ns / 1 ps

module design_1
   (
    fan_en,
    pl_clk);
  output fan_en;
  output pl_clk;

  wire fan_en;
  wire pl_clk;

  // テストベンチから force する前提
  reg             clk   /*verilator public_flat*/;

  // assign
  assign fan_en = 1'b0  ;
  assign pl_clk = clk   ;

endmodule
