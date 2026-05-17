
DT_NAME   = kv260_jfive_v3_sample
BIT_NAME  = kv260_jfive_v3_sample

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree


.PHONY: all
all: build

.PHONY: build
build: $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean: clean_rust
	rm -rf $(DTBO_FILE) $(BIN_FILE)

.PHONY: run
run: run_rust

# JFive app
.PHONY: jfive
jfive:
	make -C ../jfive

# rust
.PHONY: build_rust
build_rust:
	make -C ./rust build

.PHONY: clean_rust
clean_rust:
	make -C ./rust clean

.PHONY: run_rust
run_rust: jfive load
	make -C ./rust run


# cpp
.PHONY: build_cpp
build_cpp:
	make -C ./cpp build

.PHONY: clean_cpp
clean_cpp:
	make -C ./cpp clean

.PHONY: run_cpp
run_cpp: jfive load 
	make -C ./cpp run


# DeviceTree
$(DTBO_FILE): $(DTS_FILE)
	dtc -I dts -O dtb -o $(DTBO_FILE) $(DTS_FILE)

$(BIN_FILE): $(BIF_FILE) $(BIT_FILE)
	bootgen -w -image $(BIF_FILE) -arch zynqmp -process_bitstream bin

$(DEVTREE_PATH):
	sudo mkdir -p /configfs
	sudo mount -t configfs configfs /configfs


.PHONY: mount
mount: $(DEVTREE_PATH)

.PHONY: umount
umount: unload
	@if [ -d $(DEVTREE_PATH) ] ; then \
		echo umount configfs ; \
		sudo umount /configfs ; \
	fi

.PHONY: load
load: $(DEVTREE_PATH) $(DTBO_FILE) $(BIN_FILE) unload
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
	sudo chmod 666 /dev/uio*

.PHONY: unload
unload:
	@if [ -e $(DEVTREE_PATH)/overlays/full ] ; then \
		echo unload ; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi

.PHONY: load2
load2: $(DTBO_FILE) $(BIN_FILE)
	sudo fpgautil -R
	sudo fpgautil -b $(BIT_FILE) -o $(DTBO_FILE)

.PHONY: unload2
unload2:
	sudo fpgautil -R

