create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/clk_wiz_0/inst/clk_out4]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 4 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {axi4s_eth_tx_tvalid[0]} {axi4s_eth_tx_tvalid[1]} {axi4s_eth_tx_tvalid[2]} {axi4s_eth_tx_tvalid[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 4 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi4s_eth_tx_tready[0]} {axi4s_eth_tx_tready[1]} {axi4s_eth_tx_tready[2]} {axi4s_eth_tx_tready[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {axi4s_eth_tx_tlast[0]} {axi4s_eth_tx_tlast[1]} {axi4s_eth_tx_tlast[2]} {axi4s_eth_tx_tlast[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {axi4s_eth_tx_tdata[3][0]} {axi4s_eth_tx_tdata[3][1]} {axi4s_eth_tx_tdata[3][2]} {axi4s_eth_tx_tdata[3][3]} {axi4s_eth_tx_tdata[3][4]} {axi4s_eth_tx_tdata[3][5]} {axi4s_eth_tx_tdata[3][6]} {axi4s_eth_tx_tdata[3][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 8 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {axi4s_eth_tx_tdata[2][0]} {axi4s_eth_tx_tdata[2][1]} {axi4s_eth_tx_tdata[2][2]} {axi4s_eth_tx_tdata[2][3]} {axi4s_eth_tx_tdata[2][4]} {axi4s_eth_tx_tdata[2][5]} {axi4s_eth_tx_tdata[2][6]} {axi4s_eth_tx_tdata[2][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 8 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {axi4s_eth_tx_tdata[1][0]} {axi4s_eth_tx_tdata[1][1]} {axi4s_eth_tx_tdata[1][2]} {axi4s_eth_tx_tdata[1][3]} {axi4s_eth_tx_tdata[1][4]} {axi4s_eth_tx_tdata[1][5]} {axi4s_eth_tx_tdata[1][6]} {axi4s_eth_tx_tdata[1][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 8 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {axi4s_eth_tx_tdata[0][0]} {axi4s_eth_tx_tdata[0][1]} {axi4s_eth_tx_tdata[0][2]} {axi4s_eth_tx_tdata[0][3]} {axi4s_eth_tx_tdata[0][4]} {axi4s_eth_tx_tdata[0][5]} {axi4s_eth_tx_tdata[0][6]} {axi4s_eth_tx_tdata[0][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 4 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {axi4s_eth_rx_tvalid[0]} {axi4s_eth_rx_tvalid[1]} {axi4s_eth_rx_tvalid[2]} {axi4s_eth_rx_tvalid[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 4 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {axi4s_eth_rx_tlast[0]} {axi4s_eth_rx_tlast[1]} {axi4s_eth_rx_tlast[2]} {axi4s_eth_rx_tlast[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 4 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {axi4s_eth_rx_tfirst[0]} {axi4s_eth_rx_tfirst[1]} {axi4s_eth_rx_tfirst[2]} {axi4s_eth_rx_tfirst[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 8 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {axi4s_eth_rx_tdata[3][0]} {axi4s_eth_rx_tdata[3][1]} {axi4s_eth_rx_tdata[3][2]} {axi4s_eth_rx_tdata[3][3]} {axi4s_eth_rx_tdata[3][4]} {axi4s_eth_rx_tdata[3][5]} {axi4s_eth_rx_tdata[3][6]} {axi4s_eth_rx_tdata[3][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 8 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {axi4s_eth_rx_tdata[2][0]} {axi4s_eth_rx_tdata[2][1]} {axi4s_eth_rx_tdata[2][2]} {axi4s_eth_rx_tdata[2][3]} {axi4s_eth_rx_tdata[2][4]} {axi4s_eth_rx_tdata[2][5]} {axi4s_eth_rx_tdata[2][6]} {axi4s_eth_rx_tdata[2][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 8 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {axi4s_eth_rx_tdata[1][0]} {axi4s_eth_rx_tdata[1][1]} {axi4s_eth_rx_tdata[1][2]} {axi4s_eth_rx_tdata[1][3]} {axi4s_eth_rx_tdata[1][4]} {axi4s_eth_rx_tdata[1][5]} {axi4s_eth_rx_tdata[1][6]} {axi4s_eth_rx_tdata[1][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 8 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {axi4s_eth_rx_tdata[0][0]} {axi4s_eth_rx_tdata[0][1]} {axi4s_eth_rx_tdata[0][2]} {axi4s_eth_rx_tdata[0][3]} {axi4s_eth_rx_tdata[0][4]} {axi4s_eth_rx_tdata[0][5]} {axi4s_eth_rx_tdata[0][6]} {axi4s_eth_rx_tdata[0][7]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets aclk]
