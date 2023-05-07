
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1_i/zynq_ultra_ps_e_0/inst/dp_video_ref_clk]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 36 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {dbg_dp_live_video_in_pixel1_0[0]} {dbg_dp_live_video_in_pixel1_0[1]} {dbg_dp_live_video_in_pixel1_0[2]} {dbg_dp_live_video_in_pixel1_0[3]} {dbg_dp_live_video_in_pixel1_0[4]} {dbg_dp_live_video_in_pixel1_0[5]} {dbg_dp_live_video_in_pixel1_0[6]} {dbg_dp_live_video_in_pixel1_0[7]} {dbg_dp_live_video_in_pixel1_0[8]} {dbg_dp_live_video_in_pixel1_0[9]} {dbg_dp_live_video_in_pixel1_0[10]} {dbg_dp_live_video_in_pixel1_0[11]} {dbg_dp_live_video_in_pixel1_0[12]} {dbg_dp_live_video_in_pixel1_0[13]} {dbg_dp_live_video_in_pixel1_0[14]} {dbg_dp_live_video_in_pixel1_0[15]} {dbg_dp_live_video_in_pixel1_0[16]} {dbg_dp_live_video_in_pixel1_0[17]} {dbg_dp_live_video_in_pixel1_0[18]} {dbg_dp_live_video_in_pixel1_0[19]} {dbg_dp_live_video_in_pixel1_0[20]} {dbg_dp_live_video_in_pixel1_0[21]} {dbg_dp_live_video_in_pixel1_0[22]} {dbg_dp_live_video_in_pixel1_0[23]} {dbg_dp_live_video_in_pixel1_0[24]} {dbg_dp_live_video_in_pixel1_0[25]} {dbg_dp_live_video_in_pixel1_0[26]} {dbg_dp_live_video_in_pixel1_0[27]} {dbg_dp_live_video_in_pixel1_0[28]} {dbg_dp_live_video_in_pixel1_0[29]} {dbg_dp_live_video_in_pixel1_0[30]} {dbg_dp_live_video_in_pixel1_0[31]} {dbg_dp_live_video_in_pixel1_0[32]} {dbg_dp_live_video_in_pixel1_0[33]} {dbg_dp_live_video_in_pixel1_0[34]} {dbg_dp_live_video_in_pixel1_0[35]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 36 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {dbg_dp_video_out_pixel1_0[0]} {dbg_dp_video_out_pixel1_0[1]} {dbg_dp_video_out_pixel1_0[2]} {dbg_dp_video_out_pixel1_0[3]} {dbg_dp_video_out_pixel1_0[4]} {dbg_dp_video_out_pixel1_0[5]} {dbg_dp_video_out_pixel1_0[6]} {dbg_dp_video_out_pixel1_0[7]} {dbg_dp_video_out_pixel1_0[8]} {dbg_dp_video_out_pixel1_0[9]} {dbg_dp_video_out_pixel1_0[10]} {dbg_dp_video_out_pixel1_0[11]} {dbg_dp_video_out_pixel1_0[12]} {dbg_dp_video_out_pixel1_0[13]} {dbg_dp_video_out_pixel1_0[14]} {dbg_dp_video_out_pixel1_0[15]} {dbg_dp_video_out_pixel1_0[16]} {dbg_dp_video_out_pixel1_0[17]} {dbg_dp_video_out_pixel1_0[18]} {dbg_dp_video_out_pixel1_0[19]} {dbg_dp_video_out_pixel1_0[20]} {dbg_dp_video_out_pixel1_0[21]} {dbg_dp_video_out_pixel1_0[22]} {dbg_dp_video_out_pixel1_0[23]} {dbg_dp_video_out_pixel1_0[24]} {dbg_dp_video_out_pixel1_0[25]} {dbg_dp_video_out_pixel1_0[26]} {dbg_dp_video_out_pixel1_0[27]} {dbg_dp_video_out_pixel1_0[28]} {dbg_dp_video_out_pixel1_0[29]} {dbg_dp_video_out_pixel1_0[30]} {dbg_dp_video_out_pixel1_0[31]} {dbg_dp_video_out_pixel1_0[32]} {dbg_dp_video_out_pixel1_0[33]} {dbg_dp_video_out_pixel1_0[34]} {dbg_dp_video_out_pixel1_0[35]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list dbg_dp_live_video_de_out_0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list dbg_dp_live_video_in_de_0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list dbg_dp_live_video_in_hsync_0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list dbg_dp_live_video_in_vsync_0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list dbg_dp_video_out_hsync_0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list dbg_dp_video_out_vsync_0]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list i_design_1_i/zynq_ultra_ps_e_0/inst/pl_clk0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 36 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {mon_dp_video_out_pixel1_0[0]} {mon_dp_video_out_pixel1_0[1]} {mon_dp_video_out_pixel1_0[2]} {mon_dp_video_out_pixel1_0[3]} {mon_dp_video_out_pixel1_0[4]} {mon_dp_video_out_pixel1_0[5]} {mon_dp_video_out_pixel1_0[6]} {mon_dp_video_out_pixel1_0[7]} {mon_dp_video_out_pixel1_0[8]} {mon_dp_video_out_pixel1_0[9]} {mon_dp_video_out_pixel1_0[10]} {mon_dp_video_out_pixel1_0[11]} {mon_dp_video_out_pixel1_0[12]} {mon_dp_video_out_pixel1_0[13]} {mon_dp_video_out_pixel1_0[14]} {mon_dp_video_out_pixel1_0[15]} {mon_dp_video_out_pixel1_0[16]} {mon_dp_video_out_pixel1_0[17]} {mon_dp_video_out_pixel1_0[18]} {mon_dp_video_out_pixel1_0[19]} {mon_dp_video_out_pixel1_0[20]} {mon_dp_video_out_pixel1_0[21]} {mon_dp_video_out_pixel1_0[22]} {mon_dp_video_out_pixel1_0[23]} {mon_dp_video_out_pixel1_0[24]} {mon_dp_video_out_pixel1_0[25]} {mon_dp_video_out_pixel1_0[26]} {mon_dp_video_out_pixel1_0[27]} {mon_dp_video_out_pixel1_0[28]} {mon_dp_video_out_pixel1_0[29]} {mon_dp_video_out_pixel1_0[30]} {mon_dp_video_out_pixel1_0[31]} {mon_dp_video_out_pixel1_0[32]} {mon_dp_video_out_pixel1_0[33]} {mon_dp_video_out_pixel1_0[34]} {mon_dp_video_out_pixel1_0[35]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 36 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {mon_dp_live_video_in_pixel1_0[0]} {mon_dp_live_video_in_pixel1_0[1]} {mon_dp_live_video_in_pixel1_0[2]} {mon_dp_live_video_in_pixel1_0[3]} {mon_dp_live_video_in_pixel1_0[4]} {mon_dp_live_video_in_pixel1_0[5]} {mon_dp_live_video_in_pixel1_0[6]} {mon_dp_live_video_in_pixel1_0[7]} {mon_dp_live_video_in_pixel1_0[8]} {mon_dp_live_video_in_pixel1_0[9]} {mon_dp_live_video_in_pixel1_0[10]} {mon_dp_live_video_in_pixel1_0[11]} {mon_dp_live_video_in_pixel1_0[12]} {mon_dp_live_video_in_pixel1_0[13]} {mon_dp_live_video_in_pixel1_0[14]} {mon_dp_live_video_in_pixel1_0[15]} {mon_dp_live_video_in_pixel1_0[16]} {mon_dp_live_video_in_pixel1_0[17]} {mon_dp_live_video_in_pixel1_0[18]} {mon_dp_live_video_in_pixel1_0[19]} {mon_dp_live_video_in_pixel1_0[20]} {mon_dp_live_video_in_pixel1_0[21]} {mon_dp_live_video_in_pixel1_0[22]} {mon_dp_live_video_in_pixel1_0[23]} {mon_dp_live_video_in_pixel1_0[24]} {mon_dp_live_video_in_pixel1_0[25]} {mon_dp_live_video_in_pixel1_0[26]} {mon_dp_live_video_in_pixel1_0[27]} {mon_dp_live_video_in_pixel1_0[28]} {mon_dp_live_video_in_pixel1_0[29]} {mon_dp_live_video_in_pixel1_0[30]} {mon_dp_live_video_in_pixel1_0[31]} {mon_dp_live_video_in_pixel1_0[32]} {mon_dp_live_video_in_pixel1_0[33]} {mon_dp_live_video_in_pixel1_0[34]} {mon_dp_live_video_in_pixel1_0[35]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 1 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list mon_dp_live_video_de_out_0]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 1 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list mon_dp_live_video_in_de_0]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 1 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list mon_dp_live_video_in_hsync_0]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 1 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list mon_dp_live_video_in_vsync_0]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 1 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list mon_dp_video_out_hsync_0]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
set_property port_width 1 [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list mon_dp_video_out_vsync_0]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets dp_video_in_clk_0]
