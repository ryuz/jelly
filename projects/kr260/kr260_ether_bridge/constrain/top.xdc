
# 25MHz
create_clock -period 40.000 -name in_clk25a -waveform {0.000 20.000} [get_ports in_clk25a]
create_clock -period 40.000 -name in_clk25b -waveform {0.000 20.000} [get_ports in_clk25b]

# 125MHz
create_clock -period 8.000 -name rgmii0_rx_clk -waveform {0.000 4.000} [get_ports rgmii0_rx_clk]
create_clock -period 8.000 -name rgmii1_rx_clk -waveform {0.000 4.000} [get_ports rgmii1_rx_clk]


set_input_delay -clock [get_clocks rgmii0_rx_clk] -min 2.000 [get_ports {rgmii0_rx_ctrl {rgmii0_rx_d[*]}}]
set_input_delay -clock [get_clocks rgmii0_rx_clk] -min 2.000 [get_ports {rgmii0_rx_ctrl {rgmii0_rx_d[*]}}] -clock_fall -add_delay
set_input_delay -clock [get_clocks rgmii0_rx_clk] -max 3.500 [get_ports {rgmii0_rx_ctrl {rgmii0_rx_d[*]}}]
set_input_delay -clock [get_clocks rgmii0_rx_clk] -max 3.500 [get_ports {rgmii0_rx_ctrl {rgmii0_rx_d[*]}}] -clock_fall -add_delay

set_input_delay -clock [get_clocks rgmii1_rx_clk] -min 2.000 [get_ports {rgmii1_rx_ctrl {rgmii1_rx_d[*]}}]
set_input_delay -clock [get_clocks rgmii1_rx_clk] -min 2.000 [get_ports {rgmii1_rx_ctrl {rgmii1_rx_d[*]}}] -clock_fall -add_delay
set_input_delay -clock [get_clocks rgmii1_rx_clk] -max 3.500 [get_ports {rgmii1_rx_ctrl {rgmii1_rx_d[*]}}]
set_input_delay -clock [get_clocks rgmii1_rx_clk] -max 3.500 [get_ports {rgmii1_rx_ctrl {rgmii1_rx_d[*]}}] -clock_fall -add_delay


# fan
set_property PACKAGE_PIN A12 [get_ports fan_en]
set_property IOSTANDARD LVCMOS18 [get_ports fan_en]

# clock
set_property PACKAGE_PIN C3 [get_ports in_clk25a]
set_property PACKAGE_PIN L3 [get_ports in_clk25b]
set_property IOSTANDARD LVCMOS18 [get_ports in_clk25a]
set_property IOSTANDARD LVCMOS18 [get_ports in_clk25b]


# LED
set_property PACKAGE_PIN F8 [get_ports {led[0]}]
set_property PACKAGE_PIN E8 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]

# RGMII_0 (DP83867)
set_property PACKAGE_PIN B1 [get_ports rgmii0_reset_n]
set_property PACKAGE_PIN D4 [get_ports rgmii0_rx_clk]
set_property PACKAGE_PIN A2 [get_ports rgmii0_gtx_clk]
set_property PACKAGE_PIN G3 [get_ports rgmii0_mdc]
set_property PACKAGE_PIN F3 [get_ports rgmii0_mdio]
set_property PACKAGE_PIN A4 [get_ports rgmii0_rx_ctrl]
set_property PACKAGE_PIN A1 [get_ports {rgmii0_rx_d[0]}]
set_property PACKAGE_PIN B3 [get_ports {rgmii0_rx_d[1]}]
set_property PACKAGE_PIN A3 [get_ports {rgmii0_rx_d[2]}]
set_property PACKAGE_PIN B4 [get_ports {rgmii0_rx_d[3]}]
set_property PACKAGE_PIN F1 [get_ports rgmii0_tx_ctrl]
set_property PACKAGE_PIN E1 [get_ports {rgmii0_tx_d[0]}]
set_property PACKAGE_PIN D1 [get_ports {rgmii0_tx_d[1]}]
set_property PACKAGE_PIN F2 [get_ports {rgmii0_tx_d[2]}]
set_property PACKAGE_PIN E2 [get_ports {rgmii0_tx_d[3]}]
set_property PACKAGE_PIN E4 [get_ports {rgmii0_led[0]}]
set_property PACKAGE_PIN E3 [get_ports {rgmii0_led[1]}]
set_property PACKAGE_PIN C1 [get_ports {rgmii0_led[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii0_reset_n]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii0_rx_clk]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii0_gtx_clk]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii0_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii0_mdio]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii0_rx_ctrl]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_rx_d[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_rx_d[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_rx_d[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_rx_d[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii0_tx_ctrl]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_tx_d[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_tx_d[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_tx_d[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_tx_d[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii0_led[2]}]

# RGMII_1 (DP83867)
set_property PACKAGE_PIN K1 [get_ports rgmii1_reset_n]
set_property PACKAGE_PIN K4 [get_ports rgmii1_rx_clk]
set_property PACKAGE_PIN J1 [get_ports rgmii1_gtx_clk]
set_property PACKAGE_PIN R8 [get_ports rgmii1_mdc]
set_property PACKAGE_PIN T8 [get_ports rgmii1_mdio]
set_property PACKAGE_PIN H3 [get_ports rgmii1_rx_ctrl]
set_property PACKAGE_PIN H1 [get_ports {rgmii1_rx_d[0]}]
set_property PACKAGE_PIN K2 [get_ports {rgmii1_rx_d[1]}]
set_property PACKAGE_PIN J2 [get_ports {rgmii1_rx_d[2]}]
set_property PACKAGE_PIN H4 [get_ports {rgmii1_rx_d[3]}]
set_property PACKAGE_PIN Y8 [get_ports rgmii1_tx_ctrl]
set_property PACKAGE_PIN U9 [get_ports {rgmii1_tx_d[0]}]
set_property PACKAGE_PIN V9 [get_ports {rgmii1_tx_d[1]}]
set_property PACKAGE_PIN U8 [get_ports {rgmii1_tx_d[2]}]
set_property PACKAGE_PIN V8 [get_ports {rgmii1_tx_d[3]}]
set_property PACKAGE_PIN R7 [get_ports {rgmii1_led[0]}]
set_property PACKAGE_PIN T7 [get_ports {rgmii1_led[1]}]
set_property PACKAGE_PIN L1 [get_ports {rgmii1_led[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii1_reset_n]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii1_rx_clk]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii1_gtx_clk]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii1_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii1_mdio]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii1_rx_ctrl]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_rx_d[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_rx_d[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_rx_d[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_rx_d[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii1_tx_ctrl]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_tx_d[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_tx_d[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_tx_d[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_tx_d[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii1_led[2]}]
