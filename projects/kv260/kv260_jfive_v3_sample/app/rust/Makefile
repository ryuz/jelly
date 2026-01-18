
BASE_NAME = kv260_jfive_v3_sample

ELF_NAME   = $(BASE_NAME)
ACCEL_NAME = $(BASE_NAME)
BIT_FILE   = ../$(BASE_NAME).bit
BIN_FILE   = $(BIT_FILE).bin
DTBO_FILE  = ../$(BASE_NAME).dtbo

TARGET_ARCH = aarch64-unknown-linux-gnu

KV260_SERVER_ADDRESS ?= 127.0.0.1:8051
KV260_SSH_ADDRESS    ?= kria


.PHONY: all
all: build

.PHONY: build
build: jfive
	cargo build --release

.PHONY: clean
clean:
	cargo clean

.PHONY: run
run: load
	cargo run --release -- $(RUN_OPT)

.PHONY: jfive
jfive:
	make -C ../../jfive
	cp ../../jfive/jfive_sample.bin .

.PHONY: load
load:
	make -C ..
	jelly-fpga-loader unload --ip $(KV260_SERVER_ADDRESS)
	jelly-fpga-loader register-accel $(ACCEL_NAME) $(DTBO_FILE) $(BIN_FILE) --ip $(KV260_SERVER_ADDRESS)
	jelly-fpga-loader load $(ACCEL_NAME) --ip $(KV260_SERVER_ADDRESS)

.PHONY: cross_build
cross_build: jfive
	cross build --target=$(TARGET_ARCH) --release

.PHONY: remote_run
remote_run: cross_build load
	scp target/$(TARGET_ARCH)/release/$(ELF_NAME) $(KV260_SSH_ADDRESS):/tmp/
	ssh -Y -t $(KV260_SSH_ADDRESS) /tmp/$(ELF_NAME) $(RUN_OPT)

.PHONY: remote_rerun
remote_rerun:
	ssh -Y -t $(KV260_SSH_ADDRESS) /tmp/$(ELF_NAME) $(RUN_OPT)
