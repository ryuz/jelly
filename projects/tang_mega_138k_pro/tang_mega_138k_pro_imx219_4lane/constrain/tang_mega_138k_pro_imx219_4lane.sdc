
create_clock -name in_clk50 -period 20.000 -waveform {0 10.000} [get_ports {in_clk50}] -add
create_clock -name mipi0_clk_p -period 2.403 -waveform {0 1.096} [get_ports {mipi0_clk_p}] -add
create_generated_clock -name sys_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 36 -multiply_by 18 [get_pins {u_Gowin_PLL/u_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name cam_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 10 -multiply_by 18 [get_pins {u_Gowin_PLL/u_pll/PLL_inst/CLKOUT1}]
create_generated_clock -name dvi_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 30 -multiply_by 15 [get_pins {u_Gowin_PLL_dvi/u_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name dvi_clk_x5 -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by  6 -multiply_by 15 [get_pins {u_Gowin_PLL_dvi/u_pll/PLL_inst/CLKOUT1}]
create_generated_clock -name mipi0_dphy_rx_clk -source [get_ports {mipi0_clk_p}] -master_clock mipi0_clk_p -divide_by 4 -multiply_by 1 [get_pins {u_imx219_mipi_rx_4lane/u_MIPI_DPHY_RX/mipi_dphy_rx_inst/RX_CLK_O}]
set_clock_groups -asynchronous -group [get_clocks {in_clk50}] -group [get_clocks {sys_clk}] -group [get_clocks {cam_clk}] -group [get_clocks {dvi_clk}] -group [get_clocks {mipi0_dphy_rx_clk}]
