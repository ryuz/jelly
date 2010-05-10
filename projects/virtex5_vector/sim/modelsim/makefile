

# directory 
WORK_DIR = work
PRJ_DIR  = ../..
TOP_DIR  = ../../../..
RTL_DIR  = $(TOP_DIR)/rtl


# flags
VLOG_FLAGS =


all: work_setup prj_compile
	vsim -c -wlf vsim.wlf -do "run -all" -L xilinxcorelib_ver -L unisims_ver -lib work tb_jelly_vector_mac glbl

clean:
	make -C $(HOS_DIR) -f gmake.mak mostlyclean
	rm -f *.vcd
	rm -fr $(WORK_DIR)


work_setup:
	vlib $(WORK_DIR)


prj_compile:
	vlog $(VLOG_FLAGS) "$(XILINX)/verilog/src/glbl.v"
	vlog $(VLOG_FLAGS) $(PRJ_DIR)/sim/*.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/vector_alu/jelly_mac18x18.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/vector_alu/jelly_pipeline_ff.v
	vlog $(VLOG_FLAGS) $(RTL_DIR)/vector_alu/jelly_vector_mac.v


