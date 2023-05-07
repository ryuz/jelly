

# directory 
WORK_DIR = work
PRJ_DIR  = ../..
TOP_DIR  = ../../../..
RTL_DIR  = $(TOP_DIR)/rtl


# flags
VLOG_FLAGS =


all: work_setup prj_compile
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_top glbl

clean:
	make -C $(HOS_DIR) -f gmake.mak mostlyclean
	rm -f *.vcd
	rm -fr $(WORK_DIR)


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
	vlog $(VLOG_FLAGS) $(RTL_DIR)/extbus/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/*.v


