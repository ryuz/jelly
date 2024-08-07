

################################
# Timing
################################

# in_clk128
create_clock -period 8.000 -name in_clk125 -waveform {0.000 4.000} [get_ports in_clk125]



################################
# I/O
################################

# in_clk128
set_property PACKAGE_PIN L16 [get_ports in_clk125]
set_property IOSTANDARD LVCMOS33 [get_ports in_clk125]


# VGA
set_property PACKAGE_PIN R19 [get_ports vga_vsync]
set_property PACKAGE_PIN P19 [get_ports vga_hsync]
set_property PACKAGE_PIN M19 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN L20 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN J20 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN G20 [get_ports {vga_r[3]}]
set_property PACKAGE_PIN F19 [get_ports {vga_r[4]}]
set_property PACKAGE_PIN H18 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN N20 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN L19 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN J19 [get_ports {vga_g[3]}]
set_property PACKAGE_PIN H20 [get_ports {vga_g[4]}]
set_property PACKAGE_PIN F20 [get_ports {vga_g[5]}]
set_property PACKAGE_PIN P20 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN M20 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN K19 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]
set_property PACKAGE_PIN G19 [get_ports {vga_b[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[4]}]


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
set_property PACKAGE_PIN R18 [get_ports {push_sw[0]}]
set_property PACKAGE_PIN P16 [get_ports {push_sw[1]}]
set_property PACKAGE_PIN V16 [get_ports {push_sw[2]}]
set_property PACKAGE_PIN Y16 [get_ports {push_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[3]}]


# LED
set_property PACKAGE_PIN M14 [get_ports {led[0]}]
set_property PACKAGE_PIN D18 [get_ports {led[3]}]
set_property PACKAGE_PIN G14 [get_ports {led[2]}]
set_property PACKAGE_PIN M15 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]


# PMOD_A
# set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[6]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[5]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[3]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[2]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[0]}]
# set_property PACKAGE_PIN N15 [get_ports {pmod_a[0]}]
# set_property PACKAGE_PIN N16 [get_ports {pmod_a[4]}]
# set_property PACKAGE_PIN L14 [get_ports {pmod_a[1]}]
# set_property PACKAGE_PIN L15 [get_ports {pmod_a[5]}]
# set_property PACKAGE_PIN K16 [get_ports {pmod_a[2]}]
# set_property PACKAGE_PIN J16 [get_ports {pmod_a[6]}]
# set_property PACKAGE_PIN K14 [get_ports {pmod_a[3]}]
# set_property PACKAGE_PIN J14 [get_ports {pmod_a[7]}]


