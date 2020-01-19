

################################
# Timing
################################

#set_max_delay -datapath_only -from [get_clocks clk_fpga_0] -to [get_clocks clk_fpga_1] 7.500
#set_max_delay -datapath_only -from [get_clocks clk_fpga_1] -to [get_clocks clk_fpga_0] 7.500


################################
# I/O
################################


# MIPI
set_property PACKAGE_PIN P1 [get_ports cam_clk_n]
set_property PACKAGE_PIN N2 [get_ports cam_clk_p]
set_property PACKAGE_PIN N4 [get_ports {cam_data_n[0]}]
set_property PACKAGE_PIN N5 [get_ports {cam_data_p[0]}]
set_property PACKAGE_PIN M1 [get_ports {cam_data_n[1]}]
set_property PACKAGE_PIN M2 [get_ports {cam_data_p[1]}]
#set_property PACKAGE_PIN XXX [get_ports cam_clk]
#set_property PACKAGE_PIN XXX [get_ports cam_gpio]
#set_property PACKAGE_PIN XXX [get_ports cam_scl]
#set_property PACKAGE_PIN XXX [get_ports cam_sda]

