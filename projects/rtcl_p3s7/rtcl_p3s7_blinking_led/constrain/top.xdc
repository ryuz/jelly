# set_property CONFIG_MODE SPIx4 [current_design]

# Clock
create_clock -period 20.000 -name clk50 -waveform {0.000 10.000} [get_ports clk50]
create_clock -period 13.888 -name clk72 -waveform {0.000  6.944} [get_ports clk72]

# clock
set_property PACKAGE_PIN H4 [get_ports clk50]
set_property IOSTANDARD LVCMOS18 [get_ports {clk50}]

set_property PACKAGE_PIN G11 [get_ports clk72]
set_property IOSTANDARD LVCMOS33 [get_ports {clk72}]

# LED
set_property PACKAGE_PIN P12 [get_ports {led[0]}]
set_property PACKAGE_PIN P13 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

# PMOD
set_property PACKAGE_PIN A12 [get_ports {pmod[0]}]
set_property PACKAGE_PIN A13 [get_ports {pmod[1]}]
set_property PACKAGE_PIN M13 [get_ports {pmod[2]}]
set_property PACKAGE_PIN L14 [get_ports {pmod[3]}]
set_property PACKAGE_PIN H11 [get_ports {pmod[4]}]
set_property PACKAGE_PIN H12 [get_ports {pmod[5]}]
set_property PACKAGE_PIN N14 [get_ports {pmod[6]}]
set_property PACKAGE_PIN M14 [get_ports {pmod[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[7]}]
