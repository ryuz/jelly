# set_property CONFIG_MODE SPIx4 [current_design]

# Clock
create_clock -period 20.000 -name in_clk50 -waveform {0.000 10.000} [get_ports in_clk50]
create_clock -period 13.888 -name in_clk72 -waveform {0.000  6.944} [get_ports in_clk72]

# 720Mbps (360MHz)
create_clock -period 2.777 -name python_clk_p -waveform {0.000 1.388} [get_ports python_clk_p]

# 1250Mbps : 312.5MHz 3.2ns

# in_clk72               :  72MHz 13.888ns
# python_clk_p           : 360MHz  2.777ns
# clk_out1_clk_mipi_core : 200MHz  5.000ns
# dphy_txbyteclkhs       : 125Mhz  8.000ns


#set_max_delay -datapath_only -from [get_clocks in_clk72] -to [get_clocks clk_out1_clk_mipi_core] 10.000
#set_max_delay -datapath_only -from [get_clocks in_clk72] -to [get_clocks python_clk] 10.000
#set_max_delay -datapath_only -from [get_clocks in_clk72] -to [get_clocks python_clk_p] 10.000
#set_max_delay -datapath_only -from [get_clocks python_clk] -to [get_clocks in_clk72] 10.000

set_max_delay -datapath_only -from [get_clocks clk_out1_clk_mipi_core] -to [get_clocks dphy_txbyteclkhs]       5.200
set_max_delay -datapath_only -from [get_clocks dphy_txbyteclkhs]       -to [get_clocks python_clk_p]           2.777
set_max_delay -datapath_only -from [get_clocks in_clk72]               -to [get_clocks clk_out1_clk_mipi_core] 5.000
set_max_delay -datapath_only -from [get_clocks in_clk72]               -to [get_clocks python_clk_p]           2.777
set_max_delay -datapath_only -from [get_clocks python_clk_p]           -to [get_clocks dphy_txbyteclkhs]       2.777
set_max_delay -datapath_only -from [get_clocks python_clk_p]           -to [get_clocks in_clk72]               2.777


# clock
set_property PACKAGE_PIN H4 [get_ports in_clk50]
set_property IOSTANDARD LVCMOS18 [get_ports in_clk50]

set_property PACKAGE_PIN G11 [get_ports in_clk72]
set_property IOSTANDARD LVCMOS33 [get_ports in_clk72]

# LED
set_property PACKAGE_PIN P12 [get_ports {led[0]}]
set_property PACKAGE_PIN P13 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

