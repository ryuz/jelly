
# 25MHz
create_clock -period 40.000 -name clk -waveform {0.000 20.000} [get_ports clk]

# fan enable
set_property PACKAGE_PIN A12 [get_ports fan_en]
set_property IOSTANDARD LVCMOS18 [get_ports fan_en]

# clock
set_property PACKAGE_PIN C3 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports {clk}]

# LED
set_property PACKAGE_PIN F8 [get_ports {led[0]}]
set_property PACKAGE_PIN E8 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
