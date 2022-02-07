
# setting
export HLS_TARGET   = video_filter
export HLS_SOLUTION = solution_1
export DEVICE_PART  = xczu3eg-sbva484-1-i
export CLOCK_PERIOD = 4.0

export CSIM_OPTIONS  ?= 
export COSIM_OPTIONS ?= -trace_level all -wave_debug


# Ubuntu の場合下記が必要？
# export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

# tools
HLS_TOOL = vitis_hls
#HLS_TOOL = vivado_hls

# directories
TOP_DIR       = ../../..
SOURCE_DIR    = src
TESTBENCH_DIR = testbench
TARGET_DIR    = $(HLS_TARGET)/$(HLS_SOLUTION)
CSIM_DIR      = $(TARGET_DIR)/csim
SYN_DIR       = $(TARGET_DIR)/syn
COSIM_DIR     = $(TARGET_DIR)/sim
IMPL_DIR      = $(TARGET_DIR)/impl
EXPORT_ZIP    = $(IMPL_DIR)/export.zip

# flags
export SOURCE_FLAGS    = -std=c++14 -I$(TOP_DIR)/include -I$(SOURCE_DIR)
export TESTBENCH_FLAGS = -std=c++14 -I$(TOP_DIR)/include -I$(SOURCE_DIR) -I$(TESTBENCH_DIR)

# source
SOURCES = $(SOURCE_DIR)/video_filter.cpp
export SOURCES

# testbanch
TESTBENCHS = $(TESTBENCH_DIR)/tb_video_filter.cpp
export TESTBENCHS

# rules
.PHONY: all
all: $(EXPORT_ZIP)

$(TARGET_DIR): Makefile
	-rm -rf $(HLS_TARGET)
	$(HLS_TOOL) $(TOP_DIR)/scripts/hls_create_project.tcl

$(EXPORT_ZIP): $(TARGET_DIR) $(SOURCES)
	$(HLS_TOOL) $(TOP_DIR)/scripts/hls_csynth.tcl

.PHONY: clean
clean:
	-rm -rf $(HLS_TARGET)
	-rm -f *.log


.PHONY: create
create: $(TARGET_DIR)

.PHONY: csynth
csynth: $(EXPORT_ZIP)

.PHONY: csim
csim: $(TARGET_DIR)
	$(HLS_TOOL) $(TOP_DIR)/scripts/hls_csim.tcl

.PHONY: cosim
cosim: $(TARGET_DIR) $(EXPORT_ZIP)
	$(HLS_TOOL) $(TOP_DIR)/scripts/hls_cosim.tcl
