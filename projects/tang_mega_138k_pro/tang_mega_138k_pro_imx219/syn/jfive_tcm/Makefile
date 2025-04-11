


DEVICE_NAME = GW5AST-LV138FPG676AES

TOP_MODULE = jfive_tcm
OUTPUT_BASE_NAME = $(TOP_MODULE)

VG_FILE  = impl/gwsynthesis/$(TOP_MODULE).vg
MEM_FILE = mem.hex

TOP_DIR = ../../../../..
RTL_DIR = ../../rtl

# include
#JELLY_TOP_DIR = $(TOP_DIR)
#-include $(JELLY_TOP_DIR)/include/make/def_sources.inc

CONSTRAIN_DIR = ../../constrain

VLOG_SOURCES  = ./jfive_tcm.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_ram_dualport.sv

SDC_SOURCES =
CST_SOURCES =

# for tcl script
export DEVICE_NAME
export DEVICE_VERSION
export TOP_MODULE
export OUTPUT_BASE_NAME
export VLOG_SOURCES
export SDC_SOURCES
export CST_SOURCES
export DISABLE_IO_INSERTION = 1
export RUN = syn
export WSLENV=DEVICE_NAME:DEVICE_VERSION:TOP_MODULE:OUTPUT_BASE_NAME:VLOG_SOURCES:SDC_SOURCES:CST_SOURCES:USE_CPU_AS_GPIO:DISABLE_IO_INSERTION:RUN

.PHONY: all
all: $(VG_FILE)

.PHONY: jfive
jfive:
	make -C ../../jfive/
	cp ../../jfive/mem.hex ./$(MEM_FILE)

$(VG_FILE): jfive $(VLOG_SOURCES) $(CST_SOURCES) $(MEM_FILE)
	gw_sh $(TOP_DIR)/scripts/gowin_build.tcl

.PHONY: clean
clean:
	rm -fr impl
	rm -f $(MEM_FILE)
