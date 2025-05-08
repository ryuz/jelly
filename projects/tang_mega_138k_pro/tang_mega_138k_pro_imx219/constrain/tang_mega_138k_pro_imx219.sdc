
# 50MHz
create_clock -name in_clk50 -period 20.000 -waveform {0 10.000} [get_ports {in_clk50}] -add
