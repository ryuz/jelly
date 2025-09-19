# set_property CONFIG_MODE SPIx4 [current_design]

# QSPI x4 用に設定
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 16 [current_design]

# write_cfgmem  -format mcs -size 2 -interface spix4 -loadbit "up 0x0 rtcl_p3s7_hs.runs/impl_1/rtcl_p3s7_hs.bit" -file rtcl_p3s7_hs.runs/impl_1/rtcl_p3s7_hs.top.mcs

# Clock
create_clock -period 20.000 -name in_clk50 -waveform {0.000 10.000} [get_ports in_clk50]
create_clock -period 13.888 -name in_clk72 -waveform {0.000 6.944} [get_ports in_clk72]

# 720Mbps (360MHz)
create_clock -period 2.777 -name python_clk_p -waveform {0.000 1.388} [get_ports python_clk_p]

# MIPI  1250Mbps : 8bit@156.25MHz 6.400ns
# MIPI   950Mbps : 8bit@118.75MHz 8.421ns

# in_clk72               :  50.00MHz 20.000ns
# in_clk72               :  72.00MHz 13.888ns
# python_clk_p           : 360.00MHz  2.777ns
# python_clk             :  72.00MHz 13.888ns
# clk_out1_clk_mipi_core : 200.00MHz  5.000ns
# dphy_clk               : 156.25MHz  6.400ns

set_clock_groups -asynchronous -group in_clk50 -group in_clk72 -group python_clk_p -group python_clk -group dphy_clk -group clk_out1_clk_mipi_core
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

set_property PACKAGE_PIN P10 [get_ports mipi_gpio0]
set_property PACKAGE_PIN N10 [get_ports mipi_gpio1]
set_property PACKAGE_PIN P11 [get_ports mipi_scl]
set_property PACKAGE_PIN N11 [get_ports mipi_sda]

set_property IOSTANDARD LVCMOS33 [get_ports mipi_gpio0]
set_property PULLTYPE PULLDOWN [get_ports mipi_gpio0]
set_property IOSTANDARD LVCMOS33 [get_ports mipi_gpio1]
set_property PULLTYPE PULLDOWN [get_ports mipi_gpio1]
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



