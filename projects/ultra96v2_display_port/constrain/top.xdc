
set_max_delay -datapath_only -from [get_clocks clk_pl_0] -to [get_clocks clk_pl_1]  6.666
set_max_delay -datapath_only -from [get_clocks clk_pl_1] -to [get_clocks clk_pl_0]  6.666

set_property PACKAGE_PIN B9 [get_ports {led[1]}]
set_property PACKAGE_PIN A9 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
