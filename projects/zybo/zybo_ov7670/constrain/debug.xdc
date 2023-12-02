
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/clk_wiz_1/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {reg_ov7670_d[0]} {reg_ov7670_d[1]} {reg_ov7670_d[2]} {reg_ov7670_d[3]} {reg_ov7670_d[4]} {reg_ov7670_d[5]} {reg_ov7670_d[6]} {reg_ov7670_d[7]} {reg_ov7670_d[8]} {reg_ov7670_d[9]} {reg_ov7670_d[10]} {reg_ov7670_d[11]} {reg_ov7670_d[12]} {reg_ov7670_d[13]} {reg_ov7670_d[14]} {reg_ov7670_d[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi4s_ov7670_tdata[0]} {axi4s_ov7670_tdata[1]} {axi4s_ov7670_tdata[2]} {axi4s_ov7670_tdata[3]} {axi4s_ov7670_tdata[4]} {axi4s_ov7670_tdata[5]} {axi4s_ov7670_tdata[6]} {axi4s_ov7670_tdata[7]} {axi4s_ov7670_tdata[8]} {axi4s_ov7670_tdata[9]} {axi4s_ov7670_tdata[10]} {axi4s_ov7670_tdata[11]} {axi4s_ov7670_tdata[12]} {axi4s_ov7670_tdata[13]} {axi4s_ov7670_tdata[14]} {axi4s_ov7670_tdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 8 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {dbg_ov7670_d[0]} {dbg_ov7670_d[1]} {dbg_ov7670_d[2]} {dbg_ov7670_d[3]} {dbg_ov7670_d[4]} {dbg_ov7670_d[5]} {dbg_ov7670_d[6]} {dbg_ov7670_d[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {dbg_ov7670_v_count[0]} {dbg_ov7670_v_count[1]} {dbg_ov7670_v_count[2]} {dbg_ov7670_v_count[3]} {dbg_ov7670_v_count[4]} {dbg_ov7670_v_count[5]} {dbg_ov7670_v_count[6]} {dbg_ov7670_v_count[7]} {dbg_ov7670_v_count[8]} {dbg_ov7670_v_count[9]} {dbg_ov7670_v_count[10]} {dbg_ov7670_v_count[11]} {dbg_ov7670_v_count[12]} {dbg_ov7670_v_count[13]} {dbg_ov7670_v_count[14]} {dbg_ov7670_v_count[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {dbg_ov7670_h_count[0]} {dbg_ov7670_h_count[1]} {dbg_ov7670_h_count[2]} {dbg_ov7670_h_count[3]} {dbg_ov7670_h_count[4]} {dbg_ov7670_h_count[5]} {dbg_ov7670_h_count[6]} {dbg_ov7670_h_count[7]} {dbg_ov7670_h_count[8]} {dbg_ov7670_h_count[9]} {dbg_ov7670_h_count[10]} {dbg_ov7670_h_count[11]} {dbg_ov7670_h_count[12]} {dbg_ov7670_h_count[13]} {dbg_ov7670_h_count[14]} {dbg_ov7670_h_count[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list axi4s_ov7670_tlast]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list axi4s_ov7670_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list axi4s_ov7670_tuser]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list axi4s_ov7670_tvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list dbg_ov7670_hs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list dbg_ov7670_vs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list reg_ov7670_busy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list reg_ov7670_fs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list reg_ov7670_last]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list reg_ov7670_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk125]
