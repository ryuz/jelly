


################################
# Timing
################################

# in_clk125
create_clock -period 8.000 -name in_clk125 -waveform {0.000 4.000} [get_ports in_clk125]

# HDMI-RX 480p (27.7MHz)
# create_clock -period 36.101 -name hdmi_clk_p -waveform {0.000 18.050} [get_ports hdmi_clk_p]


# clk_fpga_0                     133MHz   7.500ns
# clk_fpga_1                     100MHz  10.000ns
# clk_out1_design_1_clk_wiz_0_0  100MHz  10.000ns
# clk_out2_design_1_clk_wiz_0_0  200MHz   5.000ns
# rxbyteclkhs                             8.768ns

# set_clock_groups -name async_clks0 -asynchronous -group [get_clocks -include_generated_clocks in_clk125]   -group {clk_fpga_0 clk_fpga_1}
# set_clock_groups -name async_clks1 -asynchronous -group [get_clocks -include_generated_clocks rxbyteclkhs] -group {clk_fpga_0 clk_fpga_1}
# set_clock_groups -name async_clks2 -asynchronous -group [get_clocks -include_generated_clocks rxbyteclkhs] -group [get_clocks -include_generated_clocks in_clk125]
# set_clock_groups -name async_clks3 -asynchronous -group {clk_fpga_1} -group {clk_out2_design_1_clk_wiz_0_0}


#set_max_delay -datapath_only -from [get_clocks clk_fpga_0] -to [get_clocks clk_fpga_1] 7.500
#set_max_delay -datapath_only -from [get_clocks clk_fpga_1] -to [get_clocks clk_fpga_0] 7.500


set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets pmod_jb_p_IBUF[4]]


################################
# I/O
################################

# in_clk125
set_property PACKAGE_PIN K17 [get_ports in_clk125]
set_property IOSTANDARD LVCMOS33 [get_ports in_clk125]


# DIP-SW
set_property PACKAGE_PIN G15 [get_ports {dip_sw[0]}]
set_property PACKAGE_PIN P15 [get_ports {dip_sw[1]}]
set_property PACKAGE_PIN W13 [get_ports {dip_sw[2]}]
set_property PACKAGE_PIN T16 [get_ports {dip_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[3]}]

# PUSH-SW
set_property PACKAGE_PIN K18 [get_ports {push_sw[0]}]
set_property PACKAGE_PIN P16 [get_ports {push_sw[1]}]
set_property PACKAGE_PIN K19 [get_ports {push_sw[2]}]
set_property PACKAGE_PIN Y16 [get_ports {push_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[3]}]

# LED
set_property PACKAGE_PIN M14 [get_ports {led[0]}]
set_property PACKAGE_PIN M15 [get_ports {led[1]}]
set_property PACKAGE_PIN G14 [get_ports {led[2]}]
set_property PACKAGE_PIN D18 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]


# PMOD_A
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[0]}]
set_property PACKAGE_PIN N15 [get_ports {pmod_a[0]}]
set_property PACKAGE_PIN N16 [get_ports {pmod_a[4]}]
set_property PACKAGE_PIN L14 [get_ports {pmod_a[1]}]
set_property PACKAGE_PIN L15 [get_ports {pmod_a[5]}]
set_property PACKAGE_PIN K16 [get_ports {pmod_a[2]}]
set_property PACKAGE_PIN J16 [get_ports {pmod_a[6]}]
set_property PACKAGE_PIN K14 [get_ports {pmod_a[3]}]
set_property PACKAGE_PIN J14 [get_ports {pmod_a[7]}]

# PMOD_B
set_property PACKAGE_PIN V8  [get_ports {pmod_jb_p[1]}]
set_property PACKAGE_PIN U7  [get_ports {pmod_jb_p[2]}]
set_property PACKAGE_PIN Y7  [get_ports {pmod_jb_p[3]}]
set_property PACKAGE_PIN V6  [get_ports {pmod_jb_p[4]}]
set_property PACKAGE_PIN W8  [get_ports {pmod_jb_n[1]}]
set_property PACKAGE_PIN V7  [get_ports {pmod_jb_n[2]}]
set_property PACKAGE_PIN Y6  [get_ports {pmod_jb_n[3]}]
set_property PACKAGE_PIN W6  [get_ports {pmod_jb_n[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jb_n[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jb_n[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jb_n[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jb_n[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jb_p[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jb_p[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jb_p[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jb_p[4]}]

# PMOD_C
set_property PACKAGE_PIN V15  [get_ports {pmod_jc_p[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_jc_p[1]}]
