

################################
# Timing
################################

# in_clk128
create_clock -period 8.000 -name in_clk125 -waveform {0.000 4.000} [get_ports in_clk125]

set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out3_design_1_clk_wiz_0_0] 4.000
set_max_delay -datapath_only -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_out4_design_1_clk_wiz_0_0] 5.000

#set_max_delay -datapath_only -from [get_clocks clk_out4_design_1_clk_wiz_0_0] -to [get_clocks dbg_hub/inst/BSCANID.u_xsdbm_id/SWITCH_N_EXT_BSCAN.bscan_inst/SERIES7_BSCAN.bscan_inst/TCK] 4.000
#set_max_delay -datapath_only -from [get_clocks dbg_hub/inst/BSCANID.u_xsdbm_id/SWITCH_N_EXT_BSCAN.bscan_inst/SERIES7_BSCAN.bscan_inst/TCK] -to [get_clocks clk_out4_design_1_clk_wiz_0_0] 4.000


#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets i_rmii_to_pmod/i_iobuf_pmod_a6/O]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets i_rmii_to_pmod/i_iobuf_pmod_b6/O]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets i_rmii_to_pmod/i_iobuf_pmod_d6/O]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets i_rmii_to_pmod/i_iobuf_pmod_e6/O]


set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets i_iobuf_pmod_a7/O]


################################
# I/O
################################

# in_clk128
set_property PACKAGE_PIN L16 [get_ports in_clk125]
set_property IOSTANDARD LVCMOS33 [get_ports in_clk125]


# DIP-SW
set_property PACKAGE_PIN G15 [get_ports {dip_sw[0]}]
set_property PACKAGE_PIN P15 [get_ports {dip_sw[1]}]
set_property PACKAGE_PIN W13 [get_ports {dip_sw[2]}]
set_property PACKAGE_PIN T16 [get_ports {dip_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dip_sw[3]}]


# PUSH-SW
set_property PACKAGE_PIN R18 [get_ports {push_sw[0]}]
set_property PACKAGE_PIN P16 [get_ports {push_sw[1]}]
set_property PACKAGE_PIN V16 [get_ports {push_sw[2]}]
set_property PACKAGE_PIN Y16 [get_ports {push_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {push_sw[3]}]

# LED
set_property PACKAGE_PIN M14 [get_ports {led[0]}]
set_property PACKAGE_PIN D18 [get_ports {led[3]}]
set_property PACKAGE_PIN G14 [get_ports {led[2]}]
set_property PACKAGE_PIN M15 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]


# PMOD_A
set_property PACKAGE_PIN N15 [get_ports {pmod_a[0]}]
set_property PACKAGE_PIN L14 [get_ports {pmod_a[1]}]
set_property PACKAGE_PIN K16 [get_ports {pmod_a[2]}]
set_property PACKAGE_PIN K14 [get_ports {pmod_a[3]}]
set_property PACKAGE_PIN N16 [get_ports {pmod_a[4]}]
set_property PACKAGE_PIN L15 [get_ports {pmod_a[5]}]
set_property PACKAGE_PIN J16 [get_ports {pmod_a[6]}]
set_property PACKAGE_PIN J14 [get_ports {pmod_a[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_a[7]}]

# PMOD_B
set_property PACKAGE_PIN T20 [get_ports {pmod_b[0]}]
set_property PACKAGE_PIN U20 [get_ports {pmod_b[1]}]
set_property PACKAGE_PIN V20 [get_ports {pmod_b[2]}]
set_property PACKAGE_PIN W20 [get_ports {pmod_b[3]}]
set_property PACKAGE_PIN Y18 [get_ports {pmod_b[4]}]
set_property PACKAGE_PIN Y19 [get_ports {pmod_b[5]}]
set_property PACKAGE_PIN W18 [get_ports {pmod_b[6]}]
set_property PACKAGE_PIN W19 [get_ports {pmod_b[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_b[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_b[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_b[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_b[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_b[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_b[7]}]

# PMOD_C
set_property PACKAGE_PIN V15 [get_ports {pmod_c[0]}]
set_property PACKAGE_PIN W15 [get_ports {pmod_c[1]}]
set_property PACKAGE_PIN T11 [get_ports {pmod_c[2]}]
set_property PACKAGE_PIN T10 [get_ports {pmod_c[3]}]
set_property PACKAGE_PIN W14 [get_ports {pmod_c[4]}]
set_property PACKAGE_PIN Y14 [get_ports {pmod_c[5]}]
set_property PACKAGE_PIN T12 [get_ports {pmod_c[6]}]
set_property PACKAGE_PIN U12 [get_ports {pmod_c[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_c[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_c[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_c[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_c[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_c[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_c[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_c[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_c[7]}]

# PMOD_D
set_property PACKAGE_PIN T14 [get_ports {pmod_d[0]}]
set_property PACKAGE_PIN T15 [get_ports {pmod_d[1]}]
set_property PACKAGE_PIN P14 [get_ports {pmod_d[2]}]
set_property PACKAGE_PIN R14 [get_ports {pmod_d[3]}]
set_property PACKAGE_PIN U14 [get_ports {pmod_d[4]}]
set_property PACKAGE_PIN U15 [get_ports {pmod_d[5]}]
set_property PACKAGE_PIN V17 [get_ports {pmod_d[6]}]
set_property PACKAGE_PIN V18 [get_ports {pmod_d[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_d[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_d[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_d[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_d[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_d[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_d[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_d[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_d[7]}]

# PMOD_E
set_property PACKAGE_PIN V12 [get_ports {pmod_e[0]}]
set_property PACKAGE_PIN W16 [get_ports {pmod_e[1]}]
set_property PACKAGE_PIN J15 [get_ports {pmod_e[2]}]
set_property PACKAGE_PIN H15 [get_ports {pmod_e[3]}]
set_property PACKAGE_PIN V13 [get_ports {pmod_e[4]}]
set_property PACKAGE_PIN U17 [get_ports {pmod_e[5]}]
set_property PACKAGE_PIN T17 [get_ports {pmod_e[6]}]
set_property PACKAGE_PIN Y17 [get_ports {pmod_e[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_e[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_e[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_e[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_e[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_e[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_e[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_e[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_e[7]}]


