module Gowin_PLL(
    clkin,
    init_clk,
    clkout0,
    clkout1,
    lock
);


input clkin;
input init_clk;
output clkout0;
output clkout1;
output lock;
wire [5:0] icpsel;
wire [2:0] lpfres;
wire pll_lock;
wire pll_rst;

endmodule
