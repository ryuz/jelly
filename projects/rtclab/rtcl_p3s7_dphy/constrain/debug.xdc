


connect_debug_port u_ila_0/probe4 [get_nets [list {align_valid[0]} {align_valid[1]} {align_valid[2]} {align_valid[3]} {align_valid[4]}]]
connect_debug_port u_ila_0/probe5 [get_nets [list {align_data[4][0]} {align_data[4][1]} {align_data[4][2]} {align_data[4][3]} {align_data[4][4]} {align_data[4][5]} {align_data[4][6]} {align_data[4][7]} {align_data[4][8]} {align_data[4][9]}]]
connect_debug_port u_ila_0/probe7 [get_nets [list {align_10bit[0].u_pttern_align_10bit/buffer[0]} {align_10bit[0].u_pttern_align_10bit/buffer[1]} {align_10bit[0].u_pttern_align_10bit/buffer[2]} {align_10bit[0].u_pttern_align_10bit/buffer[3]} {align_10bit[0].u_pttern_align_10bit/buffer[4]} {align_10bit[0].u_pttern_align_10bit/buffer[5]} {align_10bit[0].u_pttern_align_10bit/buffer[6]} {align_10bit[0].u_pttern_align_10bit/buffer[7]} {align_10bit[0].u_pttern_align_10bit/buffer[8]} {align_10bit[0].u_pttern_align_10bit/buffer[9]} {align_10bit[0].u_pttern_align_10bit/buffer[10]} {align_10bit[0].u_pttern_align_10bit/buffer[11]}]]
connect_debug_port u_ila_0/probe8 [get_nets [list {align_10bit[0].u_pttern_align_10bit/num[0]} {align_10bit[0].u_pttern_align_10bit/num[1]} {align_10bit[0].u_pttern_align_10bit/num[2]} {align_10bit[0].u_pttern_align_10bit/num[3]}]]
connect_debug_port u_ila_0/probe9 [get_nets [list {align_10bit[0].u_pttern_align_10bit/running}]]

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
connect_debug_port u_ila_0/clk [get_nets [list u_selectio_wiz_0/inst/clk_div_out]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 12 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {u_py300_align_10bit/sync_buf[0]} {u_py300_align_10bit/sync_buf[1]} {u_py300_align_10bit/sync_buf[2]} {u_py300_align_10bit/sync_buf[3]} {u_py300_align_10bit/sync_buf[4]} {u_py300_align_10bit/sync_buf[5]} {u_py300_align_10bit/sync_buf[6]} {u_py300_align_10bit/sync_buf[7]} {u_py300_align_10bit/sync_buf[8]} {u_py300_align_10bit/sync_buf[9]} {u_py300_align_10bit/sync_buf[10]} {u_py300_align_10bit/sync_buf[11]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 4 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {dbg_python_sync[0]} {dbg_python_sync[1]} {dbg_python_sync[2]} {dbg_python_sync[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {dbg_python_data3[0]} {dbg_python_data3[1]} {dbg_python_data3[2]} {dbg_python_data3[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 4 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {dbg_python_data2[0]} {dbg_python_data2[1]} {dbg_python_data2[2]} {dbg_python_data2[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 4 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {dbg_python_data1[0]} {dbg_python_data1[1]} {dbg_python_data1[2]} {dbg_python_data1[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 4 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {dbg_python_data0[0]} {dbg_python_data0[1]} {dbg_python_data0[2]} {dbg_python_data0[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 10 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {align_sync[0]} {align_sync[1]} {align_sync[2]} {align_sync[3]} {align_sync[4]} {align_sync[5]} {align_sync[6]} {align_sync[7]} {align_sync[8]} {align_sync[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 10 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {align_data[3][0]} {align_data[3][1]} {align_data[3][2]} {align_data[3][3]} {align_data[3][4]} {align_data[3][5]} {align_data[3][6]} {align_data[3][7]} {align_data[3][8]} {align_data[3][9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 10 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {align_data[2][0]} {align_data[2][1]} {align_data[2][2]} {align_data[2][3]} {align_data[2][4]} {align_data[2][5]} {align_data[2][6]} {align_data[2][7]} {align_data[2][8]} {align_data[2][9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 10 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {align_data[1][0]} {align_data[1][1]} {align_data[1][2]} {align_data[1][3]} {align_data[1][4]} {align_data[1][5]} {align_data[1][6]} {align_data[1][7]} {align_data[1][8]} {align_data[1][9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 10 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {align_data[0][0]} {align_data[0][1]} {align_data[0][2]} {align_data[0][3]} {align_data[0][4]} {align_data[0][5]} {align_data[0][6]} {align_data[0][7]} {align_data[0][8]} {align_data[0][9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 5 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {align_bitslip[0]} {align_bitslip[1]} {align_bitslip[2]} {align_bitslip[3]} {align_bitslip[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 4 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {u_py300_align_10bit/num[0]} {u_py300_align_10bit/num[1]} {u_py300_align_10bit/num[2]} {u_py300_align_10bit/num[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list align_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list u_py300_align_10bit/running]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list u_mipi_dphy_clk_gen/u_clk_mipi_core/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 1 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list dphy_init_done]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets in_clk72]