# PMOD
set_property PACKAGE_PIN A12 [get_ports {pmod[0]}]
set_property PACKAGE_PIN A13 [get_ports {pmod[1]}]
set_property PACKAGE_PIN M13 [get_ports {pmod[2]}]
set_property PACKAGE_PIN L14 [get_ports {pmod[3]}]
set_property PACKAGE_PIN H11 [get_ports {pmod[4]}]
set_property PACKAGE_PIN H12 [get_ports {pmod[5]}]
set_property PACKAGE_PIN N14 [get_ports {pmod[6]}]
set_property PACKAGE_PIN M14 [get_ports {pmod[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod[7]}]

set_property PACKAGE_PIN P10 [get_ports mipi_reset_n]
set_property PACKAGE_PIN N10 [get_ports mipi_clk]
set_property PACKAGE_PIN P11 [get_ports mipi_scl]
set_property PACKAGE_PIN N11 [get_ports mipi_sda]

set_property IOSTANDARD LVCMOS33 [get_ports mipi_reset_n]
set_property PULLTYPE PULLDOWN [get_ports mipi_reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports mipi_clk]
set_property IOSTANDARD LVCMOS33 [get_ports mipi_scl]
set_property IOSTANDARD LVCMOS33 [get_ports mipi_sda]

set_property PACKAGE_PIN M5 [get_ports mipi_clk_lp_p]
set_property PACKAGE_PIN M4 [get_ports mipi_clk_lp_n]
set_property PACKAGE_PIN P5 [get_ports mipi_clk_hs_p]
set_property PACKAGE_PIN N4 [get_ports mipi_clk_hs_n]
set_property PACKAGE_PIN M1 [get_ports {mipi_data_lp_p[0]}]
set_property PACKAGE_PIN L1 [get_ports {mipi_data_lp_n[0]}]
set_property PACKAGE_PIN P2 [get_ports {mipi_data_hs_p[0]}]
set_property PACKAGE_PIN N1 [get_ports {mipi_data_hs_n[0]}]
set_property PACKAGE_PIN M3 [get_ports {mipi_data_lp_p[1]}]
set_property PACKAGE_PIN M2 [get_ports {mipi_data_lp_n[1]}]
set_property PACKAGE_PIN P4 [get_ports {mipi_data_hs_p[1]}]
set_property PACKAGE_PIN P3 [get_ports {mipi_data_hs_n[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports mipi_clk_lp_p]
set_property IOSTANDARD LVCMOS18 [get_ports mipi_clk_lp_n]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports mipi_clk_hs_p]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports mipi_clk_hs_n]
set_property IOSTANDARD LVCMOS18 [get_ports {mipi_data_lp_p[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mipi_data_lp_n[0]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {mipi_data_hs_p[0]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {mipi_data_hs_n[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mipi_data_lp_p[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mipi_data_lp_n[1]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {mipi_data_hs_p[1]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {mipi_data_hs_n[1]}]


# PYTHON300
set_property PACKAGE_PIN D12 [get_ports sensor_pwr_en_vdd18]
set_property PACKAGE_PIN C14 [get_ports sensor_pwr_en_vdd33]
set_property PACKAGE_PIN D13 [get_ports sensor_pwr_en_pix]
set_property PACKAGE_PIN H13 [get_ports sensor_pgood]
set_property IOSTANDARD LVCMOS33 [get_ports sensor_pwr_en_vdd18]
set_property IOSTANDARD LVCMOS33 [get_ports sensor_pwr_en_vdd33]
set_property IOSTANDARD LVCMOS33 [get_ports sensor_pwr_en_pix]
set_property IOSTANDARD LVCMOS33 [get_ports sensor_pgood]
set_property PULLTYPE PULLDOWN [get_ports sensor_pgood]

set_property PACKAGE_PIN D14 [get_ports python_reset_n]
set_property PACKAGE_PIN J13 [get_ports python_clk_pll]
set_property PACKAGE_PIN E12 [get_ports python_ss_n]
set_property PACKAGE_PIN E13 [get_ports python_mosi]
set_property PACKAGE_PIN F13 [get_ports python_miso]
set_property PACKAGE_PIN F12 [get_ports python_sck]
set_property PACKAGE_PIN F14 [get_ports {python_trigger[0]}]
set_property PACKAGE_PIN G14 [get_ports {python_trigger[1]}]
set_property PACKAGE_PIN J11 [get_ports {python_trigger[2]}]
set_property PACKAGE_PIN J12 [get_ports {python_monitor[0]}]
set_property PACKAGE_PIN H14 [get_ports {python_monitor[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports python_reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports python_clk_pll]
set_property IOSTANDARD LVCMOS33 [get_ports python_ss_n]
set_property IOSTANDARD LVCMOS33 [get_ports python_mosi]
set_property IOSTANDARD LVCMOS33 [get_ports python_miso]
set_property IOSTANDARD LVCMOS33 [get_ports python_sck]
set_property IOSTANDARD LVCMOS33 [get_ports {python_trigger[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {python_trigger[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {python_trigger[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {python_monitor[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {python_monitor[1]}]

set_property PACKAGE_PIN D1 [get_ports python_clk_p]
set_property PACKAGE_PIN C1 [get_ports python_clk_n]
set_property PACKAGE_PIN B2 [get_ports {python_data_p[0]}]
set_property PACKAGE_PIN B1 [get_ports {python_data_n[0]}]
set_property PACKAGE_PIN E2 [get_ports {python_data_p[1]}]
set_property PACKAGE_PIN D2 [get_ports {python_data_n[1]}]
set_property PACKAGE_PIN E4 [get_ports {python_data_p[2]}]
set_property PACKAGE_PIN D4 [get_ports {python_data_n[2]}]
set_property PACKAGE_PIN C5 [get_ports {python_data_p[3]}]
set_property PACKAGE_PIN C4 [get_ports {python_data_n[3]}]
set_property PACKAGE_PIN B5 [get_ports python_sync_p]
set_property PACKAGE_PIN A5 [get_ports python_sync_n]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports python_clk_p]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports python_clk_n]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {python_data_p[0]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {python_data_n[0]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {python_data_p[1]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {python_data_n[1]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {python_data_p[2]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {python_data_n[2]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {python_data_p[3]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {python_data_n[3]}]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports python_sync_p]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports python_sync_n]


# set_property PACKAGE_PIN C12 [get_ports mipi_reset_n]
# set_property PACKAGE_PIN F12 [get_ports mipi_gpio]
# set_property PACKAGE_PIN E12 [get_ports mipi_sck]
# set_property PACKAGE_PIN D12 [get_ports mipi_sda]
# set_property IOSTANDARD LVCMOS33 [get_ports mipi_reset_n]
# set_property IOSTANDARD LVCMOS33 [get_ports mipi_gpio]
# set_property IOSTANDARD LVCMOS33 [get_ports mipi_sck]
# set_property IOSTANDARD LVCMOS33 [get_ports mipi_sda]
# set_property PACKAGE_PIN D3 [get_ports mipi_clk_lp_p]
# set_property PACKAGE_PIN C3 [get_ports mipi_clk_lp_n]
# set_property PACKAGE_PIN A4 [get_ports mipi_clk_hs_p]
# set_property PACKAGE_PIN A3 [get_ports mipi_clk_hs_n]
# set_property PACKAGE_PIN B3 [get_ports {mipi_data_lp_p[0]}]
# set_property PACKAGE_PIN A2 [get_ports {mipi_data_lp_n[0]}]
# set_property PACKAGE_PIN B5 [get_ports {mipi_data_hs_p[0]}]
# set_property PACKAGE_PIN A5 [get_ports {mipi_data_hs_n[0]}]
# set_property PACKAGE_PIN B2 [get_ports {mipi_data_lp_p[1]}]
# set_property PACKAGE_PIN B1 [get_ports {mipi_data_lp_n[1]}]
# set_property PACKAGE_PIN C5 [get_ports {mipi_data_hs_p[1]}]
# set_property PACKAGE_PIN C4 [get_ports {mipi_data_hs_n[1]}]
# set_property IOSTANDARD LVCMOS18 [get_ports mipi_clk_lp_p]
# set_property IOSTANDARD LVCMOS18 [get_ports mipi_clk_lp_n]
# set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports mipi_clk_hs_p]
# set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports mipi_clk_hs_n]
# set_property IOSTANDARD LVCMOS18 [get_ports {mipi_data_lp_p[0]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {mipi_data_lp_n[0]}]
# set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {mipi_data_hs_p[0]}]
# set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {mipi_data_hs_n[0]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {mipi_data_lp_p[1]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {mipi_data_lp_n[1]}]
# set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {mipi_data_hs_p[1]}]
# set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {mipi_data_hs_n[1]}]


