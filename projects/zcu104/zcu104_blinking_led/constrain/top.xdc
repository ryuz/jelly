


create_clock -period 8.0000 -name clk125_p -waveform {0.000 4.0000} [get_ports clk125_p]


# clock
set_property PACKAGE_PIN F23 [get_ports clk125_p]
set_property PACKAGE_PIN E23 [get_ports clk125_n]
set_property IOSTANDARD LVDS [get_ports clk125_p]
set_property IOSTANDARD LVDS [get_ports clk125_n]

# LED
set_property PACKAGE_PIN D5 [get_ports {led[0]}]
set_property PACKAGE_PIN D6 [get_ports {led[1]}]
set_property PACKAGE_PIN A5 [get_ports {led[2]}]
set_property PACKAGE_PIN B5 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

# PUSH SWITCH
set_property PACKAGE_PIN B4 [get_ports {push_sw[0]}]
set_property PACKAGE_PIN C4 [get_ports {push_sw[1]}]
set_property PACKAGE_PIN B3 [get_ports {push_sw[2]}]
set_property PACKAGE_PIN C3 [get_ports {push_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[3]}]

# DIP SWITCH
set_property PACKAGE_PIN E4 [get_ports {dip_sw[0]}]
set_property PACKAGE_PIN D4 [get_ports {dip_sw[1]}]
set_property PACKAGE_PIN F5 [get_ports {dip_sw[2]}]
set_property PACKAGE_PIN F4 [get_ports {dip_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[3]}]
