
# setting
export HLS_TARGET   = divider
export HLS_SOLUTION = solution_1
export DEVICE_PART  = xczu3eg-sbva484-1-i
export CLOCK_PERIOD = 4

TARGET_DIR = target
CSIM_DIR   = $(TARGET_DIR)/csim
SYN_DIR    = $(TARGET_DIR)/syn
COSIM_DIR  = $(TARGET_DIR)/sim
IMPL_DIR   = $(TARGET_DIR)/impl


.PHONY: all
all: clean csim csynth

.PHONY: create
create:
	vitis_hls create_project.tcl

.PHONY: clean
clean:
	-rm -rf $(HLS_TARGET)
	-rm *.log

.PHONY: csim
csim:
	vitis_hls csim.tcl

.PHONY: csynth
csynth:
	vitis_hls csynth.tcl

.PHONY: cosim
cosim:
	vitis_hls cosim.tcl




