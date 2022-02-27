

#create_clock -period 5.000 -name clk -waveform {0.000 2.500} [get_ports clk]

set_property PACKAGE_PIN B9 [get_ports {led[1]}]
set_property PACKAGE_PIN A9 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
