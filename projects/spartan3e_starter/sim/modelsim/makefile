

# directory 
WORK_DIR = work
PRJ_DIR  = ../..
TOP_DIR  = ../../../..
RTL_DIR  = $(TOP_DIR)/rtl
HOS_DIR  = ~/hos-v4a/sample/mips/jelly/gcc


# flags
VLOG_FLAGS =


all: soft_build $(TOP_DIR)/soft/boot_rom.v work_setup prj_compile
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_top glbl

clean:
	make -C $(HOS_DIR) -f gmake.mak mostlyclean
	rm -f *.vcd
	rm -fr $(WORK_DIR)

dbg: work_setup prj_compile
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/tb_uart_dbg.v
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_uart_dbg glbl


soft_build:
	make -C $(HOS_DIR) -f gmake.mak

soft_clean:
	make -C $(HOS_DIR) -f gmake.mak mostlyclean

$(TOP_DIR)/soft/boot_rom.v: $(HOS_DIR)/sample.bin
	$(TOP_DIR)/soft/bin2rom.pl $(HOS_DIR)/sample.bin > $(TOP_DIR)/soft/boot_rom.v
	mips-elf-objdump -D $(HOS_DIR)/sample.elf > disasm.txt



work_setup:
	vlib $(WORK_DIR)


prj_compile:
	vlog $(VLOG_FLAGS) "$(XILINX)/verilog/src/glbl.v"
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/sim/*.v
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/rtl/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/bus/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cache/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/library/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/irc/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/timer/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/gpio/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/sram/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/*.v
	vlog $(VLOG_FLAGS) $(TOP_DIR)/soft/boot_rom.v


