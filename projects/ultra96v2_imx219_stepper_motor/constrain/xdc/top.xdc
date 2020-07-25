

################################
# Timing
################################

# cam_clk_p                          456MHz(912Mbps)
# cam_clk_p_FIFO_WRCLK_OUT
# GEN_PLL_IN_IP_USP.pll0_clkout0
# clk_out1_design_1_clk_wiz_0_0      100MHz
# clk_out2_design_1_clk_wiz_0_0      200MHz
# clk_out3_design_1_clk_wiz_0_0      250MHz
# clk_pl_0                           100MHz
# clkoutphy_out                      114MHz   8.771ns
# i_design_1/clk_wiz_0/inst/clk_in1  

# cam_clk_p
create_clock -period 2.1929 -name cam_clk_p -waveform {0.000 1.0964} [get_ports cam_clk_p]

set_max_delay -datapath_only -from [get_clocks cam_clk_p_FIFO_WRCLK_OUT]      -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  5.000
set_max_delay -datapath_only -from [get_clocks cam_clk_p_FIFO_WRCLK_OUT]      -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  4.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  5.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  4.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks clk_pl_0]                       5.000
set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       4.000
set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  4.000
set_max_delay -datapath_only -from [get_clocks clk_pl_0]                      -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  5.000


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



######################################
# multi-io board
######################################


# HS_DSI_CLK_P  J5  push_sw[0]
# HS_DSI_CLK_N  H5  push_sw[1]
# HS_DSI_D0_P   G1  dip_sw[0]
# HS_DSI_D0_N   F1  dip_sw[1]
# HS_DSI_D1_P   E4  dip_sw[2]
# HS_DSI_D1_N   E3  dip_sw[3]
# HS_DSI_D2_P   E1  led[0]
# HS_DSI_D2_N   D1  led[1]
# HS_DSI_D3_P   D3  led[2]
# HS_DSI_D3_N   C3  led[3]

set_property PACKAGE_PIN J5  [get_ports {push_sw[0]}]
set_property PACKAGE_PIN H5  [get_ports {push_sw[1]}]
set_property PACKAGE_PIN G1  [get_ports {dip_sw[0]}]
set_property PACKAGE_PIN F1  [get_ports {dip_sw[1]}]
set_property PACKAGE_PIN E4  [get_ports {dip_sw[2]}]
set_property PACKAGE_PIN E3  [get_ports {dip_sw[3]}]
set_property PACKAGE_PIN E1  [get_ports {led[0]}]
set_property PACKAGE_PIN D1  [get_ports {led[1]}]
set_property PACKAGE_PIN D3  [get_ports {led[2]}]
set_property PACKAGE_PIN C3  [get_ports {led[3]}]

set_property IOSTANDARD LVCMOS12 [get_ports {push_sw[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports {push_sw[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {dip_sw[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports {dip_sw[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {dip_sw[2]}]
set_property IOSTANDARD LVCMOS12 [get_ports {dip_sw[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS12 [get_ports {led[3]}]


# HD_GPIO_0   D7   pmod0[0]
# HD_GPIO_1   F8   pmod0[1]
# HD_GPIO_2   F7   pmod0[2]
# HD_GPIO_3   G7   pmod0[3]
# HD_GPIO_4   F6   pmod0[4]
# HD_GPIO_5   G5   pmod0[5]
# HD_GPIO_6   A6   pmod0[6]
# HD_GPIO_7   A7   pmod0[7]
# HD_GPIO_8   G6   pmod1[0]
# HD_GPIO_9   E6   pmod1[1]
# HD_GPIO_10  E5   pmod1[6]*
# HD_GPIO_11  D6   pmod1[3]
# HD_GPIO_12  D5   pmod1[4]
# HD_GPIO_13  C7   pmod1[5]
# HD_GPIO_14  B6   pmod1[2]*
# HD_GPIO_15  C5   pmod1[7]

set_property PACKAGE_PIN D7  [get_ports {pmod0[0]}]
set_property PACKAGE_PIN F8  [get_ports {pmod0[1]}]
set_property PACKAGE_PIN F7  [get_ports {pmod0[2]}]
set_property PACKAGE_PIN G7  [get_ports {pmod0[3]}]
set_property PACKAGE_PIN F6  [get_ports {pmod0[4]}]
set_property PACKAGE_PIN G5  [get_ports {pmod0[5]}]
set_property PACKAGE_PIN A6  [get_ports {pmod0[6]}]
set_property PACKAGE_PIN A7  [get_ports {pmod0[7]}]
set_property PACKAGE_PIN G6  [get_ports {pmod1[0]}]
set_property PACKAGE_PIN E6  [get_ports {pmod1[1]}]
set_property PACKAGE_PIN E5  [get_ports {pmod1[6]}]
set_property PACKAGE_PIN D6  [get_ports {pmod1[3]}]
set_property PACKAGE_PIN D5  [get_ports {pmod1[4]}]
set_property PACKAGE_PIN C7  [get_ports {pmod1[5]}]
set_property PACKAGE_PIN B6  [get_ports {pmod1[2]}]
set_property PACKAGE_PIN C5  [get_ports {pmod1[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod0[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod0[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod0[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod0[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod0[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod0[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod0[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod1[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod1[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod1[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod1[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod1[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod1[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod1[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {pmod1[7]}]


# GPIO
#set_property PACKAGE_PIN D7  [get_ports {hd_gpio[0]}]
#set_property PACKAGE_PIN F8  [get_ports {hd_gpio[1]}]
#set_property PACKAGE_PIN F7  [get_ports {hd_gpio[2]}]
#set_property PACKAGE_PIN G7  [get_ports {hd_gpio[3]}]
#set_property PACKAGE_PIN F6  [get_ports {hd_gpio[4]}]
#set_property PACKAGE_PIN G5  [get_ports {hd_gpio[5]}]
#set_property PACKAGE_PIN A6  [get_ports {hd_gpio[6]}]
#set_property PACKAGE_PIN A7  [get_ports {hd_gpio[7]}]
#set_property PACKAGE_PIN G6  [get_ports {hd_gpio[8]}]
#set_property PACKAGE_PIN E6  [get_ports {hd_gpio[9]}]
#set_property PACKAGE_PIN E5  [get_ports {hd_gpio[10]}]
#set_property PACKAGE_PIN D6  [get_ports {hd_gpio[11]}]
#set_property PACKAGE_PIN D5  [get_ports {hd_gpio[12]}]
#set_property PACKAGE_PIN C7  [get_ports {hd_gpio[13]}]
#set_property PACKAGE_PIN B6  [get_ports {hd_gpio[14]}]
#set_property PACKAGE_PIN C5  [get_ports {hd_gpio[15]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[4]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[5]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[6]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[7]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[8]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[9]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[10]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[11]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[12]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[13]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[14]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {hd_gpio[15]}]

