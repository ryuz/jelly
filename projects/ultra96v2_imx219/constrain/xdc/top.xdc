

################################
# Timing
################################

#set_max_delay -datapath_only -from [get_clocks clk_fpga_0] -to [get_clocks clk_fpga_1] 7.500
#set_max_delay -datapath_only -from [get_clocks clk_fpga_1] -to [get_clocks clk_fpga_0] 7.500

set_max_delay -datapath_only -from [get_clocks cam_clk_p_FIFO_WRCLK_OUT] -to [get_clocks clk_out2_design_1_clk_wiz_0_0] 5.000

set_max_delay -datapath_only -from [get_clocks cam_clk_p_FIFO_WRCLK_OUT] -to [get_clocks clk_out3_design_1_clk_wiz_0_0] 5.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0] 5.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0] 5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT] 5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0] 5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks clk_pl_0] 5.000
set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT] 5.000
set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0] 5.000
set_max_delay -datapath_only -from [get_clocks clk_pl_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0] 5.000


# clk_pl_0                           100MHz
# GEN_PLL_IN_IP_USP.pll0_clkout0
# clk_out1_design_1_clk_wiz_0_0      100MHz
# clk_out2_design_1_clk_wiz_0_0      200MHz
# clk_out3_design_1_clk_wiz_0_0      250MHz
# i_design_1/clk_wiz_0/inst/clk_in1


################################
# I/O
################################


# MIPI
set_property PACKAGE_PIN N2 [get_ports cam_clk_p]
set_property PACKAGE_PIN P1 [get_ports cam_clk_n]
set_property PACKAGE_PIN N5 [get_ports {cam_data_p[0]}]
set_property PACKAGE_PIN N4 [get_ports {cam_data_n[0]}]
set_property PACKAGE_PIN M2 [get_ports {cam_data_p[1]}]
set_property PACKAGE_PIN M1 [get_ports {cam_data_n[1]}]
#set_property PACKAGE_PIN XXX [get_ports cam_clk]
#set_property PACKAGE_PIN XXX [get_ports cam_gpio]
#set_property PACKAGE_PIN XXX [get_ports cam_scl]
#set_property PACKAGE_PIN XXX [get_ports cam_sda]

# radio LED
set_property PACKAGE_PIN A9  [get_ports {radio_led[0]}]
set_property PACKAGE_PIN B9  [get_ports {radio_led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {radio_led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {radio_led[1]}]


# GPIO
set_property PACKAGE_PIN D7  [get_ports {hd_gpio[0]}]
set_property PACKAGE_PIN F8  [get_ports {hd_gpio[1]}]
set_property PACKAGE_PIN F7  [get_ports {hd_gpio[2]}]
set_property PACKAGE_PIN G7  [get_ports {hd_gpio[3]}]
set_property PACKAGE_PIN F6  [get_ports {hd_gpio[4]}]
set_property PACKAGE_PIN G5  [get_ports {hd_gpio[5]}]
set_property PACKAGE_PIN A6  [get_ports {hd_gpio[6]}]
set_property PACKAGE_PIN A7  [get_ports {hd_gpio[7]}]
set_property PACKAGE_PIN G6  [get_ports {hd_gpio[8]}]
set_property PACKAGE_PIN E6  [get_ports {hd_gpio[9]}]
set_property PACKAGE_PIN E5  [get_ports {hd_gpio[10]}]
set_property PACKAGE_PIN D6  [get_ports {hd_gpio[11]}]
set_property PACKAGE_PIN D5  [get_ports {hd_gpio[12]}]
set_property PACKAGE_PIN C7  [get_ports {hd_gpio[13]}]
set_property PACKAGE_PIN B6  [get_ports {hd_gpio[14]}]
set_property PACKAGE_PIN C5  [get_ports {hd_gpio[15]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[8]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[9]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[10]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[12]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[13]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[14]}]
set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[15]}]

