

DT_NAME   = kv260_imx219_stepper_motor
BIT_NAME  = kv260_imx219_stepper_motor

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree

RUN_OPT ?=

OBJS = main.o

### all ###
.PHONY: all
all: build

.PHONY: build
build: $(DTBO_FILE) $(BIN_FILE) apu_build rpu_build

.PHONY: clean
clean: apu_clean rpu_clean
	rm -rf $(DTBO_FILE) $(BIN_FILE)

.PHONY: run
run: build load rpu_run apu_run rpu_stop

.PHONY: stop
stop: rpu_stop


### APU ###
.PHONY: apu_build
apu_build:
	make -C apu

.PHONY: apu_clean
apu_clean:
	make -C apu clean

.PHONY: apu_run
apu_run:
	make -C apu run RUN_OPT=$(RUN_OPT)


### RPU ###
.PHONY: rpu_build
rpu_build:
	make -C rpu

.PHONY: rpu_clean
rpu_clean:
	make -C rpu clean

.PHONY: rpu_run
rpu_run:
	make -C rpu run RUN_OPT=$(RUN_OPT)

.PHONY: rpu_stop
rpu_stop:
	make -C rpu stop


### bit file ###
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
load: $(DEVTREE_PATH) $(DTBO_FILE) $(BIN_FILE) rpu_stop unload
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
	@if [ ! -e /sys/class/gpio/gpio36 ] ; then \
		sudo sh -c "echo 36  > /sys/class/gpio/export" ; \
		sudo sh -c "echo out > /sys/class/gpio/gpio36/direction" ; \
		sudo sh -c "echo 1   > /sys/class/gpio/gpio36/value" ; \
	fi
	sudo chmod -R 777 /sys/class/gpio/gpio36
	sudo chmod 666 /dev/uio*
	sudo chmod 666 /dev/udmabuf*
	sudo chmod 666 /dev/i2c-6

.PHONY: unload
unload: rpu_stop
	@if [ -e $(DEVTREE_PATH)/overlays/full ] ; then \
		echo unload ; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi
	@if [ -e /sys/class/gpio/gpio36 ] ; then \
		sudo sh -c "echo in > /sys/class/gpio/gpio36/direction" ; \
		sudo sh -c "echo 36 > /sys/class/gpio/unexport" ; \
	fi
