

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
connect_debug_port u_ila_0/clk [get_nets [list i_design_1/zynq_ultra_ps_e_0/inst/pl_clk0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 4 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {monitor_tsk_tskwait[6][0]} {monitor_tsk_tskwait[6][1]} {monitor_tsk_tskwait[6][2]} {monitor_tsk_tskwait[6][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 4 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {monitor_tsk_tskwait[3][0]} {monitor_tsk_tskwait[3][1]} {monitor_tsk_tskwait[3][2]} {monitor_tsk_tskwait[3][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {monitor_tsk_tskstat[6][0]} {monitor_tsk_tskstat[6][1]} {monitor_tsk_tskstat[6][2]} {monitor_tsk_tskstat[6][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 4 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {monitor_tsk_tskstat[4][0]} {monitor_tsk_tskstat[4][1]} {monitor_tsk_tskstat[4][2]} {monitor_tsk_tskstat[4][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 4 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {monitor_tsk_tskwait[12][0]} {monitor_tsk_tskwait[12][1]} {monitor_tsk_tskwait[12][2]} {monitor_tsk_tskwait[12][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 4 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {monitor_tsk_tskwait[2][0]} {monitor_tsk_tskwait[2][1]} {monitor_tsk_tskwait[2][2]} {monitor_tsk_tskwait[2][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 4 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {monitor_tsk_tskstat[7][0]} {monitor_tsk_tskstat[7][1]} {monitor_tsk_tskstat[7][2]} {monitor_tsk_tskstat[7][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 27 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {wb_adr_i[0]} {wb_adr_i[1]} {wb_adr_i[2]} {wb_adr_i[3]} {wb_adr_i[4]} {wb_adr_i[5]} {wb_adr_i[6]} {wb_adr_i[7]} {wb_adr_i[8]} {wb_adr_i[9]} {wb_adr_i[10]} {wb_adr_i[11]} {wb_adr_i[12]} {wb_adr_i[13]} {wb_adr_i[14]} {wb_adr_i[15]} {wb_adr_i[16]} {wb_adr_i[17]} {wb_adr_i[18]} {wb_adr_i[19]} {wb_adr_i[20]} {wb_adr_i[21]} {wb_adr_i[22]} {wb_adr_i[23]} {wb_adr_i[24]} {wb_adr_i[25]} {wb_adr_i[26]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 4 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {monitor_tsk_tskwait[7][0]} {monitor_tsk_tskwait[7][1]} {monitor_tsk_tskwait[7][2]} {monitor_tsk_tskwait[7][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 4 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {monitor_tsk_tskwait[5][0]} {monitor_tsk_tskwait[5][1]} {monitor_tsk_tskwait[5][2]} {monitor_tsk_tskwait[5][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 4 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {monitor_tsk_tskwait[15][0]} {monitor_tsk_tskwait[15][1]} {monitor_tsk_tskwait[15][2]} {monitor_tsk_tskwait[15][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 4 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {monitor_tsk_tskwait[14][0]} {monitor_tsk_tskwait[14][1]} {monitor_tsk_tskwait[14][2]} {monitor_tsk_tskwait[14][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 4 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {monitor_tsk_tskwait[13][0]} {monitor_tsk_tskwait[13][1]} {monitor_tsk_tskwait[13][2]} {monitor_tsk_tskwait[13][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 4 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {monitor_tsk_tskwait[4][0]} {monitor_tsk_tskwait[4][1]} {monitor_tsk_tskwait[4][2]} {monitor_tsk_tskwait[4][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 4 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {monitor_sem_semcnt[1][0]} {monitor_sem_semcnt[1][1]} {monitor_sem_semcnt[1][2]} {monitor_sem_semcnt[1][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 4 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {monitor_sem_quecnt[7][0]} {monitor_sem_quecnt[7][1]} {monitor_sem_quecnt[7][2]} {monitor_sem_quecnt[7][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 4 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {monitor_sem_quecnt[6][0]} {monitor_sem_quecnt[6][1]} {monitor_sem_quecnt[6][2]} {monitor_sem_quecnt[6][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 4 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {monitor_sem_semcnt[2][0]} {monitor_sem_semcnt[2][1]} {monitor_sem_semcnt[2][2]} {monitor_sem_semcnt[2][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 4 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {monitor_sem_quecnt[5][0]} {monitor_sem_quecnt[5][1]} {monitor_sem_quecnt[5][2]} {monitor_sem_quecnt[5][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 4 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {monitor_sem_quecnt[4][0]} {monitor_sem_quecnt[4][1]} {monitor_sem_quecnt[4][2]} {monitor_sem_quecnt[4][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 4 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {monitor_sem_quecnt[2][0]} {monitor_sem_quecnt[2][1]} {monitor_sem_quecnt[2][2]} {monitor_sem_quecnt[2][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 4 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {monitor_sem_quecnt[3][0]} {monitor_sem_quecnt[3][1]} {monitor_sem_quecnt[3][2]} {monitor_sem_quecnt[3][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 4 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {monitor_run_tskid[0]} {monitor_run_tskid[1]} {monitor_run_tskid[2]} {monitor_run_tskid[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 32 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {monitor_scratch1[0]} {monitor_scratch1[1]} {monitor_scratch1[2]} {monitor_scratch1[3]} {monitor_scratch1[4]} {monitor_scratch1[5]} {monitor_scratch1[6]} {monitor_scratch1[7]} {monitor_scratch1[8]} {monitor_scratch1[9]} {monitor_scratch1[10]} {monitor_scratch1[11]} {monitor_scratch1[12]} {monitor_scratch1[13]} {monitor_scratch1[14]} {monitor_scratch1[15]} {monitor_scratch1[16]} {monitor_scratch1[17]} {monitor_scratch1[18]} {monitor_scratch1[19]} {monitor_scratch1[20]} {monitor_scratch1[21]} {monitor_scratch1[22]} {monitor_scratch1[23]} {monitor_scratch1[24]} {monitor_scratch1[25]} {monitor_scratch1[26]} {monitor_scratch1[27]} {monitor_scratch1[28]} {monitor_scratch1[29]} {monitor_scratch1[30]} {monitor_scratch1[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 32 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {monitor_scratch2[0]} {monitor_scratch2[1]} {monitor_scratch2[2]} {monitor_scratch2[3]} {monitor_scratch2[4]} {monitor_scratch2[5]} {monitor_scratch2[6]} {monitor_scratch2[7]} {monitor_scratch2[8]} {monitor_scratch2[9]} {monitor_scratch2[10]} {monitor_scratch2[11]} {monitor_scratch2[12]} {monitor_scratch2[13]} {monitor_scratch2[14]} {monitor_scratch2[15]} {monitor_scratch2[16]} {monitor_scratch2[17]} {monitor_scratch2[18]} {monitor_scratch2[19]} {monitor_scratch2[20]} {monitor_scratch2[21]} {monitor_scratch2[22]} {monitor_scratch2[23]} {monitor_scratch2[24]} {monitor_scratch2[25]} {monitor_scratch2[26]} {monitor_scratch2[27]} {monitor_scratch2[28]} {monitor_scratch2[29]} {monitor_scratch2[30]} {monitor_scratch2[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 32 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list {monitor_scratch3[0]} {monitor_scratch3[1]} {monitor_scratch3[2]} {monitor_scratch3[3]} {monitor_scratch3[4]} {monitor_scratch3[5]} {monitor_scratch3[6]} {monitor_scratch3[7]} {monitor_scratch3[8]} {monitor_scratch3[9]} {monitor_scratch3[10]} {monitor_scratch3[11]} {monitor_scratch3[12]} {monitor_scratch3[13]} {monitor_scratch3[14]} {monitor_scratch3[15]} {monitor_scratch3[16]} {monitor_scratch3[17]} {monitor_scratch3[18]} {monitor_scratch3[19]} {monitor_scratch3[20]} {monitor_scratch3[21]} {monitor_scratch3[22]} {monitor_scratch3[23]} {monitor_scratch3[24]} {monitor_scratch3[25]} {monitor_scratch3[26]} {monitor_scratch3[27]} {monitor_scratch3[28]} {monitor_scratch3[29]} {monitor_scratch3[30]} {monitor_scratch3[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 4 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {monitor_sem_quecnt[1][0]} {monitor_sem_quecnt[1][1]} {monitor_sem_quecnt[1][2]} {monitor_sem_quecnt[1][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 4 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list {monitor_tsk_tskstat[14][0]} {monitor_tsk_tskstat[14][1]} {monitor_tsk_tskstat[14][2]} {monitor_tsk_tskstat[14][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 4 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list {monitor_tsk_tskstat[10][0]} {monitor_tsk_tskstat[10][1]} {monitor_tsk_tskstat[10][2]} {monitor_tsk_tskstat[10][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
set_property port_width 32 [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list {monitor_flg_flgptn[0]} {monitor_flg_flgptn[1]} {monitor_flg_flgptn[2]} {monitor_flg_flgptn[3]} {monitor_flg_flgptn[4]} {monitor_flg_flgptn[5]} {monitor_flg_flgptn[6]} {monitor_flg_flgptn[7]} {monitor_flg_flgptn[8]} {monitor_flg_flgptn[9]} {monitor_flg_flgptn[10]} {monitor_flg_flgptn[11]} {monitor_flg_flgptn[12]} {monitor_flg_flgptn[13]} {monitor_flg_flgptn[14]} {monitor_flg_flgptn[15]} {monitor_flg_flgptn[16]} {monitor_flg_flgptn[17]} {monitor_flg_flgptn[18]} {monitor_flg_flgptn[19]} {monitor_flg_flgptn[20]} {monitor_flg_flgptn[21]} {monitor_flg_flgptn[22]} {monitor_flg_flgptn[23]} {monitor_flg_flgptn[24]} {monitor_flg_flgptn[25]} {monitor_flg_flgptn[26]} {monitor_flg_flgptn[27]} {monitor_flg_flgptn[28]} {monitor_flg_flgptn[29]} {monitor_flg_flgptn[30]} {monitor_flg_flgptn[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
set_property port_width 32 [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list {monitor_scratch0[0]} {monitor_scratch0[1]} {monitor_scratch0[2]} {monitor_scratch0[3]} {monitor_scratch0[4]} {monitor_scratch0[5]} {monitor_scratch0[6]} {monitor_scratch0[7]} {monitor_scratch0[8]} {monitor_scratch0[9]} {monitor_scratch0[10]} {monitor_scratch0[11]} {monitor_scratch0[12]} {monitor_scratch0[13]} {monitor_scratch0[14]} {monitor_scratch0[15]} {monitor_scratch0[16]} {monitor_scratch0[17]} {monitor_scratch0[18]} {monitor_scratch0[19]} {monitor_scratch0[20]} {monitor_scratch0[21]} {monitor_scratch0[22]} {monitor_scratch0[23]} {monitor_scratch0[24]} {monitor_scratch0[25]} {monitor_scratch0[26]} {monitor_scratch0[27]} {monitor_scratch0[28]} {monitor_scratch0[29]} {monitor_scratch0[30]} {monitor_scratch0[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
set_property port_width 32 [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list {wb_dat_o[0]} {wb_dat_o[1]} {wb_dat_o[2]} {wb_dat_o[3]} {wb_dat_o[4]} {wb_dat_o[5]} {wb_dat_o[6]} {wb_dat_o[7]} {wb_dat_o[8]} {wb_dat_o[9]} {wb_dat_o[10]} {wb_dat_o[11]} {wb_dat_o[12]} {wb_dat_o[13]} {wb_dat_o[14]} {wb_dat_o[15]} {wb_dat_o[16]} {wb_dat_o[17]} {wb_dat_o[18]} {wb_dat_o[19]} {wb_dat_o[20]} {wb_dat_o[21]} {wb_dat_o[22]} {wb_dat_o[23]} {wb_dat_o[24]} {wb_dat_o[25]} {wb_dat_o[26]} {wb_dat_o[27]} {wb_dat_o[28]} {wb_dat_o[29]} {wb_dat_o[30]} {wb_dat_o[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
set_property port_width 4 [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list {wb_sel_i[0]} {wb_sel_i[1]} {wb_sel_i[2]} {wb_sel_i[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe33]
set_property port_width 4 [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list {monitor_tsk_tskwait[9][0]} {monitor_tsk_tskwait[9][1]} {monitor_tsk_tskwait[9][2]} {monitor_tsk_tskwait[9][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
set_property port_width 32 [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list {wb_dat_i[0]} {wb_dat_i[1]} {wb_dat_i[2]} {wb_dat_i[3]} {wb_dat_i[4]} {wb_dat_i[5]} {wb_dat_i[6]} {wb_dat_i[7]} {wb_dat_i[8]} {wb_dat_i[9]} {wb_dat_i[10]} {wb_dat_i[11]} {wb_dat_i[12]} {wb_dat_i[13]} {wb_dat_i[14]} {wb_dat_i[15]} {wb_dat_i[16]} {wb_dat_i[17]} {wb_dat_i[18]} {wb_dat_i[19]} {wb_dat_i[20]} {wb_dat_i[21]} {wb_dat_i[22]} {wb_dat_i[23]} {wb_dat_i[24]} {wb_dat_i[25]} {wb_dat_i[26]} {wb_dat_i[27]} {wb_dat_i[28]} {wb_dat_i[29]} {wb_dat_i[30]} {wb_dat_i[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
set_property port_width 4 [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list {monitor_sem_semcnt[5][0]} {monitor_sem_semcnt[5][1]} {monitor_sem_semcnt[5][2]} {monitor_sem_semcnt[5][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
set_property port_width 4 [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list {monitor_sem_semcnt[6][0]} {monitor_sem_semcnt[6][1]} {monitor_sem_semcnt[6][2]} {monitor_sem_semcnt[6][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
set_property port_width 4 [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list {monitor_sem_semcnt[7][0]} {monitor_sem_semcnt[7][1]} {monitor_sem_semcnt[7][2]} {monitor_sem_semcnt[7][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe38]
set_property port_width 4 [get_debug_ports u_ila_0/probe38]
connect_debug_port u_ila_0/probe38 [get_nets [list {monitor_tsk_tskstat[5][0]} {monitor_tsk_tskstat[5][1]} {monitor_tsk_tskstat[5][2]} {monitor_tsk_tskstat[5][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe39]
set_property port_width 4 [get_debug_ports u_ila_0/probe39]
connect_debug_port u_ila_0/probe39 [get_nets [list {monitor_tsk_tskstat[11][0]} {monitor_tsk_tskstat[11][1]} {monitor_tsk_tskstat[11][2]} {monitor_tsk_tskstat[11][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe40]
set_property port_width 4 [get_debug_ports u_ila_0/probe40]
connect_debug_port u_ila_0/probe40 [get_nets [list {monitor_tsk_tskwait[10][0]} {monitor_tsk_tskwait[10][1]} {monitor_tsk_tskwait[10][2]} {monitor_tsk_tskwait[10][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe41]
set_property port_width 4 [get_debug_ports u_ila_0/probe41]
connect_debug_port u_ila_0/probe41 [get_nets [list {monitor_tsk_tskstat[2][0]} {monitor_tsk_tskstat[2][1]} {monitor_tsk_tskstat[2][2]} {monitor_tsk_tskstat[2][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe42]
set_property port_width 4 [get_debug_ports u_ila_0/probe42]
connect_debug_port u_ila_0/probe42 [get_nets [list {monitor_tsk_tskstat[3][0]} {monitor_tsk_tskstat[3][1]} {monitor_tsk_tskstat[3][2]} {monitor_tsk_tskstat[3][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe43]
set_property port_width 4 [get_debug_ports u_ila_0/probe43]
connect_debug_port u_ila_0/probe43 [get_nets [list {monitor_tsk_tskstat[13][0]} {monitor_tsk_tskstat[13][1]} {monitor_tsk_tskstat[13][2]} {monitor_tsk_tskstat[13][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe44]
set_property port_width 4 [get_debug_ports u_ila_0/probe44]
connect_debug_port u_ila_0/probe44 [get_nets [list {monitor_tsk_tskstat[9][0]} {monitor_tsk_tskstat[9][1]} {monitor_tsk_tskstat[9][2]} {monitor_tsk_tskstat[9][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe45]
set_property port_width 4 [get_debug_ports u_ila_0/probe45]
connect_debug_port u_ila_0/probe45 [get_nets [list {monitor_tsk_tskwait[8][0]} {monitor_tsk_tskwait[8][1]} {monitor_tsk_tskwait[8][2]} {monitor_tsk_tskwait[8][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe46]
set_property port_width 4 [get_debug_ports u_ila_0/probe46]
connect_debug_port u_ila_0/probe46 [get_nets [list {monitor_tsk_tskstat[15][0]} {monitor_tsk_tskstat[15][1]} {monitor_tsk_tskstat[15][2]} {monitor_tsk_tskstat[15][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe47]
set_property port_width 4 [get_debug_ports u_ila_0/probe47]
connect_debug_port u_ila_0/probe47 [get_nets [list {monitor_tsk_tskstat[12][0]} {monitor_tsk_tskstat[12][1]} {monitor_tsk_tskstat[12][2]} {monitor_tsk_tskstat[12][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe48]
set_property port_width 4 [get_debug_ports u_ila_0/probe48]
connect_debug_port u_ila_0/probe48 [get_nets [list {monitor_tsk_tskwait[1][0]} {monitor_tsk_tskwait[1][1]} {monitor_tsk_tskwait[1][2]} {monitor_tsk_tskwait[1][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe49]
set_property port_width 4 [get_debug_ports u_ila_0/probe49]
connect_debug_port u_ila_0/probe49 [get_nets [list {monitor_tsk_tskstat[1][0]} {monitor_tsk_tskstat[1][1]} {monitor_tsk_tskstat[1][2]} {monitor_tsk_tskstat[1][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe50]
set_property port_width 4 [get_debug_ports u_ila_0/probe50]
connect_debug_port u_ila_0/probe50 [get_nets [list {monitor_top_tskid[0]} {monitor_top_tskid[1]} {monitor_top_tskid[2]} {monitor_top_tskid[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe51]
set_property port_width 4 [get_debug_ports u_ila_0/probe51]
connect_debug_port u_ila_0/probe51 [get_nets [list {monitor_tsk_tskstat[8][0]} {monitor_tsk_tskstat[8][1]} {monitor_tsk_tskstat[8][2]} {monitor_tsk_tskstat[8][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe52]
set_property port_width 4 [get_debug_ports u_ila_0/probe52]
connect_debug_port u_ila_0/probe52 [get_nets [list {monitor_tsk_tskwait[11][0]} {monitor_tsk_tskwait[11][1]} {monitor_tsk_tskwait[11][2]} {monitor_tsk_tskwait[11][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe53]
set_property port_width 4 [get_debug_ports u_ila_0/probe53]
connect_debug_port u_ila_0/probe53 [get_nets [list {monitor_sem_semcnt[3][0]} {monitor_sem_semcnt[3][1]} {monitor_sem_semcnt[3][2]} {monitor_sem_semcnt[3][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe54]
set_property port_width 4 [get_debug_ports u_ila_0/probe54]
connect_debug_port u_ila_0/probe54 [get_nets [list {monitor_sem_semcnt[4][0]} {monitor_sem_semcnt[4][1]} {monitor_sem_semcnt[4][2]} {monitor_sem_semcnt[4][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe55]
set_property port_width 1 [get_debug_ports u_ila_0/probe55]
connect_debug_port u_ila_0/probe55 [get_nets [list irq_rtos]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe56]
set_property port_width 1 [get_debug_ports u_ila_0/probe56]
connect_debug_port u_ila_0/probe56 [get_nets [list {monitor_tsk_suscnt[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe57]
set_property port_width 1 [get_debug_ports u_ila_0/probe57]
connect_debug_port u_ila_0/probe57 [get_nets [list {monitor_tsk_suscnt[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe58]
set_property port_width 1 [get_debug_ports u_ila_0/probe58]
connect_debug_port u_ila_0/probe58 [get_nets [list {monitor_tsk_suscnt[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe59]
set_property port_width 1 [get_debug_ports u_ila_0/probe59]
connect_debug_port u_ila_0/probe59 [get_nets [list {monitor_tsk_suscnt[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe60]
set_property port_width 1 [get_debug_ports u_ila_0/probe60]
connect_debug_port u_ila_0/probe60 [get_nets [list {monitor_tsk_suscnt[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe61]
set_property port_width 1 [get_debug_ports u_ila_0/probe61]
connect_debug_port u_ila_0/probe61 [get_nets [list {monitor_tsk_suscnt[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe62]
set_property port_width 1 [get_debug_ports u_ila_0/probe62]
connect_debug_port u_ila_0/probe62 [get_nets [list {monitor_tsk_suscnt[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe63]
set_property port_width 1 [get_debug_ports u_ila_0/probe63]
connect_debug_port u_ila_0/probe63 [get_nets [list {monitor_tsk_suscnt[8]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe64]
set_property port_width 1 [get_debug_ports u_ila_0/probe64]
connect_debug_port u_ila_0/probe64 [get_nets [list {monitor_tsk_suscnt[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe65]
set_property port_width 1 [get_debug_ports u_ila_0/probe65]
connect_debug_port u_ila_0/probe65 [get_nets [list {monitor_tsk_suscnt[10]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe66]
set_property port_width 1 [get_debug_ports u_ila_0/probe66]
connect_debug_port u_ila_0/probe66 [get_nets [list {monitor_tsk_suscnt[11]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe67]
set_property port_width 1 [get_debug_ports u_ila_0/probe67]
connect_debug_port u_ila_0/probe67 [get_nets [list {monitor_tsk_suscnt[12]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe68]
set_property port_width 1 [get_debug_ports u_ila_0/probe68]
connect_debug_port u_ila_0/probe68 [get_nets [list {monitor_tsk_suscnt[13]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe69]
set_property port_width 1 [get_debug_ports u_ila_0/probe69]
connect_debug_port u_ila_0/probe69 [get_nets [list {monitor_tsk_suscnt[14]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe70]
set_property port_width 1 [get_debug_ports u_ila_0/probe70]
connect_debug_port u_ila_0/probe70 [get_nets [list {monitor_tsk_suscnt[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe71]
set_property port_width 1 [get_debug_ports u_ila_0/probe71]
connect_debug_port u_ila_0/probe71 [get_nets [list {monitor_tsk_wupcnt[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe72]
set_property port_width 1 [get_debug_ports u_ila_0/probe72]
connect_debug_port u_ila_0/probe72 [get_nets [list {monitor_tsk_wupcnt[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe73]
set_property port_width 1 [get_debug_ports u_ila_0/probe73]
connect_debug_port u_ila_0/probe73 [get_nets [list {monitor_tsk_wupcnt[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe74]
set_property port_width 1 [get_debug_ports u_ila_0/probe74]
connect_debug_port u_ila_0/probe74 [get_nets [list {monitor_tsk_wupcnt[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe75]
set_property port_width 1 [get_debug_ports u_ila_0/probe75]
connect_debug_port u_ila_0/probe75 [get_nets [list {monitor_tsk_wupcnt[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe76]
set_property port_width 1 [get_debug_ports u_ila_0/probe76]
connect_debug_port u_ila_0/probe76 [get_nets [list {monitor_tsk_wupcnt[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe77]
set_property port_width 1 [get_debug_ports u_ila_0/probe77]
connect_debug_port u_ila_0/probe77 [get_nets [list {monitor_tsk_wupcnt[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe78]
set_property port_width 1 [get_debug_ports u_ila_0/probe78]
connect_debug_port u_ila_0/probe78 [get_nets [list {monitor_tsk_wupcnt[8]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe79]
set_property port_width 1 [get_debug_ports u_ila_0/probe79]
connect_debug_port u_ila_0/probe79 [get_nets [list {monitor_tsk_wupcnt[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe80]
set_property port_width 1 [get_debug_ports u_ila_0/probe80]
connect_debug_port u_ila_0/probe80 [get_nets [list {monitor_tsk_wupcnt[10]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe81]
set_property port_width 1 [get_debug_ports u_ila_0/probe81]
connect_debug_port u_ila_0/probe81 [get_nets [list {monitor_tsk_wupcnt[11]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe82]
set_property port_width 1 [get_debug_ports u_ila_0/probe82]
connect_debug_port u_ila_0/probe82 [get_nets [list {monitor_tsk_wupcnt[12]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe83]
set_property port_width 1 [get_debug_ports u_ila_0/probe83]
connect_debug_port u_ila_0/probe83 [get_nets [list {monitor_tsk_wupcnt[13]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe84]
set_property port_width 1 [get_debug_ports u_ila_0/probe84]
connect_debug_port u_ila_0/probe84 [get_nets [list {monitor_tsk_wupcnt[14]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe85]
set_property port_width 1 [get_debug_ports u_ila_0/probe85]
connect_debug_port u_ila_0/probe85 [get_nets [list {monitor_tsk_wupcnt[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe86]
set_property port_width 1 [get_debug_ports u_ila_0/probe86]
connect_debug_port u_ila_0/probe86 [get_nets [list wb_ack_o]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe87]
set_property port_width 1 [get_debug_ports u_ila_0/probe87]
connect_debug_port u_ila_0/probe87 [get_nets [list wb_stb_i]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe88]
set_property port_width 1 [get_debug_ports u_ila_0/probe88]
connect_debug_port u_ila_0/probe88 [get_nets [list wb_we_i]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets axi4l_aclk]
