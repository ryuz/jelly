
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/clk_wiz_0/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_axi4s_debug_monitor/dbg_width[0]} {i_axi4s_debug_monitor/dbg_width[1]} {i_axi4s_debug_monitor/dbg_width[2]} {i_axi4s_debug_monitor/dbg_width[3]} {i_axi4s_debug_monitor/dbg_width[4]} {i_axi4s_debug_monitor/dbg_width[5]} {i_axi4s_debug_monitor/dbg_width[6]} {i_axi4s_debug_monitor/dbg_width[7]} {i_axi4s_debug_monitor/dbg_width[8]} {i_axi4s_debug_monitor/dbg_width[9]} {i_axi4s_debug_monitor/dbg_width[10]} {i_axi4s_debug_monitor/dbg_width[11]} {i_axi4s_debug_monitor/dbg_width[12]} {i_axi4s_debug_monitor/dbg_width[13]} {i_axi4s_debug_monitor/dbg_width[14]} {i_axi4s_debug_monitor/dbg_width[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_axi4s_debug_monitor/dbg_pixel[0]} {i_axi4s_debug_monitor/dbg_pixel[1]} {i_axi4s_debug_monitor/dbg_pixel[2]} {i_axi4s_debug_monitor/dbg_pixel[3]} {i_axi4s_debug_monitor/dbg_pixel[4]} {i_axi4s_debug_monitor/dbg_pixel[5]} {i_axi4s_debug_monitor/dbg_pixel[6]} {i_axi4s_debug_monitor/dbg_pixel[7]} {i_axi4s_debug_monitor/dbg_pixel[8]} {i_axi4s_debug_monitor/dbg_pixel[9]} {i_axi4s_debug_monitor/dbg_pixel[10]} {i_axi4s_debug_monitor/dbg_pixel[11]} {i_axi4s_debug_monitor/dbg_pixel[12]} {i_axi4s_debug_monitor/dbg_pixel[13]} {i_axi4s_debug_monitor/dbg_pixel[14]} {i_axi4s_debug_monitor/dbg_pixel[15]} {i_axi4s_debug_monitor/dbg_pixel[16]} {i_axi4s_debug_monitor/dbg_pixel[17]} {i_axi4s_debug_monitor/dbg_pixel[18]} {i_axi4s_debug_monitor/dbg_pixel[19]} {i_axi4s_debug_monitor/dbg_pixel[20]} {i_axi4s_debug_monitor/dbg_pixel[21]} {i_axi4s_debug_monitor/dbg_pixel[22]} {i_axi4s_debug_monitor/dbg_pixel[23]} {i_axi4s_debug_monitor/dbg_pixel[24]} {i_axi4s_debug_monitor/dbg_pixel[25]} {i_axi4s_debug_monitor/dbg_pixel[26]} {i_axi4s_debug_monitor/dbg_pixel[27]} {i_axi4s_debug_monitor/dbg_pixel[28]} {i_axi4s_debug_monitor/dbg_pixel[29]} {i_axi4s_debug_monitor/dbg_pixel[30]} {i_axi4s_debug_monitor/dbg_pixel[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_axi4s_debug_monitor/dbg_frame[0]} {i_axi4s_debug_monitor/dbg_frame[1]} {i_axi4s_debug_monitor/dbg_frame[2]} {i_axi4s_debug_monitor/dbg_frame[3]} {i_axi4s_debug_monitor/dbg_frame[4]} {i_axi4s_debug_monitor/dbg_frame[5]} {i_axi4s_debug_monitor/dbg_frame[6]} {i_axi4s_debug_monitor/dbg_frame[7]} {i_axi4s_debug_monitor/dbg_frame[8]} {i_axi4s_debug_monitor/dbg_frame[9]} {i_axi4s_debug_monitor/dbg_frame[10]} {i_axi4s_debug_monitor/dbg_frame[11]} {i_axi4s_debug_monitor/dbg_frame[12]} {i_axi4s_debug_monitor/dbg_frame[13]} {i_axi4s_debug_monitor/dbg_frame[14]} {i_axi4s_debug_monitor/dbg_frame[15]} {i_axi4s_debug_monitor/dbg_frame[16]} {i_axi4s_debug_monitor/dbg_frame[17]} {i_axi4s_debug_monitor/dbg_frame[18]} {i_axi4s_debug_monitor/dbg_frame[19]} {i_axi4s_debug_monitor/dbg_frame[20]} {i_axi4s_debug_monitor/dbg_frame[21]} {i_axi4s_debug_monitor/dbg_frame[22]} {i_axi4s_debug_monitor/dbg_frame[23]} {i_axi4s_debug_monitor/dbg_frame[24]} {i_axi4s_debug_monitor/dbg_frame[25]} {i_axi4s_debug_monitor/dbg_frame[26]} {i_axi4s_debug_monitor/dbg_frame[27]} {i_axi4s_debug_monitor/dbg_frame[28]} {i_axi4s_debug_monitor/dbg_frame[29]} {i_axi4s_debug_monitor/dbg_frame[30]} {i_axi4s_debug_monitor/dbg_frame[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_axi4s_debug_monitor/dbg_timer[0]} {i_axi4s_debug_monitor/dbg_timer[1]} {i_axi4s_debug_monitor/dbg_timer[2]} {i_axi4s_debug_monitor/dbg_timer[3]} {i_axi4s_debug_monitor/dbg_timer[4]} {i_axi4s_debug_monitor/dbg_timer[5]} {i_axi4s_debug_monitor/dbg_timer[6]} {i_axi4s_debug_monitor/dbg_timer[7]} {i_axi4s_debug_monitor/dbg_timer[8]} {i_axi4s_debug_monitor/dbg_timer[9]} {i_axi4s_debug_monitor/dbg_timer[10]} {i_axi4s_debug_monitor/dbg_timer[11]} {i_axi4s_debug_monitor/dbg_timer[12]} {i_axi4s_debug_monitor/dbg_timer[13]} {i_axi4s_debug_monitor/dbg_timer[14]} {i_axi4s_debug_monitor/dbg_timer[15]} {i_axi4s_debug_monitor/dbg_timer[16]} {i_axi4s_debug_monitor/dbg_timer[17]} {i_axi4s_debug_monitor/dbg_timer[18]} {i_axi4s_debug_monitor/dbg_timer[19]} {i_axi4s_debug_monitor/dbg_timer[20]} {i_axi4s_debug_monitor/dbg_timer[21]} {i_axi4s_debug_monitor/dbg_timer[22]} {i_axi4s_debug_monitor/dbg_timer[23]} {i_axi4s_debug_monitor/dbg_timer[24]} {i_axi4s_debug_monitor/dbg_timer[25]} {i_axi4s_debug_monitor/dbg_timer[26]} {i_axi4s_debug_monitor/dbg_timer[27]} {i_axi4s_debug_monitor/dbg_timer[28]} {i_axi4s_debug_monitor/dbg_timer[29]} {i_axi4s_debug_monitor/dbg_timer[30]} {i_axi4s_debug_monitor/dbg_timer[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_axi4s_debug_monitor/dbg_height[0]} {i_axi4s_debug_monitor/dbg_height[1]} {i_axi4s_debug_monitor/dbg_height[2]} {i_axi4s_debug_monitor/dbg_height[3]} {i_axi4s_debug_monitor/dbg_height[4]} {i_axi4s_debug_monitor/dbg_height[5]} {i_axi4s_debug_monitor/dbg_height[6]} {i_axi4s_debug_monitor/dbg_height[7]} {i_axi4s_debug_monitor/dbg_height[8]} {i_axi4s_debug_monitor/dbg_height[9]} {i_axi4s_debug_monitor/dbg_height[10]} {i_axi4s_debug_monitor/dbg_height[11]} {i_axi4s_debug_monitor/dbg_height[12]} {i_axi4s_debug_monitor/dbg_height[13]} {i_axi4s_debug_monitor/dbg_height[14]} {i_axi4s_debug_monitor/dbg_height[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 16 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {i_axi4s_debug_monitor/dbg_x[0]} {i_axi4s_debug_monitor/dbg_x[1]} {i_axi4s_debug_monitor/dbg_x[2]} {i_axi4s_debug_monitor/dbg_x[3]} {i_axi4s_debug_monitor/dbg_x[4]} {i_axi4s_debug_monitor/dbg_x[5]} {i_axi4s_debug_monitor/dbg_x[6]} {i_axi4s_debug_monitor/dbg_x[7]} {i_axi4s_debug_monitor/dbg_x[8]} {i_axi4s_debug_monitor/dbg_x[9]} {i_axi4s_debug_monitor/dbg_x[10]} {i_axi4s_debug_monitor/dbg_x[11]} {i_axi4s_debug_monitor/dbg_x[12]} {i_axi4s_debug_monitor/dbg_x[13]} {i_axi4s_debug_monitor/dbg_x[14]} {i_axi4s_debug_monitor/dbg_x[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 16 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {i_axi4s_debug_monitor/dbg_y[0]} {i_axi4s_debug_monitor/dbg_y[1]} {i_axi4s_debug_monitor/dbg_y[2]} {i_axi4s_debug_monitor/dbg_y[3]} {i_axi4s_debug_monitor/dbg_y[4]} {i_axi4s_debug_monitor/dbg_y[5]} {i_axi4s_debug_monitor/dbg_y[6]} {i_axi4s_debug_monitor/dbg_y[7]} {i_axi4s_debug_monitor/dbg_y[8]} {i_axi4s_debug_monitor/dbg_y[9]} {i_axi4s_debug_monitor/dbg_y[10]} {i_axi4s_debug_monitor/dbg_y[11]} {i_axi4s_debug_monitor/dbg_y[12]} {i_axi4s_debug_monitor/dbg_y[13]} {i_axi4s_debug_monitor/dbg_y[14]} {i_axi4s_debug_monitor/dbg_y[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 10 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {i_axi4s_debug_monitor/dbg_axi4s_tdata[0]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[1]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[2]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[3]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[4]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[5]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[6]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[7]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[8]} {i_axi4s_debug_monitor/dbg_axi4s_tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 10 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {axi4s_csi2_tdata[0]} {axi4s_csi2_tdata[1]} {axi4s_csi2_tdata[2]} {axi4s_csi2_tdata[3]} {axi4s_csi2_tdata[4]} {axi4s_csi2_tdata[5]} {axi4s_csi2_tdata[6]} {axi4s_csi2_tdata[7]} {axi4s_csi2_tdata[8]} {axi4s_csi2_tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 8 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {dbg_dl1_rxdataesc[0]} {dbg_dl1_rxdataesc[1]} {dbg_dl1_rxdataesc[2]} {dbg_dl1_rxdataesc[3]} {dbg_dl1_rxdataesc[4]} {dbg_dl1_rxdataesc[5]} {dbg_dl1_rxdataesc[6]} {dbg_dl1_rxdataesc[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 8 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {dbg_dl0_rxdataesc[0]} {dbg_dl0_rxdataesc[1]} {dbg_dl0_rxdataesc[2]} {dbg_dl0_rxdataesc[3]} {dbg_dl0_rxdataesc[4]} {dbg_dl0_rxdataesc[5]} {dbg_dl0_rxdataesc[6]} {dbg_dl0_rxdataesc[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 8 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {dbg_dl1_rxdatahs[0]} {dbg_dl1_rxdatahs[1]} {dbg_dl1_rxdatahs[2]} {dbg_dl1_rxdatahs[3]} {dbg_dl1_rxdatahs[4]} {dbg_dl1_rxdatahs[5]} {dbg_dl1_rxdatahs[6]} {dbg_dl1_rxdatahs[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 8 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {dbg_dl0_rxdatahs[0]} {dbg_dl0_rxdatahs[1]} {dbg_dl0_rxdatahs[2]} {dbg_dl0_rxdatahs[3]} {dbg_dl0_rxdatahs[4]} {dbg_dl0_rxdatahs[5]} {dbg_dl0_rxdatahs[6]} {dbg_dl0_rxdatahs[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list axi4s_csi2_tlast]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list axi4s_csi2_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list axi4s_csi2_tuser]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list axi4s_csi2_tvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list i_axi4s_debug_monitor/dbg_axi4s_tlast]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list i_axi4s_debug_monitor/dbg_axi4s_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list i_axi4s_debug_monitor/dbg_axi4s_tuser]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list i_axi4s_debug_monitor/dbg_axi4s_tvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list dbg_cl_enable]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list dbg_cl_rxclkactivehs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 1 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list dbg_cl_rxulpsclknot]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 1 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list dbg_cl_stopstate]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 1 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list dbg_cl_ulpsactivenot]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 1 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list dbg_init_done]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 1 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list dbg_phy_reset]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 1 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list dbg_pll_lock_out]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
set_property port_width 1 [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list dbg_rxbyteclkhs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
set_property port_width 1 [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list dbg_sys_reset]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
set_property port_width 1 [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list dbg_system_rst_out]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list i_mipi_dphy_cam/inst/inst/mipi_dphy_cam_rx_support_i/rxbyteclkhs]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 8 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {dl0_rxdatahs[0]} {dl0_rxdatahs[1]} {dl0_rxdatahs[2]} {dl0_rxdatahs[3]} {dl0_rxdatahs[4]} {dl0_rxdatahs[5]} {dl0_rxdatahs[6]} {dl0_rxdatahs[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 1 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list dl0_rxactivehs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 1 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list dl0_rxsynchs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 1 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list dl0_rxvalidhs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 1 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {i_csi2_rx/i_csi2_rx_lane_merging/loop_lane[1].i_csi2_rx_lane_recv/reg_overfloaw}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 1 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list {i_csi2_rx/i_csi2_rx_lane_merging/loop_lane[0].i_csi2_rx_lane_recv/reg_overfloaw}]]
create_debug_core u_ila_2 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_2]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_2]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_2]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_2]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_2]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_2]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_2]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_2]
set_property port_width 1 [get_debug_ports u_ila_2/clk]
connect_debug_port u_ila_2/clk [get_nets [list i_design_1/clk_wiz_0/inst/clk_out3]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe0]
set_property port_width 8 [get_debug_ports u_ila_2/probe0]
connect_debug_port u_ila_2/probe0 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st0_ecc[0]} {i_csi2_rx/i_csi2_rx_low_layer/st0_ecc[1]} {i_csi2_rx/i_csi2_rx_low_layer/st0_ecc[2]} {i_csi2_rx/i_csi2_rx_low_layer/st0_ecc[3]} {i_csi2_rx/i_csi2_rx_low_layer/st0_ecc[4]} {i_csi2_rx/i_csi2_rx_low_layer/st0_ecc[5]} {i_csi2_rx/i_csi2_rx_low_layer/st0_ecc[6]} {i_csi2_rx/i_csi2_rx_low_layer/st0_ecc[7]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe1]
set_property port_width 16 [get_debug_ports u_ila_2/probe1]
connect_debug_port u_ila_2/probe1 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[0]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[1]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[2]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[3]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[4]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[5]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[6]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[7]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[8]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[9]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[10]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[11]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[12]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[13]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[14]} {i_csi2_rx/i_csi2_rx_low_layer/st1_wc[15]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe2]
set_property port_width 16 [get_debug_ports u_ila_2/probe2]
connect_debug_port u_ila_2/probe2 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[0]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[1]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[2]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[3]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[4]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[5]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[6]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[7]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[8]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[9]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[10]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[11]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[12]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[13]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[14]} {i_csi2_rx/i_csi2_rx_low_layer/st1_counter[15]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe3]
set_property port_width 8 [get_debug_ports u_ila_2/probe3]
connect_debug_port u_ila_2/probe3 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st0_id[0]} {i_csi2_rx/i_csi2_rx_low_layer/st0_id[1]} {i_csi2_rx/i_csi2_rx_low_layer/st0_id[2]} {i_csi2_rx/i_csi2_rx_low_layer/st0_id[3]} {i_csi2_rx/i_csi2_rx_low_layer/st0_id[4]} {i_csi2_rx/i_csi2_rx_low_layer/st0_id[5]} {i_csi2_rx/i_csi2_rx_low_layer/st0_id[6]} {i_csi2_rx/i_csi2_rx_low_layer/st0_id[7]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe4]
set_property port_width 16 [get_debug_ports u_ila_2/probe4]
connect_debug_port u_ila_2/probe4 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[0]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[1]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[2]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[3]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[4]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[5]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[6]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[7]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[8]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[9]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[10]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[11]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[12]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[13]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[14]} {i_csi2_rx/i_csi2_rx_low_layer/st0_wc[15]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe5]
set_property port_width 2 [get_debug_ports u_ila_2/probe5]
connect_debug_port u_ila_2/probe5 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st1_state[0]} {i_csi2_rx/i_csi2_rx_low_layer/st1_state[1]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe6]
set_property port_width 8 [get_debug_ports u_ila_2/probe6]
connect_debug_port u_ila_2/probe6 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st1_data[0]} {i_csi2_rx/i_csi2_rx_low_layer/st1_data[1]} {i_csi2_rx/i_csi2_rx_low_layer/st1_data[2]} {i_csi2_rx/i_csi2_rx_low_layer/st1_data[3]} {i_csi2_rx/i_csi2_rx_low_layer/st1_data[4]} {i_csi2_rx/i_csi2_rx_low_layer/st1_data[5]} {i_csi2_rx/i_csi2_rx_low_layer/st1_data[6]} {i_csi2_rx/i_csi2_rx_low_layer/st1_data[7]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe7]
set_property port_width 16 [get_debug_ports u_ila_2/probe7]
connect_debug_port u_ila_2/probe7 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[0]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[1]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[2]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[3]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[4]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[5]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[6]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[7]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[8]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[9]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[10]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[11]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[12]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[13]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[14]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc[15]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe8]
set_property port_width 16 [get_debug_ports u_ila_2/probe8]
connect_debug_port u_ila_2/probe8 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[0]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[1]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[2]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[3]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[4]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[5]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[6]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[7]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[8]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[9]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[10]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[11]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[12]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[13]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[14]} {i_csi2_rx/i_csi2_rx_low_layer/st1_crc_sum[15]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe9]
set_property port_width 3 [get_debug_ports u_ila_2/probe9]
connect_debug_port u_ila_2/probe9 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st0_state[0]} {i_csi2_rx/i_csi2_rx_low_layer/st0_state[1]} {i_csi2_rx/i_csi2_rx_low_layer/st0_state[2]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe10]
set_property port_width 8 [get_debug_ports u_ila_2/probe10]
connect_debug_port u_ila_2/probe10 [get_nets [list {i_csi2_rx/i_csi2_rx_low_layer/st0_data[0]} {i_csi2_rx/i_csi2_rx_low_layer/st0_data[1]} {i_csi2_rx/i_csi2_rx_low_layer/st0_data[2]} {i_csi2_rx/i_csi2_rx_low_layer/st0_data[3]} {i_csi2_rx/i_csi2_rx_low_layer/st0_data[4]} {i_csi2_rx/i_csi2_rx_low_layer/st0_data[5]} {i_csi2_rx/i_csi2_rx_low_layer/st0_data[6]} {i_csi2_rx/i_csi2_rx_low_layer/st0_data[7]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe11]
set_property port_width 1 [get_debug_ports u_ila_2/probe11]
connect_debug_port u_ila_2/probe11 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st0_ph]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe12]
set_property port_width 1 [get_debug_ports u_ila_2/probe12]
connect_debug_port u_ila_2/probe12 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st0_valid]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe13]
set_property port_width 1 [get_debug_ports u_ila_2/probe13]
connect_debug_port u_ila_2/probe13 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st1_crc_error]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe14]
set_property port_width 1 [get_debug_ports u_ila_2/probe14]
connect_debug_port u_ila_2/probe14 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st1_de]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe15]
set_property port_width 1 [get_debug_ports u_ila_2/probe15]
connect_debug_port u_ila_2/probe15 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st1_end]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe16]
set_property port_width 1 [get_debug_ports u_ila_2/probe16]
connect_debug_port u_ila_2/probe16 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st1_frame_end]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe17]
set_property port_width 1 [get_debug_ports u_ila_2/probe17]
connect_debug_port u_ila_2/probe17 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st1_frame_start]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe18]
set_property port_width 1 [get_debug_ports u_ila_2/probe18]
connect_debug_port u_ila_2/probe18 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st1_last]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe19]
set_property port_width 1 [get_debug_ports u_ila_2/probe19]
connect_debug_port u_ila_2/probe19 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st1_req_sync]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe20]
set_property port_width 1 [get_debug_ports u_ila_2/probe20]
connect_debug_port u_ila_2/probe20 [get_nets [list i_csi2_rx/i_csi2_rx_low_layer/st1_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk250]
