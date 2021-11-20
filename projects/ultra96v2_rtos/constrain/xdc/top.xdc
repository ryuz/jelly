create_clock -period 3.0 -name clk -waveform {0.000 1.5} [get_ports clk]

#set_property PACKAGE_PIN B9 [get_ports {led[1]}]
#set_property PACKAGE_PIN A9 [get_ports {led[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
