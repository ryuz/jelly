



connect_debug_port u_ila_1/probe5 [get_nets [list {fifo_dl0_rxdatahs[0]} {fifo_dl0_rxdatahs[1]} {fifo_dl0_rxdatahs[2]} {fifo_dl0_rxdatahs[3]} {fifo_dl0_rxdatahs[4]} {fifo_dl0_rxdatahs[5]} {fifo_dl0_rxdatahs[6]} {fifo_dl0_rxdatahs[7]}]]
connect_debug_port u_ila_1/probe6 [get_nets [list {fifo_dl1_rxdatahs[0]} {fifo_dl1_rxdatahs[1]} {fifo_dl1_rxdatahs[2]} {fifo_dl1_rxdatahs[3]} {fifo_dl1_rxdatahs[4]} {fifo_dl1_rxdatahs[5]} {fifo_dl1_rxdatahs[6]} {fifo_dl1_rxdatahs[7]}]]
connect_debug_port u_ila_1/probe39 [get_nets [list fifo_dl0_errsoths]]
connect_debug_port u_ila_1/probe40 [get_nets [list fifo_dl0_errsotsynchs]]
connect_debug_port u_ila_1/probe41 [get_nets [list fifo_dl0_rxactivehs]]
connect_debug_port u_ila_1/probe42 [get_nets [list fifo_dl0_rxsynchs]]
connect_debug_port u_ila_1/probe43 [get_nets [list fifo_dl0_rxvalidhs]]
connect_debug_port u_ila_1/probe44 [get_nets [list fifo_dl1_errsoths]]
connect_debug_port u_ila_1/probe45 [get_nets [list fifo_dl1_errsotsynchs]]
connect_debug_port u_ila_1/probe46 [get_nets [list fifo_dl1_rxactivehs]]
connect_debug_port u_ila_1/probe47 [get_nets [list fifo_dl1_rxsynchs]]
connect_debug_port u_ila_1/probe48 [get_nets [list fifo_dl1_rxvalidhs]]
connect_debug_port u_ila_1/probe49 [get_nets [list fifo_valid]]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 4 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/processing_system7_0/inst/FCLK_CLK0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {axi4_mem0_awlen[0]} {axi4_mem0_awlen[1]} {axi4_mem0_awlen[2]} {axi4_mem0_awlen[3]} {axi4_mem0_awlen[4]} {axi4_mem0_awlen[5]} {axi4_mem0_awlen[6]} {axi4_mem0_awlen[7]}]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 4 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list i_design_1/clk_wiz_0/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 10 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {axi4s_csi2_tdata[0]} {axi4s_csi2_tdata[1]} {axi4s_csi2_tdata[2]} {axi4s_csi2_tdata[3]} {axi4s_csi2_tdata[4]} {axi4s_csi2_tdata[5]} {axi4s_csi2_tdata[6]} {axi4s_csi2_tdata[7]} {axi4s_csi2_tdata[8]} {axi4s_csi2_tdata[9]}]]
create_debug_core u_ila_2 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_2]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_2]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_2]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_2]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_2]
set_property C_INPUT_PIPE_STAGES 4 [get_debug_cores u_ila_2]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_2]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_2]
set_property port_width 1 [get_debug_ports u_ila_2/clk]
connect_debug_port u_ila_2/clk [get_nets [list i_mipi_dphy_cam/inst/mipi_dphy_cam_rx_support_i/slave_rx.mipi_dphy_cam_rx_ioi_i/div4_clk_out]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe0]
set_property port_width 32 [get_debug_ports u_ila_2/probe0]
connect_debug_port u_ila_2/probe0 [get_nets [list {dbg_dl0_count[0]} {dbg_dl0_count[1]} {dbg_dl0_count[2]} {dbg_dl0_count[3]} {dbg_dl0_count[4]} {dbg_dl0_count[5]} {dbg_dl0_count[6]} {dbg_dl0_count[7]} {dbg_dl0_count[8]} {dbg_dl0_count[9]} {dbg_dl0_count[10]} {dbg_dl0_count[11]} {dbg_dl0_count[12]} {dbg_dl0_count[13]} {dbg_dl0_count[14]} {dbg_dl0_count[15]} {dbg_dl0_count[16]} {dbg_dl0_count[17]} {dbg_dl0_count[18]} {dbg_dl0_count[19]} {dbg_dl0_count[20]} {dbg_dl0_count[21]} {dbg_dl0_count[22]} {dbg_dl0_count[23]} {dbg_dl0_count[24]} {dbg_dl0_count[25]} {dbg_dl0_count[26]} {dbg_dl0_count[27]} {dbg_dl0_count[28]} {dbg_dl0_count[29]} {dbg_dl0_count[30]} {dbg_dl0_count[31]}]]
create_debug_core u_ila_3 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_3]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_3]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_3]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_3]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_3]
set_property C_INPUT_PIPE_STAGES 4 [get_debug_cores u_ila_3]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_3]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_3]
set_property port_width 1 [get_debug_ports u_ila_3/clk]
connect_debug_port u_ila_3/clk [get_nets [list i_design_1/processing_system7_0/inst/FCLK_CLK1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe0]
set_property port_width 30 [get_debug_ports u_ila_3/probe0]
connect_debug_port u_ila_3/probe0 [get_nets [list {wb_host_adr_o[0]} {wb_host_adr_o[1]} {wb_host_adr_o[2]} {wb_host_adr_o[3]} {wb_host_adr_o[4]} {wb_host_adr_o[5]} {wb_host_adr_o[6]} {wb_host_adr_o[7]} {wb_host_adr_o[8]} {wb_host_adr_o[9]} {wb_host_adr_o[10]} {wb_host_adr_o[11]} {wb_host_adr_o[12]} {wb_host_adr_o[13]} {wb_host_adr_o[14]} {wb_host_adr_o[15]} {wb_host_adr_o[16]} {wb_host_adr_o[17]} {wb_host_adr_o[18]} {wb_host_adr_o[19]} {wb_host_adr_o[20]} {wb_host_adr_o[21]} {wb_host_adr_o[22]} {wb_host_adr_o[23]} {wb_host_adr_o[24]} {wb_host_adr_o[25]} {wb_host_adr_o[26]} {wb_host_adr_o[27]} {wb_host_adr_o[28]} {wb_host_adr_o[29]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 64 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi4_mem0_wdata[0]} {axi4_mem0_wdata[1]} {axi4_mem0_wdata[2]} {axi4_mem0_wdata[3]} {axi4_mem0_wdata[4]} {axi4_mem0_wdata[5]} {axi4_mem0_wdata[6]} {axi4_mem0_wdata[7]} {axi4_mem0_wdata[8]} {axi4_mem0_wdata[9]} {axi4_mem0_wdata[10]} {axi4_mem0_wdata[11]} {axi4_mem0_wdata[12]} {axi4_mem0_wdata[13]} {axi4_mem0_wdata[14]} {axi4_mem0_wdata[15]} {axi4_mem0_wdata[16]} {axi4_mem0_wdata[17]} {axi4_mem0_wdata[18]} {axi4_mem0_wdata[19]} {axi4_mem0_wdata[20]} {axi4_mem0_wdata[21]} {axi4_mem0_wdata[22]} {axi4_mem0_wdata[23]} {axi4_mem0_wdata[24]} {axi4_mem0_wdata[25]} {axi4_mem0_wdata[26]} {axi4_mem0_wdata[27]} {axi4_mem0_wdata[28]} {axi4_mem0_wdata[29]} {axi4_mem0_wdata[30]} {axi4_mem0_wdata[31]} {axi4_mem0_wdata[32]} {axi4_mem0_wdata[33]} {axi4_mem0_wdata[34]} {axi4_mem0_wdata[35]} {axi4_mem0_wdata[36]} {axi4_mem0_wdata[37]} {axi4_mem0_wdata[38]} {axi4_mem0_wdata[39]} {axi4_mem0_wdata[40]} {axi4_mem0_wdata[41]} {axi4_mem0_wdata[42]} {axi4_mem0_wdata[43]} {axi4_mem0_wdata[44]} {axi4_mem0_wdata[45]} {axi4_mem0_wdata[46]} {axi4_mem0_wdata[47]} {axi4_mem0_wdata[48]} {axi4_mem0_wdata[49]} {axi4_mem0_wdata[50]} {axi4_mem0_wdata[51]} {axi4_mem0_wdata[52]} {axi4_mem0_wdata[53]} {axi4_mem0_wdata[54]} {axi4_mem0_wdata[55]} {axi4_mem0_wdata[56]} {axi4_mem0_wdata[57]} {axi4_mem0_wdata[58]} {axi4_mem0_wdata[59]} {axi4_mem0_wdata[60]} {axi4_mem0_wdata[61]} {axi4_mem0_wdata[62]} {axi4_mem0_wdata[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 2 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {axi4_mem0_bresp[0]} {axi4_mem0_bresp[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 29 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {axi4_mem0_awaddr[3]} {axi4_mem0_awaddr[4]} {axi4_mem0_awaddr[5]} {axi4_mem0_awaddr[6]} {axi4_mem0_awaddr[7]} {axi4_mem0_awaddr[8]} {axi4_mem0_awaddr[9]} {axi4_mem0_awaddr[10]} {axi4_mem0_awaddr[11]} {axi4_mem0_awaddr[12]} {axi4_mem0_awaddr[13]} {axi4_mem0_awaddr[14]} {axi4_mem0_awaddr[15]} {axi4_mem0_awaddr[16]} {axi4_mem0_awaddr[17]} {axi4_mem0_awaddr[18]} {axi4_mem0_awaddr[19]} {axi4_mem0_awaddr[20]} {axi4_mem0_awaddr[21]} {axi4_mem0_awaddr[22]} {axi4_mem0_awaddr[23]} {axi4_mem0_awaddr[24]} {axi4_mem0_awaddr[25]} {axi4_mem0_awaddr[26]} {axi4_mem0_awaddr[27]} {axi4_mem0_awaddr[28]} {axi4_mem0_awaddr[29]} {axi4_mem0_awaddr[30]} {axi4_mem0_awaddr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 6 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {axi4_mem0_bid[0]} {axi4_mem0_bid[1]} {axi4_mem0_bid[2]} {axi4_mem0_bid[3]} {axi4_mem0_bid[4]} {axi4_mem0_bid[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list axi4_mem0_awready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list axi4_mem0_awvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list axi4_mem0_bvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list axi4_mem0_wlast]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list axi4_mem0_wready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list axi4_mem0_wvalid]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 4 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {dl1_rxtriggeresc[0]} {dl1_rxtriggeresc[1]} {dl1_rxtriggeresc[2]} {dl1_rxtriggeresc[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 4 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {dl0_rxtriggeresc[0]} {dl0_rxtriggeresc[1]} {dl0_rxtriggeresc[2]} {dl0_rxtriggeresc[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 8 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {dl0_rxdataesc[0]} {dl0_rxdataesc[1]} {dl0_rxdataesc[2]} {dl0_rxdataesc[3]} {dl0_rxdataesc[4]} {dl0_rxdataesc[5]} {dl0_rxdataesc[6]} {dl0_rxdataesc[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 10 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {axi4s_memw_tdata[0]} {axi4s_memw_tdata[1]} {axi4s_memw_tdata[2]} {axi4s_memw_tdata[3]} {axi4s_memw_tdata[4]} {axi4s_memw_tdata[5]} {axi4s_memw_tdata[6]} {axi4s_memw_tdata[7]} {axi4s_memw_tdata[8]} {axi4s_memw_tdata[9]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 8 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list {dl1_rxdataesc[0]} {dl1_rxdataesc[1]} {dl1_rxdataesc[2]} {dl1_rxdataesc[3]} {dl1_rxdataesc[4]} {dl1_rxdataesc[5]} {dl1_rxdataesc[6]} {dl1_rxdataesc[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 1 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list axi4s_csi2_tlast]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
set_property port_width 1 [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list axi4s_csi2_tready]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe8]
set_property port_width 1 [get_debug_ports u_ila_1/probe8]
connect_debug_port u_ila_1/probe8 [get_nets [list axi4s_csi2_tuser]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe9]
set_property port_width 1 [get_debug_ports u_ila_1/probe9]
connect_debug_port u_ila_1/probe9 [get_nets [list axi4s_csi2_tvalid]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe10]
set_property port_width 1 [get_debug_ports u_ila_1/probe10]
connect_debug_port u_ila_1/probe10 [get_nets [list axi4s_memw_tlast]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe11]
set_property port_width 1 [get_debug_ports u_ila_1/probe11]
connect_debug_port u_ila_1/probe11 [get_nets [list axi4s_memw_tready]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe12]
set_property port_width 1 [get_debug_ports u_ila_1/probe12]
connect_debug_port u_ila_1/probe12 [get_nets [list axi4s_memw_tuser]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe13]
set_property port_width 1 [get_debug_ports u_ila_1/probe13]
connect_debug_port u_ila_1/probe13 [get_nets [list axi4s_memw_tvalid]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe14]
set_property port_width 1 [get_debug_ports u_ila_1/probe14]
connect_debug_port u_ila_1/probe14 [get_nets [list cl_enable]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe15]
set_property port_width 1 [get_debug_ports u_ila_1/probe15]
connect_debug_port u_ila_1/probe15 [get_nets [list cl_rxclkactivehs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe16]
set_property port_width 1 [get_debug_ports u_ila_1/probe16]
connect_debug_port u_ila_1/probe16 [get_nets [list cl_rxulpsclknot]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe17]
set_property port_width 1 [get_debug_ports u_ila_1/probe17]
connect_debug_port u_ila_1/probe17 [get_nets [list cl_stopstate]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe18]
set_property port_width 1 [get_debug_ports u_ila_1/probe18]
connect_debug_port u_ila_1/probe18 [get_nets [list cl_ulpsactivenot]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe19]
set_property port_width 1 [get_debug_ports u_ila_1/probe19]
connect_debug_port u_ila_1/probe19 [get_nets [list dl0_enable]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe20]
set_property port_width 1 [get_debug_ports u_ila_1/probe20]
connect_debug_port u_ila_1/probe20 [get_nets [list dl0_errcontrol]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe21]
set_property port_width 1 [get_debug_ports u_ila_1/probe21]
connect_debug_port u_ila_1/probe21 [get_nets [list dl0_erresc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe22]
set_property port_width 1 [get_debug_ports u_ila_1/probe22]
connect_debug_port u_ila_1/probe22 [get_nets [list dl0_errsyncesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe23]
set_property port_width 1 [get_debug_ports u_ila_1/probe23]
connect_debug_port u_ila_1/probe23 [get_nets [list dl0_forcerxmode]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe24]
set_property port_width 1 [get_debug_ports u_ila_1/probe24]
connect_debug_port u_ila_1/probe24 [get_nets [list dl0_rxclkesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe25]
set_property port_width 1 [get_debug_ports u_ila_1/probe25]
connect_debug_port u_ila_1/probe25 [get_nets [list dl0_rxlpdtesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe26]
set_property port_width 1 [get_debug_ports u_ila_1/probe26]
connect_debug_port u_ila_1/probe26 [get_nets [list dl0_rxulpsesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe27]
set_property port_width 1 [get_debug_ports u_ila_1/probe27]
connect_debug_port u_ila_1/probe27 [get_nets [list dl0_rxvalidesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe28]
set_property port_width 1 [get_debug_ports u_ila_1/probe28]
connect_debug_port u_ila_1/probe28 [get_nets [list dl0_stopstate]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe29]
set_property port_width 1 [get_debug_ports u_ila_1/probe29]
connect_debug_port u_ila_1/probe29 [get_nets [list dl0_ulpsactivenot]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe30]
set_property port_width 1 [get_debug_ports u_ila_1/probe30]
connect_debug_port u_ila_1/probe30 [get_nets [list dl1_enable]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe31]
set_property port_width 1 [get_debug_ports u_ila_1/probe31]
connect_debug_port u_ila_1/probe31 [get_nets [list dl1_errcontrol]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe32]
set_property port_width 1 [get_debug_ports u_ila_1/probe32]
connect_debug_port u_ila_1/probe32 [get_nets [list dl1_erresc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe33]
set_property port_width 1 [get_debug_ports u_ila_1/probe33]
connect_debug_port u_ila_1/probe33 [get_nets [list dl1_errsyncesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe34]
set_property port_width 1 [get_debug_ports u_ila_1/probe34]
connect_debug_port u_ila_1/probe34 [get_nets [list dl1_forcerxmode]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe35]
set_property port_width 1 [get_debug_ports u_ila_1/probe35]
connect_debug_port u_ila_1/probe35 [get_nets [list dl1_rxclkesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe36]
set_property port_width 1 [get_debug_ports u_ila_1/probe36]
connect_debug_port u_ila_1/probe36 [get_nets [list dl1_rxlpdtesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe37]
set_property port_width 1 [get_debug_ports u_ila_1/probe37]
connect_debug_port u_ila_1/probe37 [get_nets [list dl1_rxulpsesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe38]
set_property port_width 1 [get_debug_ports u_ila_1/probe38]
connect_debug_port u_ila_1/probe38 [get_nets [list dl1_rxvalidesc]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe39]
set_property port_width 1 [get_debug_ports u_ila_1/probe39]
connect_debug_port u_ila_1/probe39 [get_nets [list dl1_stopstate]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe40]
set_property port_width 1 [get_debug_ports u_ila_1/probe40]
connect_debug_port u_ila_1/probe40 [get_nets [list dl1_ulpsactivenot]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe41]
set_property port_width 1 [get_debug_ports u_ila_1/probe41]
connect_debug_port u_ila_1/probe41 [get_nets [list dphy_reset]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe42]
set_property port_width 1 [get_debug_ports u_ila_1/probe42]
connect_debug_port u_ila_1/probe42 [get_nets [list init_done]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe43]
set_property port_width 1 [get_debug_ports u_ila_1/probe43]
connect_debug_port u_ila_1/probe43 [get_nets [list system_rst_out]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe1]
set_property port_width 8 [get_debug_ports u_ila_2/probe1]
connect_debug_port u_ila_2/probe1 [get_nets [list {dl0_rxdatahs[0]} {dl0_rxdatahs[1]} {dl0_rxdatahs[2]} {dl0_rxdatahs[3]} {dl0_rxdatahs[4]} {dl0_rxdatahs[5]} {dl0_rxdatahs[6]} {dl0_rxdatahs[7]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe2]
set_property port_width 8 [get_debug_ports u_ila_2/probe2]
connect_debug_port u_ila_2/probe2 [get_nets [list {dl1_rxdatahs[0]} {dl1_rxdatahs[1]} {dl1_rxdatahs[2]} {dl1_rxdatahs[3]} {dl1_rxdatahs[4]} {dl1_rxdatahs[5]} {dl1_rxdatahs[6]} {dl1_rxdatahs[7]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe3]
set_property port_width 32 [get_debug_ports u_ila_2/probe3]
connect_debug_port u_ila_2/probe3 [get_nets [list {dbg_dl1_count[0]} {dbg_dl1_count[1]} {dbg_dl1_count[2]} {dbg_dl1_count[3]} {dbg_dl1_count[4]} {dbg_dl1_count[5]} {dbg_dl1_count[6]} {dbg_dl1_count[7]} {dbg_dl1_count[8]} {dbg_dl1_count[9]} {dbg_dl1_count[10]} {dbg_dl1_count[11]} {dbg_dl1_count[12]} {dbg_dl1_count[13]} {dbg_dl1_count[14]} {dbg_dl1_count[15]} {dbg_dl1_count[16]} {dbg_dl1_count[17]} {dbg_dl1_count[18]} {dbg_dl1_count[19]} {dbg_dl1_count[20]} {dbg_dl1_count[21]} {dbg_dl1_count[22]} {dbg_dl1_count[23]} {dbg_dl1_count[24]} {dbg_dl1_count[25]} {dbg_dl1_count[26]} {dbg_dl1_count[27]} {dbg_dl1_count[28]} {dbg_dl1_count[29]} {dbg_dl1_count[30]} {dbg_dl1_count[31]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe4]
set_property port_width 1 [get_debug_ports u_ila_2/probe4]
connect_debug_port u_ila_2/probe4 [get_nets [list dl0_errsoths]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe5]
set_property port_width 1 [get_debug_ports u_ila_2/probe5]
connect_debug_port u_ila_2/probe5 [get_nets [list dl0_errsotsynchs]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe6]
set_property port_width 1 [get_debug_ports u_ila_2/probe6]
connect_debug_port u_ila_2/probe6 [get_nets [list dl0_rxactivehs]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe7]
set_property port_width 1 [get_debug_ports u_ila_2/probe7]
connect_debug_port u_ila_2/probe7 [get_nets [list dl0_rxsynchs]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe8]
set_property port_width 1 [get_debug_ports u_ila_2/probe8]
connect_debug_port u_ila_2/probe8 [get_nets [list dl0_rxvalidhs]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe9]
set_property port_width 1 [get_debug_ports u_ila_2/probe9]
connect_debug_port u_ila_2/probe9 [get_nets [list dl1_errsoths]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe10]
set_property port_width 1 [get_debug_ports u_ila_2/probe10]
connect_debug_port u_ila_2/probe10 [get_nets [list dl1_errsotsynchs]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe11]
set_property port_width 1 [get_debug_ports u_ila_2/probe11]
connect_debug_port u_ila_2/probe11 [get_nets [list dl1_rxactivehs]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe12]
set_property port_width 1 [get_debug_ports u_ila_2/probe12]
connect_debug_port u_ila_2/probe12 [get_nets [list dl1_rxsynchs]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe13]
set_property port_width 1 [get_debug_ports u_ila_2/probe13]
connect_debug_port u_ila_2/probe13 [get_nets [list dl1_rxvalidhs]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe1]
set_property port_width 32 [get_debug_ports u_ila_3/probe1]
connect_debug_port u_ila_3/probe1 [get_nets [list {wb_host_dat_i[0]} {wb_host_dat_i[1]} {wb_host_dat_i[2]} {wb_host_dat_i[3]} {wb_host_dat_i[4]} {wb_host_dat_i[5]} {wb_host_dat_i[6]} {wb_host_dat_i[7]} {wb_host_dat_i[8]} {wb_host_dat_i[9]} {wb_host_dat_i[10]} {wb_host_dat_i[11]} {wb_host_dat_i[12]} {wb_host_dat_i[13]} {wb_host_dat_i[14]} {wb_host_dat_i[15]} {wb_host_dat_i[16]} {wb_host_dat_i[17]} {wb_host_dat_i[18]} {wb_host_dat_i[19]} {wb_host_dat_i[20]} {wb_host_dat_i[21]} {wb_host_dat_i[22]} {wb_host_dat_i[23]} {wb_host_dat_i[24]} {wb_host_dat_i[25]} {wb_host_dat_i[26]} {wb_host_dat_i[27]} {wb_host_dat_i[28]} {wb_host_dat_i[29]} {wb_host_dat_i[30]} {wb_host_dat_i[31]}]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe2]
set_property port_width 4 [get_debug_ports u_ila_3/probe2]
connect_debug_port u_ila_3/probe2 [get_nets [list {wb_host_sel_o[0]} {wb_host_sel_o[1]} {wb_host_sel_o[2]} {wb_host_sel_o[3]}]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe3]
set_property port_width 32 [get_debug_ports u_ila_3/probe3]
connect_debug_port u_ila_3/probe3 [get_nets [list {wb_host_dat_o[0]} {wb_host_dat_o[1]} {wb_host_dat_o[2]} {wb_host_dat_o[3]} {wb_host_dat_o[4]} {wb_host_dat_o[5]} {wb_host_dat_o[6]} {wb_host_dat_o[7]} {wb_host_dat_o[8]} {wb_host_dat_o[9]} {wb_host_dat_o[10]} {wb_host_dat_o[11]} {wb_host_dat_o[12]} {wb_host_dat_o[13]} {wb_host_dat_o[14]} {wb_host_dat_o[15]} {wb_host_dat_o[16]} {wb_host_dat_o[17]} {wb_host_dat_o[18]} {wb_host_dat_o[19]} {wb_host_dat_o[20]} {wb_host_dat_o[21]} {wb_host_dat_o[22]} {wb_host_dat_o[23]} {wb_host_dat_o[24]} {wb_host_dat_o[25]} {wb_host_dat_o[26]} {wb_host_dat_o[27]} {wb_host_dat_o[28]} {wb_host_dat_o[29]} {wb_host_dat_o[30]} {wb_host_dat_o[31]}]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe4]
set_property port_width 32 [get_debug_ports u_ila_3/probe4]
connect_debug_port u_ila_3/probe4 [get_nets [list {wb_vdmaw_dat_o[0]} {wb_vdmaw_dat_o[1]} {wb_vdmaw_dat_o[2]} {wb_vdmaw_dat_o[3]} {wb_vdmaw_dat_o[4]} {wb_vdmaw_dat_o[5]} {wb_vdmaw_dat_o[6]} {wb_vdmaw_dat_o[7]} {wb_vdmaw_dat_o[8]} {wb_vdmaw_dat_o[9]} {wb_vdmaw_dat_o[10]} {wb_vdmaw_dat_o[11]} {wb_vdmaw_dat_o[12]} {wb_vdmaw_dat_o[13]} {wb_vdmaw_dat_o[14]} {wb_vdmaw_dat_o[15]} {wb_vdmaw_dat_o[16]} {wb_vdmaw_dat_o[17]} {wb_vdmaw_dat_o[18]} {wb_vdmaw_dat_o[19]} {wb_vdmaw_dat_o[20]} {wb_vdmaw_dat_o[21]} {wb_vdmaw_dat_o[22]} {wb_vdmaw_dat_o[23]} {wb_vdmaw_dat_o[24]} {wb_vdmaw_dat_o[25]} {wb_vdmaw_dat_o[26]} {wb_vdmaw_dat_o[27]} {wb_vdmaw_dat_o[28]} {wb_vdmaw_dat_o[29]} {wb_vdmaw_dat_o[30]} {wb_vdmaw_dat_o[31]}]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe5]
set_property port_width 1 [get_debug_ports u_ila_3/probe5]
connect_debug_port u_ila_3/probe5 [get_nets [list axi4_mem_aresetn]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe6]
set_property port_width 1 [get_debug_ports u_ila_3/probe6]
connect_debug_port u_ila_3/probe6 [get_nets [list wb_host_ack_i]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe7]
set_property port_width 1 [get_debug_ports u_ila_3/probe7]
connect_debug_port u_ila_3/probe7 [get_nets [list wb_host_stb_o]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe8]
set_property port_width 1 [get_debug_ports u_ila_3/probe8]
connect_debug_port u_ila_3/probe8 [get_nets [list wb_host_we_o]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe9]
set_property port_width 1 [get_debug_ports u_ila_3/probe9]
connect_debug_port u_ila_3/probe9 [get_nets [list wb_vdmaw_ack_o]]
create_debug_port u_ila_3 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_3/probe10]
set_property port_width 1 [get_debug_ports u_ila_3/probe10]
connect_debug_port u_ila_3/probe10 [get_nets [list wb_vdmaw_stb_i]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk200]
