

# target
TARGET = tb_top_sim

# directory 
WORK_DIR = work
PRJ_DIR  = ../..
TOP_DIR  = ../../../..
RTL_DIR  = $(TOP_DIR)/rtl
HOS_DIR  = ~/hos-v4a/sample/mips/jelly/gcc


# tools
VLOGC    = vlogcomp
FUSE     = fuse

# flags
VLOG_FLAGS = -work work


all: $(TOP_DIR)/soft/boot_rom.v prj_compile run
	$(FUSE) -top tb_top -top glbl -lib unimacro_ver -lib unisims_ver -lib xilinxcorelib_ver -o $(TARGET)

run:
	./$(TARGET) -tclbatch tb_top_cmd.txt

clean:
	make -C $(HOS_DIR) -f gmake.mak mostlyclean
	rm -f *.vcd
	rm -fr $(WORK_DIR)

soft_build:
	make -C $(HOS_DIR) -f gmake.mak

soft_clean:
	make -C $(HOS_DIR) -f gmake.mak mostlyclean

$(TOP_DIR)/soft/boot_rom.v: $(HOS_DIR)/sample.bin
	$(TOP_DIR)/soft/bin2rom.pl $(HOS_DIR)/sample.bin > $(TOP_DIR)/soft/boot_rom.v
	mips-elf-objdump -D $(HOS_DIR)/sample.elf > disasm.txt


prj_compile:
	$(VLOGC) $(VLOG_FLAGS) "$(XILINX)/verilog/src/glbl.v"
	$(VLOGC) $(VLOG_FLAGS) $(PRJ_DIR)/sim/tb_top.v
	$(VLOGC) $(VLOG_FLAGS) $(PRJ_DIR)/sim/ddr.v
	$(VLOGC) $(VLOG_FLAGS) $(PRJ_DIR)/rtl/top.v
	$(VLOGC) $(VLOG_FLAGS) $(PRJ_DIR)/rtl/clkgen.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/common/binary_to_graycode.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/common/graycode_to_binary.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/common/fifo_fwtf_async.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/common/ram_singleport.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/common/ram_dualport.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/common/wishbone_clk2x.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/common/wishbone_bridge.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_adder.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_alu.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_core.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_muldiv.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_multiplier.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_divider.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_idu.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_wishbone.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_wishbone_cpubus.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_wishbone_arbiter.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_cop0.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_gpr.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_shifter.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_top_simple.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_dbu.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_dbg_comm.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/irc/irc.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/irc/irc_factor.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/timer/timer.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/uart/uart.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_debugger.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_core.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_tx.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_rx.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/sram/sram.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram_init.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram_io.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram_oddr.v
	$(VLOGC) $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/ddr_sdram_out.v
	$(VLOGC) $(VLOG_FLAGS) $(TOP_DIR)/soft/boot_rom.v


