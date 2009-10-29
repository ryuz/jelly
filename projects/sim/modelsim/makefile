

# directory 
WORK_DIR = work
TOP_DIR  = ../../..
RTL_DIR  = $(TOP_DIR)/rtl
TB_DIR   = $(TOP_DIR)/testbench


# flags
VLOG_FLAGS =


all: work_setup rtl_compile
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_wishbone_cache glbl

clean:
	rm -f *.vcd
	rm -fr $(WORK_DIR)


work_setup:
	vlib $(WORK_DIR)

rtl_compile:
	vlog $(VLOG_FLAGS) "$(XILINX)/verilog/src/glbl.v"
	vlog $(VLOG_FLAGS) $(TB_DIR)/cache/tb_wishbone_cache.v
	vlog $(VLOG_FLAGS) $(TB_DIR)/model/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/binary_to_graycode.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/graycode_to_binary.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/fifo_fwtf_async.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/ram_singleport.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/ram_dualport.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/wishbone_clk2x.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/wishbone_bridge.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/bus/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_adder.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_alu.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_core.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_muldiv.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_multiplier.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_divider.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_idu.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_wishbone.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_wishbone_cpubus.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_wishbone_arbiter.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_cop0.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_gpr.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_shifter.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_top_simple.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_dbu.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_dbg_comm.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/irc/irc.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/irc/irc_factor.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/timer/timer.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/gpio/gpio.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_debugger.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_core.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_tx.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_rx.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/sram/sram.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram_init.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram_io.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram_oddr.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram_out.v
	vlog $(VLOG_FLAGS) $(TOP_DIR)/soft/boot_rom.v


