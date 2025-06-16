//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.02 (64-bit) 
//Created Time: 2025-06-17 08:19:34
create_clock -name mipi0_clk_p -period 2.403 -waveform {0 1.096} [get_ports {mipi0_clk_p}] -add
create_clock -name in_clk50 -period 20 -waveform {0 10} [get_ports {in_clk50}] -add
create_generated_clock -name sys_clk -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 18 -multiply_by 18 [get_pins {u_Gowin_PLL/PLL_inst/CLKOUT0}]
create_generated_clock -name cam_clk -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 5 -multiply_by 18 [get_pins {u_Gowin_PLL/PLL_inst/CLKOUT1}]
create_generated_clock -name dvi_clk -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 20 -multiply_by 30 [get_pins {u_Gowin_PLL_dvi/PLL_inst/CLKOUT0}]
create_generated_clock -name dvi_clk_x5 -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 4 -multiply_by 30 [get_pins {u_Gowin_PLL_dvi/PLL_inst/CLKOUT1}]
create_generated_clock -name ddr3_clk -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 1 -multiply_by 8 [get_pins {u_Gowin_PLL_ddr3/PLL_inst/CLKOUT0}]
create_generated_clock -name dma_clk -source [get_pins {u_Gowin_PLL_ddr3/PLL_inst/CLKOUT0}] -master_clock ddr3_clk -divide_by 4 -multiply_by 1 [get_pins {u_ddr3/gw3_top/u_ddr_phy_top/fclkdiv/CLKOUT}]
create_generated_clock -name mipi0_dphy_rx_clk -source [get_ports {mipi0_clk_p}] -master_clock mipi0_clk_p -divide_by 4 -multiply_by 1 [get_pins {u_MIPI_DPHY_RX/mipi_dphy_rx_inst/RX_CLK_O}]
set_clock_groups -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {cam_clk}] -group [get_clocks {dvi_clk}] -group [get_clocks {ddr3_clk}] -group [get_clocks {dma_clk}] -group [get_clocks {mipi0_dphy_rx_clk}]
