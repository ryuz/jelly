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
connect_debug_port u_ila_0/clk [get_nets [list u_design_1/clk_wiz_0/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {axi4s_wdma\\.tdata[0]} {axi4s_wdma\\.tdata[1]} {axi4s_wdma\\.tdata[2]} {axi4s_wdma\\.tdata[3]} {axi4s_wdma\\.tdata[4]} {axi4s_wdma\\.tdata[5]} {axi4s_wdma\\.tdata[6]} {axi4s_wdma\\.tdata[7]} {axi4s_wdma\\.tdata[8]} {axi4s_wdma\\.tdata[9]} {axi4s_wdma\\.tdata[10]} {axi4s_wdma\\.tdata[11]} {axi4s_wdma\\.tdata[12]} {axi4s_wdma\\.tdata[13]} {axi4s_wdma\\.tdata[14]} {axi4s_wdma\\.tdata[15]} {axi4s_wdma\\.tdata[16]} {axi4s_wdma\\.tdata[17]} {axi4s_wdma\\.tdata[18]} {axi4s_wdma\\.tdata[19]} {axi4s_wdma\\.tdata[20]} {axi4s_wdma\\.tdata[21]} {axi4s_wdma\\.tdata[22]} {axi4s_wdma\\.tdata[23]} {axi4s_wdma\\.tdata[24]} {axi4s_wdma\\.tdata[25]} {axi4s_wdma\\.tdata[26]} {axi4s_wdma\\.tdata[27]} {axi4s_wdma\\.tdata[28]} {axi4s_wdma\\.tdata[29]} {axi4s_wdma\\.tdata[30]} {axi4s_wdma\\.tdata[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 10 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi4s_csi2\\.tdata[0]} {axi4s_csi2\\.tdata[1]} {axi4s_csi2\\.tdata[2]} {axi4s_csi2\\.tdata[3]} {axi4s_csi2\\.tdata[4]} {axi4s_csi2\\.tdata[5]} {axi4s_csi2\\.tdata[6]} {axi4s_csi2\\.tdata[7]} {axi4s_csi2\\.tdata[8]} {axi4s_csi2\\.tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 10 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {axi4s_fmtr\\.tdata[0]} {axi4s_fmtr\\.tdata[1]} {axi4s_fmtr\\.tdata[2]} {axi4s_fmtr\\.tdata[3]} {axi4s_fmtr\\.tdata[4]} {axi4s_fmtr\\.tdata[5]} {axi4s_fmtr\\.tdata[6]} {axi4s_fmtr\\.tdata[7]} {axi4s_fmtr\\.tdata[8]} {axi4s_fmtr\\.tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {axi4s_csi2\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {axi4s_csi2\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {axi4s_csi2\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {axi4s_fmtr\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {axi4s_fmtr\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {axi4s_fmtr\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {axi4s_wdma\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {axi4s_wdma\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {axi4s_wdma\\.tvalid}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk200]
