
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/processing_system7_0/inst/FCLK_CLK1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_video_integrator_bram/reg_param_rate[0]} {i_video_integrator_bram/reg_param_rate[1]} {i_video_integrator_bram/reg_param_rate[2]} {i_video_integrator_bram/reg_param_rate[3]} {i_video_integrator_bram/reg_param_rate[4]} {i_video_integrator_bram/reg_param_rate[5]} {i_video_integrator_bram/reg_param_rate[6]} {i_video_integrator_bram/reg_param_rate[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 30 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {wb_host_adr_o[0]} {wb_host_adr_o[1]} {wb_host_adr_o[2]} {wb_host_adr_o[3]} {wb_host_adr_o[4]} {wb_host_adr_o[5]} {wb_host_adr_o[6]} {wb_host_adr_o[7]} {wb_host_adr_o[8]} {wb_host_adr_o[9]} {wb_host_adr_o[10]} {wb_host_adr_o[11]} {wb_host_adr_o[12]} {wb_host_adr_o[13]} {wb_host_adr_o[14]} {wb_host_adr_o[15]} {wb_host_adr_o[16]} {wb_host_adr_o[17]} {wb_host_adr_o[18]} {wb_host_adr_o[19]} {wb_host_adr_o[20]} {wb_host_adr_o[21]} {wb_host_adr_o[22]} {wb_host_adr_o[23]} {wb_host_adr_o[24]} {wb_host_adr_o[25]} {wb_host_adr_o[26]} {wb_host_adr_o[27]} {wb_host_adr_o[28]} {wb_host_adr_o[29]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {wb_host_dat_i[0]} {wb_host_dat_i[1]} {wb_host_dat_i[2]} {wb_host_dat_i[3]} {wb_host_dat_i[4]} {wb_host_dat_i[5]} {wb_host_dat_i[6]} {wb_host_dat_i[7]} {wb_host_dat_i[8]} {wb_host_dat_i[9]} {wb_host_dat_i[10]} {wb_host_dat_i[11]} {wb_host_dat_i[12]} {wb_host_dat_i[13]} {wb_host_dat_i[14]} {wb_host_dat_i[15]} {wb_host_dat_i[16]} {wb_host_dat_i[17]} {wb_host_dat_i[18]} {wb_host_dat_i[19]} {wb_host_dat_i[20]} {wb_host_dat_i[21]} {wb_host_dat_i[22]} {wb_host_dat_i[23]} {wb_host_dat_i[24]} {wb_host_dat_i[25]} {wb_host_dat_i[26]} {wb_host_dat_i[27]} {wb_host_dat_i[28]} {wb_host_dat_i[29]} {wb_host_dat_i[30]} {wb_host_dat_i[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {wb_host_dat_o[0]} {wb_host_dat_o[1]} {wb_host_dat_o[2]} {wb_host_dat_o[3]} {wb_host_dat_o[4]} {wb_host_dat_o[5]} {wb_host_dat_o[6]} {wb_host_dat_o[7]} {wb_host_dat_o[8]} {wb_host_dat_o[9]} {wb_host_dat_o[10]} {wb_host_dat_o[11]} {wb_host_dat_o[12]} {wb_host_dat_o[13]} {wb_host_dat_o[14]} {wb_host_dat_o[15]} {wb_host_dat_o[16]} {wb_host_dat_o[17]} {wb_host_dat_o[18]} {wb_host_dat_o[19]} {wb_host_dat_o[20]} {wb_host_dat_o[21]} {wb_host_dat_o[22]} {wb_host_dat_o[23]} {wb_host_dat_o[24]} {wb_host_dat_o[25]} {wb_host_dat_o[26]} {wb_host_dat_o[27]} {wb_host_dat_o[28]} {wb_host_dat_o[29]} {wb_host_dat_o[30]} {wb_host_dat_o[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 4 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {wb_host_sel_o[0]} {wb_host_sel_o[1]} {wb_host_sel_o[2]} {wb_host_sel_o[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list wb_host_ack_i]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list wb_host_stb_o]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list wb_host_we_o]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets axi4l_peri_aclk]
