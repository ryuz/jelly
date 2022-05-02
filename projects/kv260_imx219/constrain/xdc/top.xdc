

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

set_max_delay -datapath_only -from [get_clocks cam_clk_p_FIFO_WRCLK_OUT]      -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  5.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       5.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  5.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  4.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks clk_out1_design_1_clk_wiz_0_0]  5.000
set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  4.000
set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       4.000
set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks clk_out1_design_1_clk_wiz_0_0]  4.000
set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  4.000

#set_max_delay -datapath_only -from [get_clocks cam_clk_p_FIFO_WRCLK_OUT]      -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  5.000
#set_max_delay -datapath_only -from [get_clocks cam_clk_p_FIFO_WRCLK_OUT]      -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  4.000
#set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       5.000
#set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  5.000
#set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  4.000
#set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       5.000
#set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0]  5.000
#set_max_delay -datapath_only -from [get_clocks clk_out2_design_1_clk_wiz_0_0] -to [get_clocks clk_pl_0]                       5.000
#set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       4.000
#set_max_delay -datapath_only -from [get_clocks clk_out3_design_1_clk_wiz_0_0] -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  4.000
#set_max_delay -datapath_only -from [get_clocks clk_pl_0]                      -to [get_clocks clk_out2_design_1_clk_wiz_0_0]  5.000
#set_max_delay -datapath_only -from [get_clocks clk_pl_0]                      -to [get_clocks cam_clk_p_FIFO_WRCLK_OUT]       5.000


# MIPI
set_property PACKAGE_PIN D7  [get_ports cam_clk_p]
set_property PACKAGE_PIN D6  [get_ports cam_clk_n]
set_property PACKAGE_PIN E5  [get_ports {cam_data_p[0]}]
set_property PACKAGE_PIN D5  [get_ports {cam_data_n[0]}]
set_property PACKAGE_PIN G6  [get_ports {cam_data_p[1]}]
set_property PACKAGE_PIN F6  [get_ports {cam_data_n[1]}]

set_property PACKAGE_PIN G11 [get_ports cam_scl]
set_property PACKAGE_PIN F10 [get_ports cam_sda]
set_property IOSTANDARD LVCMOS33 [get_ports cam_scl]
set_property IOSTANDARD LVCMOS33 [get_ports cam_sda]

set_property PACKAGE_PIN F11 [get_ports cam_reset]
set_property IOSTANDARD LVCMOS33 [get_ports cam_reset]


# 2  CSI0_D0_N  HPA11_N      SOM240_1 B11                 som240_1_b11  D5
# 3  CSI0_D0_P  HPA11_P      SOM240_1 B10                 som240_1_b10  E5
# 5  CSI0_D1_N  HPA12_N      SOM240_1 A10                 som240_1_a10  F6
# 6  CSI0_D1_P  HPA12_P      SOM240_1 A9                  som240_1_a9   G6
# 8  CSI0_CLK_N HPA10_CC_N   SOM240_1 C13                 som240_1_c13  D6
# 9  CSI0_CLK_P HPA10_CC_P   SOM240_1 C12                 som240_1_c12  D7
# 11 GPIO       RPI_ENABLE   SLG7XL44677
# 12 CLK        HDA10        SOM240_1 A16                 som240_1_a16  J12
# 13 SCL        RPI_I2C_SCK  TCA9546A SC2
# 14 SDA        RPI_I2C_SDA  TCA9546A SD2
#
# SLG7XL44677
#    HDIO_RPI   HDA09        SOM240_1 A15                 som240_1_a15  F11
#
# TCA9546A (I2C ADDR = 0x74)
#    SCL        HDA00_CC      SOM240_1 D16                som240_1_d16  G11
#    SDA        HDA01         SOM240_1 D17                som240_1_d17  F10


# PMOD0
set_property PACKAGE_PIN H12 [get_ports {pmod[0]}]
set_property PACKAGE_PIN E10 [get_ports {pmod[1]}]
set_property PACKAGE_PIN D10 [get_ports {pmod[2]}]
set_property PACKAGE_PIN C11 [get_ports {pmod[3]}]
set_property PACKAGE_PIN B10 [get_ports {pmod[4]}]
set_property PACKAGE_PIN E12 [get_ports {pmod[5]}]
set_property PACKAGE_PIN D11 [get_ports {pmod[6]}]
set_property PACKAGE_PIN B11 [get_ports {pmod[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[7]}]

