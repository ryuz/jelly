BASE_NAME  = kv260_blinking_led

DT_NAME    = $(BASE_NAME)
BIT_NAME   = $(BASE_NAME)
ACCEL_NAME = $(BASE_NAME)

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

DEVTREE_PATH  = /configfs/device-tree
FIRMWARE_PATH = /lib/firmware
ACCEL_PATH   = $(FIRMWARE_PATH)/xilinx/$(ACCEL_NAME)

.PHONY: all
all: $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean:
	rm -rf $(DTBO_FILE) $(BIN_FILE)

.PHONY: run
run: load


$(DTBO_FILE): $(DTS_FILE)
	dtc -I dts -O dtb -o $(DTBO_FILE) $(DTS_FILE)

$(BIN_FILE): $(BIF_FILE) $(BIT_FILE)
	bootgen -w -image $(BIF_FILE) -arch zynqmp -process_bitstream bin

$(DEVTREE_PATH):
	sudo mkdir -p /configfs
	sudo mount -t configfs configfs /configfs

.PHONY: load
load: load_dfx

.PHONY: unload
unload: unload_dfx



############################################
# FPGA Load/Unload via Device Tree Overlay
############################################

.PHONY: mount
mount: $(DEVTREE_PATH)

.PHONY: umount
umount: unload_native
	@if [ -d $(DEVTREE_PATH) ] ; then \
		echo umount configfs ; \
		sudo umount /configfs ; \
	fi

.PHONY: load_native
load_native: $(DEVTREE_PATH) $(DTBO_FILE) $(BIN_FILE) unload
	-sudo xmutil unloadapp
	@if [ -e /configfs/device-tree/overlays/k26-starter-kits_image_1 ] ; then \
		sudo rmdir /configfs/device-tree/overlays/k26-starter-kits_image_1 ; \
	fi
	sudo mkdir -p $(FIRMWARE_PATH)
	sudo cp $(BIN_FILE) $(FIRMWARE_PATH)
	sudo cp $(DTBO_FILE) $(FIRMWARE_PATH)
	sudo sh -c "echo 0 > /sys/class/fpga_manager/fpga0/flags"
	sudo mkdir $(DEVTREE_PATH)/overlays/full
	sudo sh -c "echo -n $(DTBO_FILE) > /configfs/device-tree/overlays/full/path"
	sleep 1
	cat $(DEVTREE_PATH)/overlays/full/status
	sudo rm /lib/firmware/$(DTBO_FILE)
	sudo rm /lib/firmware/$(BIN_FILE)

.PHONY: unload_native
unload_native:
	@if [ -e $(DEVTREE_PATH)/overlays/full ] ; then \
		echo unload ; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi


############################################
# FPGA Load/Unload via Accel Manager
############################################

.PHONY: register_dfx
register_accel: $(DEVTREE_PATH) $(DTBO_FILE) $(BIN_FILE) unload_dfx
	sudo mkdir -p $(ACCEL_PATH)
	sudo cp $(BIN_FILE) $(ACCEL_PATH)
	sudo cp $(DTBO_FILE) $(ACCEL_PATH)
	sudo cp shell.json $(ACCEL_PATH)

.PHONY: unregister_dfx
unregister_accel:
	sudo rm -f $(ACCEL_PATH)/$(BIT_FILE)
	sudo rm -f $(ACCEL_PATH)/$(BIN_FILE)
	sudo rm -f $(ACCEL_PATH)/$(DTBO_FILE)
	sudo rm -f $(ACCEL_PATH)/shell.json
	sudo rm -fd $(ACCEL_PATH)

.PHONY: load_dfx
load_dfx: register_accel
	sudo xmutil loadapp $(ACCEL_NAME)

.PHONY: unload_dfx
unload_dfx:
	-sudo xmutil unloadapp

