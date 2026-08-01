
DT_NAME   = zybo_z7_imx219_oled
BIT_NAME  = zybo_z7_imx219_oled

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree

ZYBO_Z7_SERVER_ADDRESS ?= 127.0.0.1:8051

RUN_OPT ?=

.PHONY: all
all: $(DTBO_FILE) $(BIN_FILE)

.PHONY: build
build: $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean:
	rm -f $(DTBO_FILE) $(BIN_FILE)

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





$(DTBO_FILE): $(DTS_FILE)
	dtc -I dts -O dtb -o $(DTBO_FILE) $(DTS_FILE)

$(BIN_FILE): $(BIF_FILE) $(BIT_FILE)
	bootgen -w -image $(BIF_FILE) -arch zynq -process_bitstream bin

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
load: load_dt

.PHONY: unload
unload: unload_dt


### Jelly loader

.PHONY: load_jelly
load_jelly: unload_jelly
	jelly-fpga-loader overlay $(DTBO_FILE) --bin $(BIN_FILE) --ip $(ZYBO_Z7_SERVER_ADDRESS)

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
	sudo mkdir -p $(FIRMWARE_PATH)
	sudo cp $(BIN_FILE) $(FIRMWARE_PATH)
	sudo mkdir -p $(DEVTREE_PATH)/overlays/full
	sudo cp $(DTBO_FILE) $(DEVTREE_PATH)/overlays/full/dtbo
	sudo sh -c "echo 1 > $(DEVTREE_PATH)/overlays/full/status"
	sleep 1
	sudo rm /lib/firmware/$(BIN_FILE)
	sudo chmod 666 /dev/i2c-0
	sudo chmod 666 /dev/uio0*
	sudo chmod 666 /dev/udmabuf*

.PHONY: unload_dt
unload_dt:
	@if [ -f /config/device-tree/overlays/full/status ] ; then \
		echo unload ; \
		sudo sh -c "echo 0 > $(DEVTREE_PATH)/overlays/full/status" ; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi

