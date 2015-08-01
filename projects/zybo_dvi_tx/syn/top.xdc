
# create_clock -period 8.000 -name in_clk125 -waveform {0.000 4.000} [get_ports in_clk125]

# set_property PACKAGE_PIN L16 [get_ports in_clk125]
# set_property IOSTANDARD LVCMOS33 [get_ports in_clk125]
# set_property PACKAGE_PIN R18 [get_ports in_reset]
# set_property IOSTANDARD LVCMOS33 [get_ports in_reset]


#create_clock -period 13.333 -name hdmi_clk_p -waveform {0.000 6.667} [get_ports hdmi_clk_p -filter direction==in]
create_clock -period 13.333 -name hdmi_clk_p -waveform {0.000 6.667} [get_ports hdmi_clk_p]

# HDMI
set_property PACKAGE_PIN F17 [get_ports hdmi_out_en]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_out_en]

set_property PACKAGE_PIN H16 [get_ports hdmi_clk_p]
set_property PACKAGE_PIN D19 [get_ports {hdmi_data_p[0]}]
set_property PACKAGE_PIN C20 [get_ports {hdmi_data_p[1]}]
set_property PACKAGE_PIN B19 [get_ports {hdmi_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_data_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_data_p[2]}]


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

# LED
set_property PACKAGE_PIN M14 [get_ports {led[0]}]
set_property PACKAGE_PIN D18 [get_ports {led[3]}]
set_property PACKAGE_PIN G14 [get_ports {led[2]}]
set_property PACKAGE_PIN M15 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]


# clk_fpga_0 100MHz pri
# clk_fpga_1 175MHz mem
# clk_fpga_2  25MHz video
# clk_fpga_3 125MHz video_x5

# peri <=> mem
set_max_delay -datapath_only -from [get_clocks clk_fpga_0] -to [get_clocks clk_fpga_1] 10.000
set_max_delay -datapath_only -from [get_clocks clk_fpga_1] -to [get_clocks clk_fpga_0] 10.000

# peri <=> video
set_max_delay -datapath_only -from [get_clocks clk_fpga_0] -to [get_clocks clk_fpga_2] 10.000
set_max_delay -datapath_only -from [get_clocks clk_fpga_2] -to [get_clocks clk_fpga_0] 10.000

# video <=> mem
set_max_delay -datapath_only -from [get_clocks clk_fpga_1] -to [get_clocks clk_fpga_2] 5.000
set_max_delay -datapath_only -from [get_clocks clk_fpga_2] -to [get_clocks clk_fpga_1] 5.000


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


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list {i_dvi_rx/pmod_a_OBUF[0]}]]
set_property port_width 10 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_dvi_rx/dec_data2[0]} {i_dvi_rx/dec_data2[1]} {i_dvi_rx/dec_data2[2]} {i_dvi_rx/dec_data2[3]} {i_dvi_rx/dec_data2[4]} {i_dvi_rx/dec_data2[5]} {i_dvi_rx/dec_data2[6]} {i_dvi_rx/dec_data2[7]} {i_dvi_rx/dec_data2[8]} {i_dvi_rx/dec_data2[9]}]]
create_debug_port u_ila_0 probe
set_property port_width 10 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_dvi_rx/dec_data1[0]} {i_dvi_rx/dec_data1[1]} {i_dvi_rx/dec_data1[2]} {i_dvi_rx/dec_data1[3]} {i_dvi_rx/dec_data1[4]} {i_dvi_rx/dec_data1[5]} {i_dvi_rx/dec_data1[6]} {i_dvi_rx/dec_data1[7]} {i_dvi_rx/dec_data1[8]} {i_dvi_rx/dec_data1[9]}]]
create_debug_port u_ila_0 probe
set_property port_width 10 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_dvi_rx/dec_data0[0]} {i_dvi_rx/dec_data0[1]} {i_dvi_rx/dec_data0[2]} {i_dvi_rx/dec_data0[3]} {i_dvi_rx/dec_data0[4]} {i_dvi_rx/dec_data0[5]} {i_dvi_rx/dec_data0[6]} {i_dvi_rx/dec_data0[7]} {i_dvi_rx/dec_data0[8]} {i_dvi_rx/dec_data0[9]}]]
create_debug_port u_ila_0 probe
set_property port_width 10 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_dvi_rx/clk_data[0]} {i_dvi_rx/clk_data[1]} {i_dvi_rx/clk_data[2]} {i_dvi_rx/clk_data[3]} {i_dvi_rx/clk_data[4]} {i_dvi_rx/clk_data[5]} {i_dvi_rx/clk_data[6]} {i_dvi_rx/clk_data[7]} {i_dvi_rx/clk_data[8]} {i_dvi_rx/clk_data[9]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets pmod_a_OBUF[0]]
