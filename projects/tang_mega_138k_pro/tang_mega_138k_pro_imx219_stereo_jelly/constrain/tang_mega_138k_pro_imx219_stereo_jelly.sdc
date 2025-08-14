create_clock -name mipi0_clk_p -period 2.403 -waveform {0 1.096} [get_ports {mipi0_clk_p}] -add
create_clock -name mipi1_clk_p -period 2.403 -waveform {0 1.096} [get_ports {mipi1_clk_p}] -add
create_clock -name in_clk50 -period 20 -waveform {0 10} [get_ports {in_clk50}] -add
create_generated_clock -name sys_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 36 -multiply_by 18 [get_pins {u_Gowin_PLL/u_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name cam_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by  5 -multiply_by 18 [get_pins {u_Gowin_PLL/u_pll/PLL_inst/CLKOUT1}]
#create_generated_clock -name sys_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 1 -multiply_by 1 [get_pins {u_Gowin_PLL/u_pll/PLL_inst/CLKOUT0}]
#create_generated_clock -name cam_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 1 -multiply_by 4 [get_pins {u_Gowin_PLL/u_pll/PLL_inst/CLKOUT1}]
#create_generated_clock -name dvi_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 20 -multiply_by 30 [get_pins {pll_dvi_720p.u_Gowin_PLL_dvi/u_pll/PLL_inst/CLKOUT0}]
#create_generated_clock -name dvi_clk_x5 -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by  4 -multiply_by 30 [get_pins {pll_dvi_720p.u_Gowin_PLL_dvi/u_pll/PLL_inst/CLKOUT1}]
create_generated_clock -name dvi_clk    -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by 30 -multiply_by 15 [get_pins {pll_dvi_vga.u_Gowin_PLL_dvi/u_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name dvi_clk_x5 -source [get_ports {in_clk50}] -master_clock in_clk50 -divide_by  6 -multiply_by 15 [get_pins {pll_dvi_vga.u_Gowin_PLL_dvi/u_pll/PLL_inst/CLKOUT1}]
create_generated_clock -name u_imx219_mipi_rx_cam0/mipi_dphy_rx_clk -source [get_ports {mipi0_clk_p}] -master_clock mipi0_clk_p -divide_by 4 -multiply_by 1 [get_pins {u_imx219_mipi_rx_cam0/u_MIPI_DPHY_RX/mipi_dphy_rx_inst/RX_CLK_O}]
create_generated_clock -name u_imx219_mipi_rx_cam1/mipi_dphy_rx_clk -source [get_ports {mipi1_clk_p}] -master_clock mipi1_clk_p -divide_by 4 -multiply_by 1 [get_pins {u_imx219_mipi_rx_cam1/u_MIPI_DPHY_RX/mipi_dphy_rx_inst/RX_CLK_O}]
set_clock_groups -asynchronous -group [get_clocks {in_clk50}] -group [get_clocks {sys_clk}] -group [get_clocks {cam_clk}] -group [get_clocks {dvi_clk}] -group [get_clocks {u_imx219_mipi_rx_cam0/mipi_dphy_rx_clk}] -group [get_clocks {u_imx219_mipi_rx_cam1/mipi_dphy_rx_clk}]
