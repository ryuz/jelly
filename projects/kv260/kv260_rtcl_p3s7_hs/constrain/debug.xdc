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




connect_debug_port u_ila_0/probe37 [get_nets [list u_dma_video_write_img/i_dma_stream_write/u_axi4_write_nd/n_0_4]]
connect_debug_port u_ila_0/probe38 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/n_0_4]]
connect_debug_port u_ila_0/probe39 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/n_0_5]]
connect_debug_port u_ila_0/probe40 [get_nets [list u_dma_video_write_img/i_dma_stream_write/u_axi4_write_nd/n_0_5]]






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
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_last[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_last[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_last[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 3 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_detect_first[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_detect_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_detect_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 3 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_detect_last[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_detect_last[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_detect_last[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 18 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[15]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[16]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_data[17]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 3 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_first[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 18 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[15]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[16]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_data[17]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 3 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_first[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 3 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_last[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_last[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_last[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 49 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[15]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[16]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[17]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[18]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[19]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[20]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[21]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[22]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[23]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[24]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[25]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[26]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[27]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[28]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[29]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[30]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[31]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[32]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[33]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[34]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[35]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[36]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[37]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[38]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[39]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[40]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[41]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[42]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[43]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[44]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[45]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[46]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[47]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_len[48]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 18 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[15]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[16]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_data[17]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 3 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_first[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 3 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_last[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_last[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_last[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 49 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[15]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[16]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[17]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[18]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[19]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[20]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[21]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[22]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[23]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[24]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[25]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[26]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[27]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[28]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[29]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[30]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[31]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[32]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[33]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[34]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[35]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[36]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[37]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[38]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[39]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[40]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[41]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[42]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[43]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[44]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[45]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[46]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[47]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_len[48]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 14 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_count[13]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 3 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_param_detect_first[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_param_detect_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_param_detect_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 3 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_param_detect_first2[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_param_detect_first2[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_param_detect_first2[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 18 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[15]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[16]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_data[17]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 3 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_first[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 3 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_last[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_last[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_last[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 3 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_s_first[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_s_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_s_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 3 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_s_last[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_s_last[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_s_last[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 2 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 2 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_last[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_last[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 14 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_len[13]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 3 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_first[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_first[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_first[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 3 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_last[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_last[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_last[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 49 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[15]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[16]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[17]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[18]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[19]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[20]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[21]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[22]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[23]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[24]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[25]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[26]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[27]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[28]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[29]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[30]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[31]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[32]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[33]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[34]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[35]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[36]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[37]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[38]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[39]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[40]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[41]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[42]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[43]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[44]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[45]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[46]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[47]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_len[48]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 16 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 1 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wfirst[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
set_property port_width 1 [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wlast[0]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
set_property port_width 16 [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[2]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[3]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[4]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[5]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[6]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[7]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[8]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[9]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[10]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[11]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[12]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[13]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[14]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
set_property port_width 3 [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wfirst[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wfirst[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wfirst[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
set_property port_width 3 [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wlast[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wlast[1]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wlast[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe33]
set_property port_width 2 [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wstrb[0]} {u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wstrb[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
set_property port_width 10 [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list {axi4s_blk\\.tdata[0]} {axi4s_blk\\.tdata[1]} {axi4s_blk\\.tdata[2]} {axi4s_blk\\.tdata[3]} {axi4s_blk\\.tdata[4]} {axi4s_blk\\.tdata[5]} {axi4s_blk\\.tdata[6]} {axi4s_blk\\.tdata[7]} {axi4s_blk\\.tdata[8]} {axi4s_blk\\.tdata[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
set_property port_width 16 [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list {axi4s_wdma_blk\\.tdata[0]} {axi4s_wdma_blk\\.tdata[1]} {axi4s_wdma_blk\\.tdata[2]} {axi4s_wdma_blk\\.tdata[3]} {axi4s_wdma_blk\\.tdata[4]} {axi4s_wdma_blk\\.tdata[5]} {axi4s_wdma_blk\\.tdata[6]} {axi4s_wdma_blk\\.tdata[7]} {axi4s_wdma_blk\\.tdata[8]} {axi4s_wdma_blk\\.tdata[9]} {axi4s_wdma_blk\\.tdata[10]} {axi4s_wdma_blk\\.tdata[11]} {axi4s_wdma_blk\\.tdata[12]} {axi4s_wdma_blk\\.tdata[13]} {axi4s_wdma_blk\\.tdata[14]} {axi4s_wdma_blk\\.tdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
set_property port_width 1 [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list {axi4s_blk\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
set_property port_width 1 [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list {axi4s_blk\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe38]
set_property port_width 1 [get_debug_ports u_ila_0/probe38]
connect_debug_port u_ila_0/probe38 [get_nets [list {axi4s_blk\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe39]
set_property port_width 1 [get_debug_ports u_ila_0/probe39]
connect_debug_port u_ila_0/probe39 [get_nets [list {axi4s_blk\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe40]
set_property port_width 1 [get_debug_ports u_ila_0/probe40]
connect_debug_port u_ila_0/probe40 [get_nets [list {axi4s_wdma_blk\\.tlast}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe41]
set_property port_width 1 [get_debug_ports u_ila_0/probe41]
connect_debug_port u_ila_0/probe41 [get_nets [list {axi4s_wdma_blk\\.tready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe42]
set_property port_width 1 [get_debug_ports u_ila_0/probe42]
connect_debug_port u_ila_0/probe42 [get_nets [list {axi4s_wdma_blk\\.tuser}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe43]
set_property port_width 1 [get_debug_ports u_ila_0/probe43]
connect_debug_port u_ila_0/probe43 [get_nets [list {axi4s_wdma_blk\\.tvalid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe44]
set_property port_width 1 [get_debug_ports u_ila_0/probe44]
connect_debug_port u_ila_0/probe44 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe45]
set_property port_width 1 [get_debug_ports u_ila_0/probe45]
connect_debug_port u_ila_0/probe45 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_user]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe46]
set_property port_width 1 [get_debug_ports u_ila_0/probe46]
connect_debug_port u_ila_0/probe46 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_m_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe47]
set_property port_width 1 [get_debug_ports u_ila_0/probe47]
connect_debug_port u_ila_0/probe47 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe48]
set_property port_width 1 [get_debug_ports u_ila_0/probe48]
connect_debug_port u_ila_0/probe48 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe49]
set_property port_width 1 [get_debug_ports u_ila_0/probe49]
connect_debug_port u_ila_0/probe49 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_padding_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe50]
set_property port_width 1 [get_debug_ports u_ila_0/probe50]
connect_debug_port u_ila_0/probe50 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_padding]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe51]
set_property port_width 1 [get_debug_ports u_ila_0/probe51]
connect_debug_port u_ila_0/probe51 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_skip]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe52]
set_property port_width 1 [get_debug_ports u_ila_0/probe52]
connect_debug_port u_ila_0/probe52 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_skip]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe53]
set_property port_width 1 [get_debug_ports u_ila_0/probe53]
connect_debug_port u_ila_0/probe53 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe54]
set_property port_width 1 [get_debug_ports u_ila_0/probe54]
connect_debug_port u_ila_0/probe54 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe55]
set_property port_width 1 [get_debug_ports u_ila_0/probe55]
connect_debug_port u_ila_0/probe55 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe56]
set_property port_width 1 [get_debug_ports u_ila_0/probe56]
connect_debug_port u_ila_0/probe56 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/dbg_s_wvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe57]
set_property port_width 1 [get_debug_ports u_ila_0/probe57]
connect_debug_port u_ila_0/probe57 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_skip]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe58]
set_property port_width 1 [get_debug_ports u_ila_0/probe58]
connect_debug_port u_ila_0/probe58 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe59]
set_property port_width 1 [get_debug_ports u_ila_0/probe59]
connect_debug_port u_ila_0/probe59 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/fifo_s_permit_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe60]
set_property port_width 1 [get_debug_ports u_ila_0/probe60]
connect_debug_port u_ila_0/probe60 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe61]
set_property port_width 1 [get_debug_ports u_ila_0/probe61]
connect_debug_port u_ila_0/probe61 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_wvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe62]
set_property port_width 1 [get_debug_ports u_ila_0/probe62]
connect_debug_port u_ila_0/probe62 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_ff_s_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe63]
set_property port_width 1 [get_debug_ports u_ila_0/probe63]
connect_debug_port u_ila_0/probe63 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe64]
set_property port_width 1 [get_debug_ports u_ila_0/probe64]
connect_debug_port u_ila_0/probe64 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_fifo_s_permit_user]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe65]
set_property port_width 1 [get_debug_ports u_ila_0/probe65]
connect_debug_port u_ila_0/probe65 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_busy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe66]
set_property port_width 1 [get_debug_ports u_ila_0/probe66]
connect_debug_port u_ila_0/probe66 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_end]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe67]
set_property port_width 1 [get_debug_ports u_ila_0/probe67]
connect_debug_port u_ila_0/probe67 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_reg_underflow]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe68]
set_property port_width 1 [get_debug_ports u_ila_0/probe68]
connect_debug_port u_ila_0/probe68 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe69]
set_property port_width 1 [get_debug_ports u_ila_0/probe69]
connect_debug_port u_ila_0/probe69 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_s_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe70]
set_property port_width 1 [get_debug_ports u_ila_0/probe70]
connect_debug_port u_ila_0/probe70 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_end]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe71]
set_property port_width 1 [get_debug_ports u_ila_0/probe71]
connect_debug_port u_ila_0/probe71 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_start]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe72]
set_property port_width 1 [get_debug_ports u_ila_0/probe72]
connect_debug_port u_ila_0/probe72 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_start_overflow]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe73]
set_property port_width 1 [get_debug_ports u_ila_0/probe73]
connect_debug_port u_ila_0/probe73 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/blk_gate.dbg2_sig_start_underflow]]
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
connect_debug_port u_ila_1/clk [get_nets [list u_design_1/zynq_ultra_ps_e_0/inst/pl_clk0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 4 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {u_dma_video_write_blk/i_dma_stream_write/reg_ctl_control[0]} {u_dma_video_write_blk/i_dma_stream_write/reg_ctl_control[1]} {u_dma_video_write_blk/i_dma_stream_write/reg_ctl_control[2]} {u_dma_video_write_blk/i_dma_stream_write/reg_ctl_control[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 1 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/reg_ctl_status]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 1 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/sig_end]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 1 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/sig_start]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 1 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_bready]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 1 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/write_bvalid]]
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
connect_debug_port u_ila_2/clk [get_nets [list u_design_1/clk_wiz_0/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe0]
set_property port_width 1 [get_debug_ports u_ila_2/probe0]
connect_debug_port u_ila_2/probe0 [get_nets [list u_dma_video_write_blk/i_dma_stream_write/u_axi4_write_nd/i_stream_gate/dbg_s_permit_reset]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk250]
