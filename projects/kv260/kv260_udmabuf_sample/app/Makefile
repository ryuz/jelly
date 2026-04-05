
BASE_NAME  = kv260_udmabuf_sample
DT_NAME    = $(BASE_NAME)
BIT_NAME   = $(BASE_NAME)
ACCEL_NAME = $(BASE_NAME)

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree
ACCEL_PATH    = $(FIRMWARE_PATH)/xilinx/$(ACCEL_NAME)


.PHONY: all
all: $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean:
	rm -rf $(DTBO_FILE) $(BIN_FILE)

.PHONY: run
run: run_cpp

.PHONY: run_cpp
run_cpp: load
	make run RUN_OPT="$(RUN_OPT)" -C cpp

.PHONY: run_rust
run_rust: load
	make run RUN_OPT="$(RUN_OPT)" -C rust

.PHONY: run_python
run_python: load
	python3 python/led_sample.py

.PHONY: run_python_server
run_python_server: load
	python3 python/flask_sample.py



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
#	sudo chmod 666 /dev/uio*
#	sudo chmod 666 /dev/udmabuf*

.PHONY: unload_dt
unload_dt:
	@if [ -e $(DEVTREE_PATH)/overlays/full ] ; then \
		echo unload device tree overlay; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi
