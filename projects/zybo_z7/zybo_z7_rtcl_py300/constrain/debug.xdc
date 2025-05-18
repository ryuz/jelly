

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/clk_wiz_0/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 10 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {axi4s_csi2_tdata[0]} {axi4s_csi2_tdata[1]} {axi4s_csi2_tdata[2]} {axi4s_csi2_tdata[3]} {axi4s_csi2_tdata[4]} {axi4s_csi2_tdata[5]} {axi4s_csi2_tdata[6]} {axi4s_csi2_tdata[7]} {axi4s_csi2_tdata[8]} {axi4s_csi2_tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 10 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi4s_fmtr_tdata[0]} {axi4s_fmtr_tdata[1]} {axi4s_fmtr_tdata[2]} {axi4s_fmtr_tdata[3]} {axi4s_fmtr_tdata[4]} {axi4s_fmtr_tdata[5]} {axi4s_fmtr_tdata[6]} {axi4s_fmtr_tdata[7]} {axi4s_fmtr_tdata[8]} {axi4s_fmtr_tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list axi4s_csi2_tlast]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list axi4s_csi2_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list axi4s_csi2_tuser]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list axi4s_csi2_tvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list axi4s_fmtr_tlast]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list axi4s_fmtr_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list axi4s_fmtr_tuser]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list axi4s_fmtr_tvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list init_done]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list i_mipi_dphy_cam/inst/inst/mipi_dphy_cam_rx_support_i/slave_rx.mipi_dphy_cam_rx_ioi_i/div4_clk_out]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 8 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {dl0_rxdatahs[0]} {dl0_rxdatahs[1]} {dl0_rxdatahs[2]} {dl0_rxdatahs[3]} {dl0_rxdatahs[4]} {dl0_rxdatahs[5]} {dl0_rxdatahs[6]} {dl0_rxdatahs[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 8 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {dl0_rxdatahs_exp[0]} {dl0_rxdatahs_exp[1]} {dl0_rxdatahs_exp[2]} {dl0_rxdatahs_exp[3]} {dl0_rxdatahs_exp[4]} {dl0_rxdatahs_exp[5]} {dl0_rxdatahs_exp[6]} {dl0_rxdatahs_exp[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 8 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {dl1_rxdatahs[0]} {dl1_rxdatahs[1]} {dl1_rxdatahs[2]} {dl1_rxdatahs[3]} {dl1_rxdatahs[4]} {dl1_rxdatahs[5]} {dl1_rxdatahs[6]} {dl1_rxdatahs[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 8 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {dl1_rxdatahs_exp[0]} {dl1_rxdatahs_exp[1]} {dl1_rxdatahs_exp[2]} {dl1_rxdatahs_exp[3]} {dl1_rxdatahs_exp[4]} {dl1_rxdatahs_exp[5]} {dl1_rxdatahs_exp[6]} {dl1_rxdatahs_exp[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 1 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list dl0_check_ng]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 1 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list dl0_rxactivehs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 1 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list dl0_rxsynchs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
set_property port_width 1 [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list dl0_rxvalidhs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe8]
set_property port_width 1 [get_debug_ports u_ila_1/probe8]
connect_debug_port u_ila_1/probe8 [get_nets [list dl1_check_ng]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe9]
set_property port_width 1 [get_debug_ports u_ila_1/probe9]
connect_debug_port u_ila_1/probe9 [get_nets [list dl1_rxactivehs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe10]
set_property port_width 1 [get_debug_ports u_ila_1/probe10]
connect_debug_port u_ila_1/probe10 [get_nets [list dl1_rxsynchs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe11]
set_property port_width 1 [get_debug_ports u_ila_1/probe11]
connect_debug_port u_ila_1/probe11 [get_nets [list dl1_rxvalidhs]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets dphy_clk]
