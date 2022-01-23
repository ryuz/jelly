
# setting
export HLS_TARGET   = video_filter
export HLS_SOLUTION = solution_1
export DEVICE_PART  = xczu3eg-sbva484-1-i
export CLOCK_PERIOD = 4

# Ubuntu の場合下記が必要？
# export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

TARGET_DIR = $(HLS_TARGET)/$(HLS_SOLUTION)
CSIM_DIR   = $(TARGET_DIR)/csim
SYN_DIR    = $(TARGET_DIR)/syn
COSIM_DIR  = $(TARGET_DIR)/sim
IMPL_DIR   = $(TARGET_DIR)/impl
EXPORT_ZIP = $(IMPL_DIR)/export.zip

.PHONY: all
all: $(EXPORT_ZIP)

.PHONY: create
create:
	vitis_hls create_project.tcl

.PHONY: clean
clean:
	-rm -rf $(HLS_TARGET)
	-rm *.log

.PHONY: csim
csim: $(TARGET_DIR)
	vitis_hls csim.tcl

.PHONY: csynth
csynth: $(TARGET_DIR)
	vitis_hls csynth.tcl

.PHONY: cosim
cosim: $(TARGET_DIR) $(SYN_DIR)
	vitis_hls cosim.tcl

$(TARGET_DIR): create
$(EXPORT_ZIP): csynth

