

PRJ_NAME  = ultra96v2_mpu9250
DT_NAME   = $(PRJ_NAME)
BIT_NAME  = $(PRJ_NAME)

RUN_PROC     ?= remoteproc0
BUILD_TARGET ?= release

EXE_FILE = target/armv7r-none-eabi/$(BUILD_TARGET)/$(PRJ_NAME)

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree

APU_TARGET   = com_rpu.out
APU_OBJS     = com_rpu.o
APU_CFLAGS  += -g -O3 -I../../../../include
APU_LDFLAGS += 

.PHONY: all
all: build

.PHONY: build
build: build_rpu build_apu

.PHONY: run
run: run_rpu run_apu stop_rpu

.PHONY: stop
stop: stop_rpu stop_apu

.PHONY: clean
clean:
	cargo clean
	rm -f $(APU_TARGET) $(APU_OBJS)


.PHONY: run_rpu
run_rpu: build_rpu
	@if grep -q running /sys/class/remoteproc/$(RUN_PROC)/state; then \
		sudo sh -c "echo stop > /sys/class/remoteproc/$(RUN_PROC)/state" ; \
		echo "[stop] $(RUN_PROC)" ; \
	fi \

	@sudo cp $(EXE_FILE) /lib/firmware
	@sudo sh -c "echo $(PRJ_NAME) > /sys/class/remoteproc/$(RUN_PROC)/firmware"
	@sudo sh -c "echo start > /sys/class/remoteproc/$(RUN_PROC)/state"
	echo "[run] $(RUN_PROC)" ; \

.PHONY: stop_rpu
stop_rpu:
	@if grep -q running /sys/class/remoteproc/$(RUN_PROC)/state; then \
		sudo sh -c "echo stop > /sys/class/remoteproc/$(RUN_PROC)/state" ; \
		echo "[stop] $(RUN_PROC)" ; \
	fi \


.PHONY: run_apu
run_apu: $(APU_TARGET)
	xterm -e ./$(APU_TARGET)

.PHONY: stop_apu
stop_apu:
#	-pkill $(APU_TARGET)

.PHONY: build_rpu
build_rpu:
	cargo build --$(BUILD_TARGET)

.PHONY: build_apu
build_apu: $(APU_TARGET)

$(APU_TARGET): $(APU_OBJS)
	g++ $(OAPU_LDFLAGS) -o $(APU_TARGET) $(APU_OBJS)

%.o : %.cpp
	g++ $(APU_CFLAGS) -c $< -o $@
