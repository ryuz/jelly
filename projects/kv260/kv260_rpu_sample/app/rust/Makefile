


PRJ_NAME = kv260_rpu_sample

# build
RELEASE       ?= No
BUILD_OPTIONS ?=

ifeq ($(RELEASE),Yes)
BUILD_TARGET = release
BUILD_OPTIONS += --release
else
BUILD_TARGET = debug
endif

TARGET_FILE = target/armv7r-none-eabi/$(BUILD_TARGET)/$(PRJ_NAME)

.PHONY: all
all: build

.PHONY: build
build:
	cargo build $(BUILD_OPTIONS)

.PHONY: clean
clean:
	cargo clean

.PHONY: fmt
fmt:
	cargo fmt

.PHONY: disas
disas: build
	arm-none-eabi-objdump -S $(TARGET_FILE) > $(BUILD_TARGET).das

# run
RUN_PROC      ?= remoteproc0
FIRMWARE_PATH  = /lib/firmware
DEVTREE_PATH   = /configfs/device-tree

.PHONY: run
run: build stop
	@sudo cp $(TARGET_FILE) /lib/firmware
	@sudo sh -c "echo $(PRJ_NAME) > /sys/class/remoteproc/$(RUN_PROC)/firmware"
	@sudo sh -c "echo start > /sys/class/remoteproc/$(RUN_PROC)/state"
	@echo "[run] $(RUN_PROC)" ; \

.PHONY: stop
stop:
	@if grep -q running /sys/class/remoteproc/$(RUN_PROC)/state; then \
		sudo sh -c "echo stop > /sys/class/remoteproc/$(RUN_PROC)/state" ; \
		echo "[stop] $(RUN_PROC)" ; \
	fi \
