

# directory 
WORK_DIR = work
PRJ_DIR  = ../..
TOP_DIR  = ../../..
RTL_DIR  = $(TOP_DIR)/rtl
HOS_DIR  = ~/hos-v4a/aplfw/sample/mips/jelly/gcc

# flags
VLOG_FLAGS =


all: soft_build disasm soft.hex work_setup prj_compile
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_top glbl

irc: work_setup prj_compile
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/sim/tb_irc.v
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_irc glbl


clean:
	make -C $(HOS_DIR) -f gmake.mak mostlyclean
	rm -f *.vcd
	rm -fr $(WORK_DIR)

dbg: work_setup prj_compile
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/tb_uart_dbg.v
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_uart_dbg glbl


soft_build:
	make -C $(HOS_DIR) -f gmake.mak MEMMAP=ram

soft_clean:
	make -C $(HOS_DIR) -f gmake.mak MEMMAP=ram mostlyclean

soft.hex: $(HOS_DIR)/sample_ram.bin
	$(TOP_DIR)/soft/bin2hex.pl $(HOS_DIR)/sample_ram.bin > soft.hex

disasm:
	mips-elf-objdump -D $(HOS_DIR)/sample_ram.elf > disasm.txt


work_setup:
	vlib $(WORK_DIR)


#	vlog $(VLOG_FLAGS) "$(XILINX) C:/Xilinx/10.1/ISE/verilog/src/glbl.v"

prj_compile:
	vlog $(VLOG_FLAGS) "$(XILINX)/verilog/src/glbl.v"
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/sim/tb_top.v
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/sim/ram_model.v
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/rtl/top.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/binary_to_graycode.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/graycode_to_binary.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/pipeline_fifo_async.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/ram_dualport.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/ram_dualport_xilinx.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/common/wishbone_bridge.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_adder.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_alu.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_core.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_divider.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_idu.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_lsu.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_muldiv.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_cop0.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_gpr.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_shifter.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_dbu.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/cpu_top.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/dbg_uart.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/irc/irc.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/irc/irc_factor.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/timer/timer.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_core.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_tx.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/uart_rx.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/asram/asram.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/sram/sram.v
	vlog $(VLOG_FLAGS) $(TOP_DIR)/soft/boot_rom.v


