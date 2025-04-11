
# 50MHz
create_clock -name clk -period 20.000 -waveform {0 10.000} [get_ports {clk}] -add
