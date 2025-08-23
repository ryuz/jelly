connect_debug_port u_ila_0/probe0 [get_nets [list {axi4s_black\\.tdata[0]} {axi4s_black\\.tdata[1]} {axi4s_black\\.tdata[2]} {axi4s_black\\.tdata[3]} {axi4s_black\\.tdata[4]} {axi4s_black\\.tdata[5]} {axi4s_black\\.tdata[6]} {axi4s_black\\.tdata[7]} {axi4s_black\\.tdata[8]} {axi4s_black\\.tdata[9]}]]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi4s_image\\.tdata[0]} {axi4s_image\\.tdata[1]} {axi4s_image\\.tdata[2]} {axi4s_image\\.tdata[3]} {axi4s_image\\.tdata[4]} {axi4s_image\\.tdata[5]} {axi4s_image\\.tdata[6]} {axi4s_image\\.tdata[7]} {axi4s_image\\.tdata[8]} {axi4s_image\\.tdata[9]}]]
connect_debug_port u_ila_0/probe2 [get_nets [list {axi4s_wdma\\.tdata[0]} {axi4s_wdma\\.tdata[1]} {axi4s_wdma\\.tdata[2]} {axi4s_wdma\\.tdata[3]} {axi4s_wdma\\.tdata[4]} {axi4s_wdma\\.tdata[5]} {axi4s_wdma\\.tdata[6]} {axi4s_wdma\\.tdata[7]} {axi4s_wdma\\.tdata[8]} {axi4s_wdma\\.tdata[9]} {axi4s_wdma\\.tdata[10]} {axi4s_wdma\\.tdata[11]} {axi4s_wdma\\.tdata[12]} {axi4s_wdma\\.tdata[13]} {axi4s_wdma\\.tdata[14]} {axi4s_wdma\\.tdata[15]}]]
connect_debug_port u_ila_0/probe4 [get_nets [list {axi4s_black\\.tlast}]]
connect_debug_port u_ila_0/probe5 [get_nets [list {axi4s_black\\.tuser}]]
connect_debug_port u_ila_0/probe6 [get_nets [list {axi4s_black\\.tvalid}]]
connect_debug_port u_ila_0/probe7 [get_nets [list {axi4s_image\\.tlast}]]
connect_debug_port u_ila_0/probe8 [get_nets [list {axi4s_image\\.tready}]]
connect_debug_port u_ila_0/probe9 [get_nets [list {axi4s_image\\.tuser}]]
connect_debug_port u_ila_0/probe10 [get_nets [list {axi4s_image\\.tvalid}]]
connect_debug_port u_ila_0/probe11 [get_nets [list {axi4s_wdma\\.tlast}]]
connect_debug_port u_ila_0/probe12 [get_nets [list {axi4s_wdma\\.tready}]]
connect_debug_port u_ila_0/probe13 [get_nets [list {axi4s_wdma\\.tuser}]]
connect_debug_port u_ila_0/probe14 [get_nets [list {axi4s_wdma\\.tvalid}]]
connect_debug_port u_ila_2/probe0 [get_nets [list {axi4s_black\\.tready}]]

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
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi4s_wdma_img\\.tdata[0]} {axi4s_wdma_img\\.tdata[1]} {axi4s_wdma_img\\.tdata[2]} {axi4s_wdma_img\\.tdata[3]} {axi4s_wdma_img\\.tdata[4]} {axi4s_wdma_img\\.tdata[5]} {axi4s_wdma_img\\.tdata[6]} {axi4s_wdma_img\\.tdata[7]} {axi4s_wdma_img\\.tdata[8]} {axi4s_wdma_img\\.tdata[9]} {axi4s_wdma_img\\.tdata[10]} {axi4s_wdma_img\\.tdata[11]} {axi4s_wdma_img\\.tdata[12]} {axi4s_wdma_img\\.tdata[13]} {axi4s_wdma_img\\.tdata[14]} {axi4s_wdma_img\\.tdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 16 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {axi4s_wdma_blk\\.tdata[0]} {axi4s_wdma_blk\\.tdata[1]} {axi4s_wdma_blk\\.tdata[2]} {axi4s_wdma_blk\\.tdata[3]} {axi4s_wdma_blk\\.tdata[4]} {axi4s_wdma_blk\\.tdata[5]} {axi4s_wdma_blk\\.tdata[6]} {axi4s_wdma_blk\\.tdata[7]} {axi4s_wdma_blk\\.tdata[8]} {axi4s_wdma_blk\\.tdata[9]} {axi4s_wdma_blk\\.tdata[10]} {axi4s_wdma_blk\\.tdata[11]} {axi4s_wdma_blk\\.tdata[12]} {axi4s_wdma_blk\\.tdata[13]} {axi4s_wdma_blk\\.tdata[14]} {axi4s_wdma_blk\\.tdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 10 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {axi4s_fmtr\\.tdata[0]} {axi4s_fmtr\\.tdata[1]} {axi4s_fmtr\\.tdata[2]} {axi4s_fmtr\\.tdata[3]} {axi4s_fmtr\\.tdata[4]} {axi4s_fmtr\\.tdata[5]} {axi4s_fmtr\\.tdata[6]} {axi4s_fmtr\\.tdata[7]} {axi4s_fmtr\\.tdata[8]} {axi4s_fmtr\\.tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 10 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {axi4s_img\\.tdata[0]} {axi4s_img\\.tdata[1]} {axi4s_img\\.tdata[2]} {axi4s_img\\.tdata[3]} {axi4s_img\\.tdata[4]} {axi4s_img\\.tdata[5]} {axi4s_img\\.tdata[6]} {axi4s_img\\.tdata[7]} {axi4s_img\\.tdata[8]} {axi4s_img\\.tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {axi4s_blk\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {axi4s_blk\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {axi4s_blk\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {axi4s_blk\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {axi4s_fmtr\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {axi4s_fmtr\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {axi4s_fmtr\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {axi4s_fmtr\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {axi4s_img\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {axi4s_img\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {axi4s_img\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {axi4s_img\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {axi4s_wdma_blk\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {axi4s_wdma_blk\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {axi4s_wdma_blk\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {axi4s_wdma_blk\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {axi4s_wdma_img\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {axi4s_wdma_img\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 1 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {axi4s_wdma_img\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 1 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {axi4s_wdma_img\\.tvalid}]]
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
connect_debug_port u_ila_1/probe0 [get_nets [list {dl1_rxdatahs[0]} {dl1_rxdatahs[1]} {dl1_rxdatahs[2]} {dl1_rxdatahs[3]} {dl1_rxdatahs[4]} {dl1_rxdatahs[5]} {dl1_rxdatahs[6]} {dl1_rxdatahs[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 8 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {dl0_rxdatahs[0]} {dl0_rxdatahs[1]} {dl0_rxdatahs[2]} {dl0_rxdatahs[3]} {dl0_rxdatahs[4]} {dl0_rxdatahs[5]} {dl0_rxdatahs[6]} {dl0_rxdatahs[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 1 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list dl0_rxactivehs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 1 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list dl0_rxsynchs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 1 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list dl0_rxvalidhs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 1 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list dl1_rxactivehs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 1 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list dl1_rxsynchs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
set_property port_width 1 [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list dl1_rxvalidhs]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets u_design_1/clk_wiz_0/inst/clk_out3]
