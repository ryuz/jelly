



connect_debug_port u_ila_0/clk [get_nets [list clk72_IBUF_BUFG]]
connect_debug_port dbg_hub/clk [get_nets clk72_IBUF_BUFG]

connect_debug_port u_ila_1/probe0 [get_nets [list {dbg_python_data[0]} {dbg_python_data[1]} {dbg_python_data[2]} {dbg_python_data[3]} {dbg_python_data[4]} {dbg_python_data[5]} {dbg_python_data[6]} {dbg_python_data[7]} {dbg_python_data[8]} {dbg_python_data[9]} {dbg_python_data[10]} {dbg_python_data[11]} {dbg_python_data[12]} {dbg_python_data[13]} {dbg_python_data[14]} {dbg_python_data[15]} {dbg_python_data[16]} {dbg_python_data[17]} {dbg_python_data[18]} {dbg_python_data[19]}]]

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
connect_debug_port u_ila_0/clk [get_nets [list in_clk72_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {dbg_clk72_counter[0]} {dbg_clk72_counter[1]} {dbg_clk72_counter[2]} {dbg_clk72_counter[3]} {dbg_clk72_counter[4]} {dbg_clk72_counter[5]} {dbg_clk72_counter[6]} {dbg_clk72_counter[7]}]]
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
connect_debug_port u_ila_1/clk [get_nets [list u_selectio_wiz_0/inst/clk_div_out]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 4 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {dbg_python_sync[0]} {dbg_python_sync[1]} {dbg_python_sync[2]} {dbg_python_sync[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 4 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {dbg_python_data0[0]} {dbg_python_data0[1]} {dbg_python_data0[2]} {dbg_python_data0[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 4 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {dbg_python_data1[0]} {dbg_python_data1[1]} {dbg_python_data1[2]} {dbg_python_data1[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 4 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {dbg_python_data2[0]} {dbg_python_data2[1]} {dbg_python_data2[2]} {dbg_python_data2[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 4 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {dbg_python_data3[0]} {dbg_python_data3[1]} {dbg_python_data3[2]} {dbg_python_data3[3]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets in_clk72_IBUF_BUFG]
