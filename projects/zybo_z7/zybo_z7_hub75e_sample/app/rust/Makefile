
BASE_NAME = zybo_z7_hub75e_sample

BIT_FILE   = ../$(BASE_NAME).bit
BIN_FILE   = $(BIT_FILE).bin
DTBO_FILE  = ../$(BASE_NAME).dtbo

TARGET_ARCH = arm-unknown-linux-gnueabihf

ZYBO_Z7_SERVER_ADDRESS ?= 127.0.0.1:8051
ZYBO_Z7_SSH_ADDRESS    ?= zybo-z7

.PHONY: all
all: build

.PHONY: build
build:
	cargo build --release

.PHONY: load
load: unload
	make -C ..
	jelly-fpga-loader overlay $(DTBO_FILE) --bin $(BIN_FILE) --ip $(ZYBO_Z7_SERVER_ADDRESS)

.PHONY: unload
unload:
	-jelly-fpga-loader unload --ip $(ZYBO_Z7_SERVER_ADDRESS)

.PHONY: cross_build
cross_build:
	cross build --target=$(TARGET_ARCH) --release

.PHONY: remote_run
remote_run: cross_build load
	scp target/$(TARGET_ARCH)/release/$(BASE_NAME) $(ZYBO_Z7_SSH_ADDRESS):/tmp/
	ssh -Y -t $(ZYBO_Z7_SSH_ADDRESS) /tmp/$(BASE_NAME) $(RUN_OPT)

