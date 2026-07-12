TARGET_NAME = kv260_imx219_sample

DT_NAME    = $(TARGET_NAME)
BIT_NAME   = $(TARGET_NAME)
ACCEL_NAME = $(TARGET_NAME)

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

DEVTREE_PATH  = /configfs/device-tree
FIRMWARE_PATH = /lib/firmware
ACCEL_PATH    = $(FIRMWARE_PATH)/xilinx/$(ACCEL_NAME)

KV260_SERVER_ADDRESS ?= 127.0.0.1:8051

RUN_OPT ?=

.PHONY: all
all: $(DTBO_FILE) $(BIN_FILE)

.PHONY: build
build: $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean:
	rm -rf $(DTBO_FILE) $(BIN_FILE)

.PHONY: run
run: run_cpp

.PHONY: run_cpp
run_cpp: load
	make -C cpp run RUN_OPT="$(RUN_OPT)"

.PHONY: build_cpp
build_cpp:
	make -C cpp build

.PHONY: run_rust
run_rust: load
	cd rust; cargo run -- $(RUN_OPT)

.PHONY: build_rust
build_rust:
	cd rust; cargo build

.PHONY: run_server
run_server: load
	cd grpc/server; cargo run RUN_OPT="$(RUN_OPT)"



$(DTBO_FILE): $(DTS_FILE)
	dtc -I dts -O dtb -o $(DTBO_FILE) $(DTS_FILE)

$(BIN_FILE): $(BIF_FILE) $(BIT_FILE)
	bootgen -w -image $(BIF_FILE) -arch zynqmp -process_bitstream bin

$(BIT_FILE):
	@if [ -f $@ ]; then \
	    echo "$@ exists, skipping build"; \
	elif command -v vivado >/dev/null 2>&1; then \
	    echo "vivado found — building $@"; \
	    make bit_cp -C ../syn/tcl; \
	else \
	    echo "vivado not found — cannot build $@"; \
	    exit 1; \
	fi

.PHONY: load
load: load_dfx

.PHONY: unload
unload: unload_dfx


### DFX Management

.PHONY: load_dfx
load_dfx: $(DEVTREE_PATH) $(DTBO_FILE) $(BIN_FILE) unload_dfx
	sudo mkdir -p $(ACCEL_PATH)
	sudo cp $(BIN_FILE) $(ACCEL_PATH)
	sudo cp $(DTBO_FILE) $(ACCEL_PATH)
	sudo cp shell.json $(ACCEL_PATH)
	sudo xmutil loadapp $(ACCEL_NAME)

.PHONY: unload_dfx
unload_dfx:
	-sudo xmutil unloadapp

.PHONY: unregister_accel
unregister_accel:
	sudo rm -f $(ACCEL_PATH)/$(BIT_FILE)
	sudo rm -f $(ACCEL_PATH)/$(BIN_FILE)
	sudo rm -f $(ACCEL_PATH)/$(DTBO_FILE)
	sudo rm -f $(ACCEL_PATH)/shell.json
	sudo rm -fd $(ACCEL_PATH)


### Jelly loader

.PHONY: load_jelly
load_jelly: unload_jelly
	jelly-fpga-loader unload --ip $(KV260_SERVER_ADDRESS)
	jelly-fpga-loader register-accel $(ACCEL_NAME) $(DTBO_FILE) $(BIN_FILE) --ip $(KV260_SERVER_ADDRESS)
	jelly-fpga-loader load $(ACCEL_NAME) --ip $(KV260_SERVER_ADDRESS)

.PHONY: unload_jelly
unload_jelly:
	-jelly-fpga-loader unload --ip $(ZYBO_Z7_SERVER_ADDRESS)


### Device Tree Overlay Management

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

.PHONY: load_dt
load_dt: $(DEVTREE_PATH) $(DTBO_FILE) $(BIN_FILE) unload
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
	sudo chmod 666 /dev/uio*
	sudo chmod 666 /dev/udmabuf*
	sudo chmod 666 /dev/i2c-6

.PHONY: unload_dt
unload_dt:
	@if [ -e $(DEVTREE_PATH)/overlays/full ] ; then \
		echo unload device tree overlay; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi

