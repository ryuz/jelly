

# directory 
WORK_DIR = work
TOP_DIR  = ../../../..
PRJ_DIR  = ../..
RTL_DIR  = $(TOP_DIR)/rtl


# flags
VLOG_FLAGS =


all: work_setup rtl_compile
	cp $(PRJ_DIR)/rtl/*.dat .
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_i2c glbl

clean:
	rm -f *.vcd
	rm -fr $(WORK_DIR)

work_setup:
	vlib $(WORK_DIR)

rtl_compile:
	vlog $(VLOG_FLAGS) "$(XILINX)/verilog/src/glbl.v"
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/rtl/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/bus/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/library/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/cpu/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/irc/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/timer/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/gpio/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/uart/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/i2c/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/sram/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/ddr_sdram/*.v

