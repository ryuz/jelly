

PRJ_NAME  = kv260_rtos
DT_NAME   = $(PRJ_NAME)
BIT_NAME  = $(PRJ_NAME)

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

RUN_PROC     ?= remoteproc0
BUILD_TARGET ?= release

EXE_FILE = target/armv7r-none-eabi/$(BUILD_TARGET)/$(PRJ_NAME)

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree


.PHONY: all
all: build $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean:
	cargo clean
	rm -rf $(DTBO_FILE) $(BIN_FILE)

.PHONY: fmt
fmt:
	cargo fmt

.PHONY: run
run: build load run_rpu

.PHONY: run_rpu
run_rpu: stop
	@sudo cp $(EXE_FILE) /lib/firmware
	@sudo sh -c "echo $(PRJ_NAME) > /sys/class/remoteproc/$(RUN_PROC)/firmware"
	@sudo sh -c "echo start > /sys/class/remoteproc/$(RUN_PROC)/state"
	echo "[run] $(RUN_PROC)" ; \

.PHONY: stop
stop:
	@if grep -q running /sys/class/remoteproc/$(RUN_PROC)/state; then \
		sudo sh -c "echo stop > /sys/class/remoteproc/$(RUN_PROC)/state" ; \
		echo "[stop] $(RUN_PROC)" ; \
	fi \


.PHONY: build
build:
	cargo build --$(BUILD_TARGET)

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
	sudo chmod 666 /dev/udmabuf*

.PHONY: unload
unload:
	@if [ -e $(DEVTREE_PATH)/overlays/full ] ; then \
		echo unload ; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi
