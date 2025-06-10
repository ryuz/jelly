//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.01 (64-bit) 
//Created Time: 2025-06-10 07:59:48
create_clock -name mipi0_clk_p -period 2.403 -waveform {0 1.096} [get_ports {in_clk50}]
create_clock -name sys_clk -period 20 -waveform {0 10} [get_nets {sys_clk}]
create_clock -name cam_clk -period 5.555 -waveform {0 2.777} [get_nets {cam_clk}]
create_clock -name dvi_clk -period 13.333 -waveform {0 6.666} [get_nets {dvi_clk}]
create_clock -name dvi_clk_x5 -period 2.666 -waveform {0 1.333} [get_nets {dvi_clk_x5}]
create_clock -name mipi0_dphy_rx_clk -period 8.771 -waveform {0 4.385} [get_nets {mipi0_dphy_rx_clk}]
create_clock -name in_clk50 -period 20 -waveform {0 10} [get_ports {in_clk50}] -add
create_generated_clock -name ddr3_clk -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 1 -multiply_by 8 [get_pins {u_Gowin_PLL_ddr3/PLL_inst/CLKOUT0}]
create_generated_clock -name dma_clk -source [get_pins {u_Gowin_PLL_ddr3/PLL_inst/CLKOUT0}] -master_clock ddr3_clk -divide_by 4 -multiply_by 1 [get_pins {u_ddr3/gw3_top/u_ddr_phy_top/fclkdiv/CLKOUT}]

set_clock_groups -asynchronous -group [get_clocks {dma_clk}] -group [get_clocks {ddr3_clk}] -group [get_clocks {in_clk50}] -group [get_clocks {sys_clk}] -group [get_clocks {dvi_clk}]

set_max_delay -from [get_clocks {cam_clk}] -to [get_clocks {mipi0_dphy_rx_clk}] 3
set_max_delay -from [get_clocks {mipi0_dphy_rx_clk}] -to [get_clocks {cam_clk}] 3
