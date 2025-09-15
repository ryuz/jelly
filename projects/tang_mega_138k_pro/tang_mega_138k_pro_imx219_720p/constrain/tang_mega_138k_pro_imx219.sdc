
# 50MHz
create_clock -name mipi0_clk_p -period 2.403 -waveform {0 1.096} [get_ports {in_clk50}]
create_clock -name sys_clk -period 20 -waveform {0 10} [get_nets {sys_clk}]
create_clock -name cam_clk -period 5.555 -waveform {0 2.777} [get_nets {cam_clk}]
create_clock -name dvi_clk -period 13.333 -waveform {0 6.666} [get_nets {dvi_clk}]
create_clock -name dvi_clk_x5 -period 2.666 -waveform {0 1.333} [get_nets {dvi_clk_x5}]
create_clock -name mipi0_dphy_rx_clk -period 8.771 -waveform {0 4.385} [get_nets {mipi0_dphy_rx_clk}]
create_clock -name in_clk50 -period 20 -waveform {0 10} [get_ports {in_clk50}] -add

set_clock_groups -asynchronous -group [get_clocks {in_clk50}] -group [get_clocks {sys_clk}] -group [get_clocks {cam_clk}] -group [get_clocks {dvi_clk}] -group [get_clocks {mipi0_dphy_rx_clk}]
