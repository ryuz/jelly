module Gowin_PLL_cam(
    clkin,
    init_clk,
    clkout0
);


input clkin;
input init_clk;
output clkout0;
wire lock;
wire [5:0] icpsel;
wire [2:0] lpfres;
wire pll_lock;
wire pll_rst;


    Gowin_PLL_cam_MOD u_pll(
        .clkout0(clkout0),
        .lock(pll_lock),
        .clkin(clkin),
        .reset(pll_rst),
        .icpsel(icpsel),
        .lpfres(lpfres),
        .lpfcap(2'b00)
    );


    PLL_INIT u_pll_init(
        .CLKIN(init_clk),
        .I_RST(1'b0),
        .O_RST(pll_rst),
        .PLLLOCK(pll_lock),
        .O_LOCK(lock),
        .ICPSEL(icpsel),
        .LPFRES(lpfres)
    );
    defparam u_pll_init.CLK_PERIOD = 20;
    defparam u_pll_init.MULTI_FAC = 24;


endmodule
