
`timescale 1 ns / 1 ps

module design_1
   (out_clk,
    fan_en,
    out_reset);
  output out_clk;
  output [0:0]fan_en;
  output [0:0]out_reset;

  wire out_clk;
  wire [0:0]fan_en;
  wire [0:0]out_reset;

    reg     clk;
    reg     reset;

    assign out_clk = clk;
    assign fan_en = 1'b0;
    assign out_reset = reset;

endmodule
