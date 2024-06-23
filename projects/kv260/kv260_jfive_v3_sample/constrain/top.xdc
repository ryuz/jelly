
# 725MHz (BUFGの限界)
#create_clock -period 1.380 -name clk -waveform {0.000 0.690} [get_ports clk]

# 656MHz (LUTRAMの限界)
#create_clock -period 1.524 -name clk -waveform {0.000 0.762} [get_ports clk]

# 650MHz
# create_clock -period 1.538 -name clk -waveform {0.000 0.769} [get_ports clk]

# 645MHz
# create_clock -period 1.550 -name clk -waveform {0.000 0.775} [get_ports clk]

# 644MHz (DSPの限界)
# create_clock -period 1.553 -name clk -waveform {0.000 0.7765} [get_ports clk]

# 605MHz
# create_clock -period 1.652 -name clk -waveform {0.000 0.8264} [get_ports clk]

# 600MHz
# create_clock -period 1.6667 -name clk -waveform {0.000 0.8333} [get_ports clk]

# 585MHz (BRAMの限界)
# create_clock -period 1.710 -name clk -waveform {0.000 0.855} [get_ports clk]

# 550MHz
# create_clock -period 1.818 -name clk -waveform {0.000 0.909} [get_ports clk]

# 520MHz
#create_clock -period 1.923 -name clk -waveform {0.000 0.9615} [get_ports clk]

# 500MHz (URAMの限界)
#create_clock -period 2.000 -name clk -waveform {0.000 1.000} [get_ports clk]

# -mode out_of_context 


# FAN
set_property PACKAGE_PIN A12 [get_ports fan_en]
set_property IOSTANDARD LVCMOS33 [get_ports fan_en]

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

