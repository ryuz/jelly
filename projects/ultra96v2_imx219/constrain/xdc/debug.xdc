


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 2 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/clk_wiz_0/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {dbg1_rxdatahs[0]} {dbg1_rxdatahs[1]} {dbg1_rxdatahs[2]} {dbg1_rxdatahs[3]} {dbg1_rxdatahs[4]} {dbg1_rxdatahs[5]} {dbg1_rxdatahs[6]} {dbg1_rxdatahs[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {dbg0_rxdatahs[0]} {dbg0_rxdatahs[1]} {dbg0_rxdatahs[2]} {dbg0_rxdatahs[3]} {dbg0_rxdatahs[4]} {dbg0_rxdatahs[5]} {dbg0_rxdatahs[6]} {dbg0_rxdatahs[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list dbg0_rxactivehs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list dbg0_rxsynchs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list dbg0_rxvalidhs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list dbg1_rxactivehs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list dbg1_rxsynchs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list dbg1_rxvalidhs]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list dbg1_valid]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 2 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list i_design_1/clk_wiz_0/inst/clk_out3]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 32 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {reg_mipi_crc_error[0]} {reg_mipi_crc_error[1]} {reg_mipi_crc_error[2]} {reg_mipi_crc_error[3]} {reg_mipi_crc_error[4]} {reg_mipi_crc_error[5]} {reg_mipi_crc_error[6]} {reg_mipi_crc_error[7]} {reg_mipi_crc_error[8]} {reg_mipi_crc_error[9]} {reg_mipi_crc_error[10]} {reg_mipi_crc_error[11]} {reg_mipi_crc_error[12]} {reg_mipi_crc_error[13]} {reg_mipi_crc_error[14]} {reg_mipi_crc_error[15]} {reg_mipi_crc_error[16]} {reg_mipi_crc_error[17]} {reg_mipi_crc_error[18]} {reg_mipi_crc_error[19]} {reg_mipi_crc_error[20]} {reg_mipi_crc_error[21]} {reg_mipi_crc_error[22]} {reg_mipi_crc_error[23]} {reg_mipi_crc_error[24]} {reg_mipi_crc_error[25]} {reg_mipi_crc_error[26]} {reg_mipi_crc_error[27]} {reg_mipi_crc_error[28]} {reg_mipi_crc_error[29]} {reg_mipi_crc_error[30]} {reg_mipi_crc_error[31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 32 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {reg_mipi_ecc_corrected[0]} {reg_mipi_ecc_corrected[1]} {reg_mipi_ecc_corrected[2]} {reg_mipi_ecc_corrected[3]} {reg_mipi_ecc_corrected[4]} {reg_mipi_ecc_corrected[5]} {reg_mipi_ecc_corrected[6]} {reg_mipi_ecc_corrected[7]} {reg_mipi_ecc_corrected[8]} {reg_mipi_ecc_corrected[9]} {reg_mipi_ecc_corrected[10]} {reg_mipi_ecc_corrected[11]} {reg_mipi_ecc_corrected[12]} {reg_mipi_ecc_corrected[13]} {reg_mipi_ecc_corrected[14]} {reg_mipi_ecc_corrected[15]} {reg_mipi_ecc_corrected[16]} {reg_mipi_ecc_corrected[17]} {reg_mipi_ecc_corrected[18]} {reg_mipi_ecc_corrected[19]} {reg_mipi_ecc_corrected[20]} {reg_mipi_ecc_corrected[21]} {reg_mipi_ecc_corrected[22]} {reg_mipi_ecc_corrected[23]} {reg_mipi_ecc_corrected[24]} {reg_mipi_ecc_corrected[25]} {reg_mipi_ecc_corrected[26]} {reg_mipi_ecc_corrected[27]} {reg_mipi_ecc_corrected[28]} {reg_mipi_ecc_corrected[29]} {reg_mipi_ecc_corrected[30]} {reg_mipi_ecc_corrected[31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 32 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {reg_mipi_crc_count[0]} {reg_mipi_crc_count[1]} {reg_mipi_crc_count[2]} {reg_mipi_crc_count[3]} {reg_mipi_crc_count[4]} {reg_mipi_crc_count[5]} {reg_mipi_crc_count[6]} {reg_mipi_crc_count[7]} {reg_mipi_crc_count[8]} {reg_mipi_crc_count[9]} {reg_mipi_crc_count[10]} {reg_mipi_crc_count[11]} {reg_mipi_crc_count[12]} {reg_mipi_crc_count[13]} {reg_mipi_crc_count[14]} {reg_mipi_crc_count[15]} {reg_mipi_crc_count[16]} {reg_mipi_crc_count[17]} {reg_mipi_crc_count[18]} {reg_mipi_crc_count[19]} {reg_mipi_crc_count[20]} {reg_mipi_crc_count[21]} {reg_mipi_crc_count[22]} {reg_mipi_crc_count[23]} {reg_mipi_crc_count[24]} {reg_mipi_crc_count[25]} {reg_mipi_crc_count[26]} {reg_mipi_crc_count[27]} {reg_mipi_crc_count[28]} {reg_mipi_crc_count[29]} {reg_mipi_crc_count[30]} {reg_mipi_crc_count[31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 32 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {reg_mipi_ecc_count[0]} {reg_mipi_ecc_count[1]} {reg_mipi_ecc_count[2]} {reg_mipi_ecc_count[3]} {reg_mipi_ecc_count[4]} {reg_mipi_ecc_count[5]} {reg_mipi_ecc_count[6]} {reg_mipi_ecc_count[7]} {reg_mipi_ecc_count[8]} {reg_mipi_ecc_count[9]} {reg_mipi_ecc_count[10]} {reg_mipi_ecc_count[11]} {reg_mipi_ecc_count[12]} {reg_mipi_ecc_count[13]} {reg_mipi_ecc_count[14]} {reg_mipi_ecc_count[15]} {reg_mipi_ecc_count[16]} {reg_mipi_ecc_count[17]} {reg_mipi_ecc_count[18]} {reg_mipi_ecc_count[19]} {reg_mipi_ecc_count[20]} {reg_mipi_ecc_count[21]} {reg_mipi_ecc_count[22]} {reg_mipi_ecc_count[23]} {reg_mipi_ecc_count[24]} {reg_mipi_ecc_count[25]} {reg_mipi_ecc_count[26]} {reg_mipi_ecc_count[27]} {reg_mipi_ecc_count[28]} {reg_mipi_ecc_count[29]} {reg_mipi_ecc_count[30]} {reg_mipi_ecc_count[31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 32 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {reg_mipi_packet_lost[0]} {reg_mipi_packet_lost[1]} {reg_mipi_packet_lost[2]} {reg_mipi_packet_lost[3]} {reg_mipi_packet_lost[4]} {reg_mipi_packet_lost[5]} {reg_mipi_packet_lost[6]} {reg_mipi_packet_lost[7]} {reg_mipi_packet_lost[8]} {reg_mipi_packet_lost[9]} {reg_mipi_packet_lost[10]} {reg_mipi_packet_lost[11]} {reg_mipi_packet_lost[12]} {reg_mipi_packet_lost[13]} {reg_mipi_packet_lost[14]} {reg_mipi_packet_lost[15]} {reg_mipi_packet_lost[16]} {reg_mipi_packet_lost[17]} {reg_mipi_packet_lost[18]} {reg_mipi_packet_lost[19]} {reg_mipi_packet_lost[20]} {reg_mipi_packet_lost[21]} {reg_mipi_packet_lost[22]} {reg_mipi_packet_lost[23]} {reg_mipi_packet_lost[24]} {reg_mipi_packet_lost[25]} {reg_mipi_packet_lost[26]} {reg_mipi_packet_lost[27]} {reg_mipi_packet_lost[28]} {reg_mipi_packet_lost[29]} {reg_mipi_packet_lost[30]} {reg_mipi_packet_lost[31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 32 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list {reg_mipi_ecc_error[0]} {reg_mipi_ecc_error[1]} {reg_mipi_ecc_error[2]} {reg_mipi_ecc_error[3]} {reg_mipi_ecc_error[4]} {reg_mipi_ecc_error[5]} {reg_mipi_ecc_error[6]} {reg_mipi_ecc_error[7]} {reg_mipi_ecc_error[8]} {reg_mipi_ecc_error[9]} {reg_mipi_ecc_error[10]} {reg_mipi_ecc_error[11]} {reg_mipi_ecc_error[12]} {reg_mipi_ecc_error[13]} {reg_mipi_ecc_error[14]} {reg_mipi_ecc_error[15]} {reg_mipi_ecc_error[16]} {reg_mipi_ecc_error[17]} {reg_mipi_ecc_error[18]} {reg_mipi_ecc_error[19]} {reg_mipi_ecc_error[20]} {reg_mipi_ecc_error[21]} {reg_mipi_ecc_error[22]} {reg_mipi_ecc_error[23]} {reg_mipi_ecc_error[24]} {reg_mipi_ecc_error[25]} {reg_mipi_ecc_error[26]} {reg_mipi_ecc_error[27]} {reg_mipi_ecc_error[28]} {reg_mipi_ecc_error[29]} {reg_mipi_ecc_error[30]} {reg_mipi_ecc_error[31]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk250]
