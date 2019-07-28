create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/clk_wiz_0/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_axi4s_debug_monitor/dbg_y[0]} {i_axi4s_debug_monitor/dbg_y[1]} {i_axi4s_debug_monitor/dbg_y[2]} {i_axi4s_debug_monitor/dbg_y[3]} {i_axi4s_debug_monitor/dbg_y[4]} {i_axi4s_debug_monitor/dbg_y[5]} {i_axi4s_debug_monitor/dbg_y[6]} {i_axi4s_debug_monitor/dbg_y[7]} {i_axi4s_debug_monitor/dbg_y[8]} {i_axi4s_debug_monitor/dbg_y[9]} {i_axi4s_debug_monitor/dbg_y[10]} {i_axi4s_debug_monitor/dbg_y[11]} {i_axi4s_debug_monitor/dbg_y[12]} {i_axi4s_debug_monitor/dbg_y[13]} {i_axi4s_debug_monitor/dbg_y[14]} {i_axi4s_debug_monitor/dbg_y[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_axi4s_debug_monitor/dbg_frame[0]} {i_axi4s_debug_monitor/dbg_frame[1]} {i_axi4s_debug_monitor/dbg_frame[2]} {i_axi4s_debug_monitor/dbg_frame[3]} {i_axi4s_debug_monitor/dbg_frame[4]} {i_axi4s_debug_monitor/dbg_frame[5]} {i_axi4s_debug_monitor/dbg_frame[6]} {i_axi4s_debug_monitor/dbg_frame[7]} {i_axi4s_debug_monitor/dbg_frame[8]} {i_axi4s_debug_monitor/dbg_frame[9]} {i_axi4s_debug_monitor/dbg_frame[10]} {i_axi4s_debug_monitor/dbg_frame[11]} {i_axi4s_debug_monitor/dbg_frame[12]} {i_axi4s_debug_monitor/dbg_frame[13]} {i_axi4s_debug_monitor/dbg_frame[14]} {i_axi4s_debug_monitor/dbg_frame[15]} {i_axi4s_debug_monitor/dbg_frame[16]} {i_axi4s_debug_monitor/dbg_frame[17]} {i_axi4s_debug_monitor/dbg_frame[18]} {i_axi4s_debug_monitor/dbg_frame[19]} {i_axi4s_debug_monitor/dbg_frame[20]} {i_axi4s_debug_monitor/dbg_frame[21]} {i_axi4s_debug_monitor/dbg_frame[22]} {i_axi4s_debug_monitor/dbg_frame[23]} {i_axi4s_debug_monitor/dbg_frame[24]} {i_axi4s_debug_monitor/dbg_frame[25]} {i_axi4s_debug_monitor/dbg_frame[26]} {i_axi4s_debug_monitor/dbg_frame[27]} {i_axi4s_debug_monitor/dbg_frame[28]} {i_axi4s_debug_monitor/dbg_frame[29]} {i_axi4s_debug_monitor/dbg_frame[30]} {i_axi4s_debug_monitor/dbg_frame[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_axi4s_debug_monitor/dbg_pixel[0]} {i_axi4s_debug_monitor/dbg_pixel[1]} {i_axi4s_debug_monitor/dbg_pixel[2]} {i_axi4s_debug_monitor/dbg_pixel[3]} {i_axi4s_debug_monitor/dbg_pixel[4]} {i_axi4s_debug_monitor/dbg_pixel[5]} {i_axi4s_debug_monitor/dbg_pixel[6]} {i_axi4s_debug_monitor/dbg_pixel[7]} {i_axi4s_debug_monitor/dbg_pixel[8]} {i_axi4s_debug_monitor/dbg_pixel[9]} {i_axi4s_debug_monitor/dbg_pixel[10]} {i_axi4s_debug_monitor/dbg_pixel[11]} {i_axi4s_debug_monitor/dbg_pixel[12]} {i_axi4s_debug_monitor/dbg_pixel[13]} {i_axi4s_debug_monitor/dbg_pixel[14]} {i_axi4s_debug_monitor/dbg_pixel[15]} {i_axi4s_debug_monitor/dbg_pixel[16]} {i_axi4s_debug_monitor/dbg_pixel[17]} {i_axi4s_debug_monitor/dbg_pixel[18]} {i_axi4s_debug_monitor/dbg_pixel[19]} {i_axi4s_debug_monitor/dbg_pixel[20]} {i_axi4s_debug_monitor/dbg_pixel[21]} {i_axi4s_debug_monitor/dbg_pixel[22]} {i_axi4s_debug_monitor/dbg_pixel[23]} {i_axi4s_debug_monitor/dbg_pixel[24]} {i_axi4s_debug_monitor/dbg_pixel[25]} {i_axi4s_debug_monitor/dbg_pixel[26]} {i_axi4s_debug_monitor/dbg_pixel[27]} {i_axi4s_debug_monitor/dbg_pixel[28]} {i_axi4s_debug_monitor/dbg_pixel[29]} {i_axi4s_debug_monitor/dbg_pixel[30]} {i_axi4s_debug_monitor/dbg_pixel[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_axi4s_debug_monitor/dbg_timer[0]} {i_axi4s_debug_monitor/dbg_timer[1]} {i_axi4s_debug_monitor/dbg_timer[2]} {i_axi4s_debug_monitor/dbg_timer[3]} {i_axi4s_debug_monitor/dbg_timer[4]} {i_axi4s_debug_monitor/dbg_timer[5]} {i_axi4s_debug_monitor/dbg_timer[6]} {i_axi4s_debug_monitor/dbg_timer[7]} {i_axi4s_debug_monitor/dbg_timer[8]} {i_axi4s_debug_monitor/dbg_timer[9]} {i_axi4s_debug_monitor/dbg_timer[10]} {i_axi4s_debug_monitor/dbg_timer[11]} {i_axi4s_debug_monitor/dbg_timer[12]} {i_axi4s_debug_monitor/dbg_timer[13]} {i_axi4s_debug_monitor/dbg_timer[14]} {i_axi4s_debug_monitor/dbg_timer[15]} {i_axi4s_debug_monitor/dbg_timer[16]} {i_axi4s_debug_monitor/dbg_timer[17]} {i_axi4s_debug_monitor/dbg_timer[18]} {i_axi4s_debug_monitor/dbg_timer[19]} {i_axi4s_debug_monitor/dbg_timer[20]} {i_axi4s_debug_monitor/dbg_timer[21]} {i_axi4s_debug_monitor/dbg_timer[22]} {i_axi4s_debug_monitor/dbg_timer[23]} {i_axi4s_debug_monitor/dbg_timer[24]} {i_axi4s_debug_monitor/dbg_timer[25]} {i_axi4s_debug_monitor/dbg_timer[26]} {i_axi4s_debug_monitor/dbg_timer[27]} {i_axi4s_debug_monitor/dbg_timer[28]} {i_axi4s_debug_monitor/dbg_timer[29]} {i_axi4s_debug_monitor/dbg_timer[30]} {i_axi4s_debug_monitor/dbg_timer[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 10 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_axi4s_debug_monitor/dbg_axi4s_tdata[0]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[1]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[2]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[3]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[4]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[5]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[6]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[7]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[8]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 16 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {i_axi4s_debug_monitor/dbg_x[0]} {i_axi4s_debug_monitor/dbg_x[1]} {i_axi4s_debug_monitor/dbg_x[2]} {i_axi4s_debug_monitor/dbg_x[3]} {i_axi4s_debug_monitor/dbg_x[4]} {i_axi4s_debug_monitor/dbg_x[5]} {i_axi4s_debug_monitor/dbg_x[6]} {i_axi4s_debug_monitor/dbg_x[7]} {i_axi4s_debug_monitor/dbg_x[8]} {i_axi4s_debug_monitor/dbg_x[9]} {i_axi4s_debug_monitor/dbg_x[10]} {i_axi4s_debug_monitor/dbg_x[11]} {i_axi4s_debug_monitor/dbg_x[12]} {i_axi4s_debug_monitor/dbg_x[13]} {i_axi4s_debug_monitor/dbg_x[14]} {i_axi4s_debug_monitor/dbg_x[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 16 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {i_axi4s_debug_monitor/dbg_width[0]} {i_axi4s_debug_monitor/dbg_width[1]} {i_axi4s_debug_monitor/dbg_width[2]} {i_axi4s_debug_monitor/dbg_width[3]} {i_axi4s_debug_monitor/dbg_width[4]} {i_axi4s_debug_monitor/dbg_width[5]} {i_axi4s_debug_monitor/dbg_width[6]} {i_axi4s_debug_monitor/dbg_width[7]} {i_axi4s_debug_monitor/dbg_width[8]} {i_axi4s_debug_monitor/dbg_width[9]} {i_axi4s_debug_monitor/dbg_width[10]} {i_axi4s_debug_monitor/dbg_width[11]} {i_axi4s_debug_monitor/dbg_width[12]} {i_axi4s_debug_monitor/dbg_width[13]} {i_axi4s_debug_monitor/dbg_width[14]} {i_axi4s_debug_monitor/dbg_width[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 16 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {i_axi4s_debug_monitor/dbg_height[0]} {i_axi4s_debug_monitor/dbg_height[1]} {i_axi4s_debug_monitor/dbg_height[2]} {i_axi4s_debug_monitor/dbg_height[3]} {i_axi4s_debug_monitor/dbg_height[4]} {i_axi4s_debug_monitor/dbg_height[5]} {i_axi4s_debug_monitor/dbg_height[6]} {i_axi4s_debug_monitor/dbg_height[7]} {i_axi4s_debug_monitor/dbg_height[8]} {i_axi4s_debug_monitor/dbg_height[9]} {i_axi4s_debug_monitor/dbg_height[10]} {i_axi4s_debug_monitor/dbg_height[11]} {i_axi4s_debug_monitor/dbg_height[12]} {i_axi4s_debug_monitor/dbg_height[13]} {i_axi4s_debug_monitor/dbg_height[14]} {i_axi4s_debug_monitor/dbg_height[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list i_axi4s_debug_monitor/dbg_axi4s_tlast]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list i_axi4s_debug_monitor/dbg_axi4s_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list i_axi4s_debug_monitor/dbg_axi4s_tuser]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list i_axi4s_debug_monitor/dbg_axi4s_tvalid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk200]
