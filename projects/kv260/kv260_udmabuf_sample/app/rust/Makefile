
BASE_NAME = kv260_udmabuf_sample

ELF_NAME   = $(BASE_NAME)
ACCEL_NAME = $(BASE_NAME)
BIT_FILE   = ../$(BASE_NAME).bit
BIN_FILE   = $(BIT_FILE).bin
DTBO_FILE  = ../$(BASE_NAME).dtbo

HOST_ARCH      := $(shell uname -m)
TARGET_ARCH    := aarch64
TARGET_TRIPLET := aarch64-unknown-linux-gnu

KV260_SERVER_ADDRESS ?= 127.0.0.1:8051
KV260_SSH_ADDRESS    ?= kria


.PHONY: all
all: build

.PHONY: build
	cargo build --release --target=$(TARGET_TRIPLET)

.PHONY: cross_build
cross_build:
	cross build --target=$(TARGET_TRIPLET) --release

.PHONY: clean
clean:
	cargo clean

.PHONY: load
load:
	make -C ..
	jelly-fpga-loader unload --ip $(KV260_SERVER_ADDRESS)
	jelly-fpga-loader register-accel $(ACCEL_NAME) $(DTBO_FILE) $(BIN_FILE) --ip $(KV260_SERVER_ADDRESS)
	jelly-fpga-loader load $(ACCEL_NAME) --ip $(KV260_SERVER_ADDRESS)

.PHONY: remote_run
remote_run: cross_build load
	scp target/$(TARGET_ARCH)/release/$(ELF_NAME) $(KV260_SSH_ADDRESS):/tmp/
	ssh -Y -t $(KV260_SSH_ADDRESS) /tmp/$(ELF_NAME) $(RUN_OPT)
