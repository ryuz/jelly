
PRJ_NAME = zynqmp_rpu_rust

RUN_PROC     ?= remoteproc0
BUILD_TARGET ?= release

EXE_FILE = target/armv7r-none-eabi/$(BUILD_TARGET)/$(PRJ_NAME)

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree


.PHONY: all
all: build

.PHONY: build
build:
	cargo build --$(BUILD_TARGET)

.PHONY: clean
clean:
	cargo clean

.PHONY: run
run: build run_rpu

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
