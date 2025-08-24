create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list u_design_1/clk_wiz_0/inst/clk_out3]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 10 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {axi4s_blk\\.tdata[0]} {axi4s_blk\\.tdata[1]} {axi4s_blk\\.tdata[2]} {axi4s_blk\\.tdata[3]} {axi4s_blk\\.tdata[4]} {axi4s_blk\\.tdata[5]} {axi4s_blk\\.tdata[6]} {axi4s_blk\\.tdata[7]} {axi4s_blk\\.tdata[8]} {axi4s_blk\\.tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 10 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi4s_fmtr\\.tdata[0]} {axi4s_fmtr\\.tdata[1]} {axi4s_fmtr\\.tdata[2]} {axi4s_fmtr\\.tdata[3]} {axi4s_fmtr\\.tdata[4]} {axi4s_fmtr\\.tdata[5]} {axi4s_fmtr\\.tdata[6]} {axi4s_fmtr\\.tdata[7]} {axi4s_fmtr\\.tdata[8]} {axi4s_fmtr\\.tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 10 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {axi4s_img\\.tdata[0]} {axi4s_img\\.tdata[1]} {axi4s_img\\.tdata[2]} {axi4s_img\\.tdata[3]} {axi4s_img\\.tdata[4]} {axi4s_img\\.tdata[5]} {axi4s_img\\.tdata[6]} {axi4s_img\\.tdata[7]} {axi4s_img\\.tdata[8]} {axi4s_img\\.tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {axi4s_wdma_blk\\.tdata[0]} {axi4s_wdma_blk\\.tdata[1]} {axi4s_wdma_blk\\.tdata[2]} {axi4s_wdma_blk\\.tdata[3]} {axi4s_wdma_blk\\.tdata[4]} {axi4s_wdma_blk\\.tdata[5]} {axi4s_wdma_blk\\.tdata[6]} {axi4s_wdma_blk\\.tdata[7]} {axi4s_wdma_blk\\.tdata[8]} {axi4s_wdma_blk\\.tdata[9]} {axi4s_wdma_blk\\.tdata[10]} {axi4s_wdma_blk\\.tdata[11]} {axi4s_wdma_blk\\.tdata[12]} {axi4s_wdma_blk\\.tdata[13]} {axi4s_wdma_blk\\.tdata[14]} {axi4s_wdma_blk\\.tdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {axi4s_wdma_img\\.tdata[0]} {axi4s_wdma_img\\.tdata[1]} {axi4s_wdma_img\\.tdata[2]} {axi4s_wdma_img\\.tdata[3]} {axi4s_wdma_img\\.tdata[4]} {axi4s_wdma_img\\.tdata[5]} {axi4s_wdma_img\\.tdata[6]} {axi4s_wdma_img\\.tdata[7]} {axi4s_wdma_img\\.tdata[8]} {axi4s_wdma_img\\.tdata[9]} {axi4s_wdma_img\\.tdata[10]} {axi4s_wdma_img\\.tdata[11]} {axi4s_wdma_img\\.tdata[12]} {axi4s_wdma_img\\.tdata[13]} {axi4s_wdma_img\\.tdata[14]} {axi4s_wdma_img\\.tdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 32 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {mon_frame_count[0]} {mon_frame_count[1]} {mon_frame_count[2]} {mon_frame_count[3]} {mon_frame_count[4]} {mon_frame_count[5]} {mon_frame_count[6]} {mon_frame_count[7]} {mon_frame_count[8]} {mon_frame_count[9]} {mon_frame_count[10]} {mon_frame_count[11]} {mon_frame_count[12]} {mon_frame_count[13]} {mon_frame_count[14]} {mon_frame_count[15]} {mon_frame_count[16]} {mon_frame_count[17]} {mon_frame_count[18]} {mon_frame_count[19]} {mon_frame_count[20]} {mon_frame_count[21]} {mon_frame_count[22]} {mon_frame_count[23]} {mon_frame_count[24]} {mon_frame_count[25]} {mon_frame_count[26]} {mon_frame_count[27]} {mon_frame_count[28]} {mon_frame_count[29]} {mon_frame_count[30]} {mon_frame_count[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 32 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {mon_frame_rate_count[0]} {mon_frame_rate_count[1]} {mon_frame_rate_count[2]} {mon_frame_rate_count[3]} {mon_frame_rate_count[4]} {mon_frame_rate_count[5]} {mon_frame_rate_count[6]} {mon_frame_rate_count[7]} {mon_frame_rate_count[8]} {mon_frame_rate_count[9]} {mon_frame_rate_count[10]} {mon_frame_rate_count[11]} {mon_frame_rate_count[12]} {mon_frame_rate_count[13]} {mon_frame_rate_count[14]} {mon_frame_rate_count[15]} {mon_frame_rate_count[16]} {mon_frame_rate_count[17]} {mon_frame_rate_count[18]} {mon_frame_rate_count[19]} {mon_frame_rate_count[20]} {mon_frame_rate_count[21]} {mon_frame_rate_count[22]} {mon_frame_rate_count[23]} {mon_frame_rate_count[24]} {mon_frame_rate_count[25]} {mon_frame_rate_count[26]} {mon_frame_rate_count[27]} {mon_frame_rate_count[28]} {mon_frame_rate_count[29]} {mon_frame_rate_count[30]} {mon_frame_rate_count[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 32 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {mon_frame_rate_value[0]} {mon_frame_rate_value[1]} {mon_frame_rate_value[2]} {mon_frame_rate_value[3]} {mon_frame_rate_value[4]} {mon_frame_rate_value[5]} {mon_frame_rate_value[6]} {mon_frame_rate_value[7]} {mon_frame_rate_value[8]} {mon_frame_rate_value[9]} {mon_frame_rate_value[10]} {mon_frame_rate_value[11]} {mon_frame_rate_value[12]} {mon_frame_rate_value[13]} {mon_frame_rate_value[14]} {mon_frame_rate_value[15]} {mon_frame_rate_value[16]} {mon_frame_rate_value[17]} {mon_frame_rate_value[18]} {mon_frame_rate_value[19]} {mon_frame_rate_value[20]} {mon_frame_rate_value[21]} {mon_frame_rate_value[22]} {mon_frame_rate_value[23]} {mon_frame_rate_value[24]} {mon_frame_rate_value[25]} {mon_frame_rate_value[26]} {mon_frame_rate_value[27]} {mon_frame_rate_value[28]} {mon_frame_rate_value[29]} {mon_frame_rate_value[30]} {mon_frame_rate_value[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 10 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][0]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][1]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][2]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][3]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][4]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][5]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][6]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][7]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][8]} {u_rtcl_p3s7_hs_dphy_recv/conv_data[0][9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 8 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {u_rtcl_p3s7_hs_dphy_recv/fifo_data[0][0]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[0][1]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[0][2]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[0][3]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[0][4]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[0][5]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[0][6]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[0][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 8 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {u_rtcl_p3s7_hs_dphy_recv/fifo_data[1][0]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[1][1]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[1][2]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[1][3]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[1][4]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[1][5]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[1][6]} {u_rtcl_p3s7_hs_dphy_recv/fifo_data[1][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {axi4s_blk\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {axi4s_blk\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {axi4s_blk\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {axi4s_blk\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {axi4s_fmtr\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {axi4s_fmtr\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {axi4s_fmtr\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {axi4s_fmtr\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {axi4s_img\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {axi4s_img\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {axi4s_img\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {axi4s_img\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 1 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {axi4s_wdma_blk\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 1 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {axi4s_wdma_blk\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 1 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list {axi4s_wdma_blk\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 1 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {axi4s_wdma_blk\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 1 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list {axi4s_wdma_img\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 1 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list {axi4s_wdma_img\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
set_property port_width 1 [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list {axi4s_wdma_img\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
set_property port_width 1 [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list {axi4s_wdma_img\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
set_property port_width 1 [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/conv_black]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
set_property port_width 1 [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/conv_first]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe33]
set_property port_width 1 [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/conv_last]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
set_property port_width 1 [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/conv_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
set_property port_width 1 [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/fifo_black]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
set_property port_width 1 [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/fifo_first]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
set_property port_width 1 [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/fifo_last]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe38]
set_property port_width 1 [get_debug_ports u_ila_0/probe38]
connect_debug_port u_ila_0/probe38 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/fifo_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe39]
set_property port_width 1 [get_debug_ports u_ila_0/probe39]
connect_debug_port u_ila_0/probe39 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/fifo_valid]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list u_mipi_dphy_cam/inst/inst/mipi_dphy_cam_rx_support_i/rxbyteclkhs]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 8 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {dl0_rxdatahs[0]} {dl0_rxdatahs[1]} {dl0_rxdatahs[2]} {dl0_rxdatahs[3]} {dl0_rxdatahs[4]} {dl0_rxdatahs[5]} {dl0_rxdatahs[6]} {dl0_rxdatahs[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 8 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {dl1_rxdatahs[0]} {dl1_rxdatahs[1]} {dl1_rxdatahs[2]} {dl1_rxdatahs[3]} {dl1_rxdatahs[4]} {dl1_rxdatahs[5]} {dl1_rxdatahs[6]} {dl1_rxdatahs[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 8 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {u_rtcl_p3s7_hs_dphy_recv/rx_data[0][0]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[0][1]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[0][2]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[0][3]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[0][4]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[0][5]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[0][6]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[0][7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 8 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {u_rtcl_p3s7_hs_dphy_recv/rx_data[1][0]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[1][1]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[1][2]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[1][3]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[1][4]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[1][5]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[1][6]} {u_rtcl_p3s7_hs_dphy_recv/rx_data[1][7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 8 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {u_rtcl_p3s7_hs_dphy_recv/rx_type[0]} {u_rtcl_p3s7_hs_dphy_recv/rx_type[1]} {u_rtcl_p3s7_hs_dphy_recv/rx_type[2]} {u_rtcl_p3s7_hs_dphy_recv/rx_type[3]} {u_rtcl_p3s7_hs_dphy_recv/rx_type[4]} {u_rtcl_p3s7_hs_dphy_recv/rx_type[5]} {u_rtcl_p3s7_hs_dphy_recv/rx_type[6]} {u_rtcl_p3s7_hs_dphy_recv/rx_type[7]}]]
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
connect_debug_port u_ila_1/probe8 [get_nets [list dl1_rxactivehs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe9]
set_property port_width 1 [get_debug_ports u_ila_1/probe9]
connect_debug_port u_ila_1/probe9 [get_nets [list dl1_rxsynchs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe10]
set_property port_width 1 [get_debug_ports u_ila_1/probe10]
connect_debug_port u_ila_1/probe10 [get_nets [list dl1_rxvalidhs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe11]
set_property port_width 1 [get_debug_ports u_ila_1/probe11]
connect_debug_port u_ila_1/probe11 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/rx_first]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe12]
set_property port_width 1 [get_debug_ports u_ila_1/probe12]
connect_debug_port u_ila_1/probe12 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/rx_last]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe13]
set_property port_width 1 [get_debug_ports u_ila_1/probe13]
connect_debug_port u_ila_1/probe13 [get_nets [list u_rtcl_p3s7_hs_dphy_recv/rx_valid]]
create_debug_core u_ila_2 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_2]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_2]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_2]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_2]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_2]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_2]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_2]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_2]
set_property port_width 1 [get_debug_ports u_ila_2/clk]
connect_debug_port u_ila_2/clk [get_nets [list u_design_1/zynq_ultra_ps_e_0/inst/pl_clk0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe0]
set_property port_width 8 [get_debug_ports u_ila_2/probe0]
connect_debug_port u_ila_2/probe0 [get_nets [list {reg_csi_data_type[0]} {reg_csi_data_type[1]} {reg_csi_data_type[2]} {reg_csi_data_type[3]} {reg_csi_data_type[4]} {reg_csi_data_type[5]} {reg_csi_data_type[6]} {reg_csi_data_type[7]}]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe1]
set_property port_width 1 [get_debug_ports u_ila_2/probe1]
connect_debug_port u_ila_2/probe1 [get_nets [list i2c0_scl_i]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe2]
set_property port_width 1 [get_debug_ports u_ila_2/probe2]
connect_debug_port u_ila_2/probe2 [get_nets [list i2c0_scl_t]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe3]
set_property port_width 1 [get_debug_ports u_ila_2/probe3]
connect_debug_port u_ila_2/probe3 [get_nets [list i2c0_sda_i]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe4]
set_property port_width 1 [get_debug_ports u_ila_2/probe4]
connect_debug_port u_ila_2/probe4 [get_nets [list i2c0_sda_t]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe5]
set_property port_width 1 [get_debug_ports u_ila_2/probe5]
connect_debug_port u_ila_2/probe5 [get_nets [list reg_cam_enable]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe6]
set_property port_width 1 [get_debug_ports u_ila_2/probe6]
connect_debug_port u_ila_2/probe6 [get_nets [list reg_dphy_init_done]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe7]
set_property port_width 1 [get_debug_ports u_ila_2/probe7]
connect_debug_port u_ila_2/probe7 [get_nets [list reg_sw_reset]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk250]
