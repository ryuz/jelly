
TARGET    = ultra96v2_imx219_stepper_motor.out
DT_NAME   = ultra96v2_imx219_stepper_motor
BIT_NAME  = ultra96v2_imx219_stepper_motor

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree

CFLAGS  += -Wall -g -O0 `pkg-config --cflags opencv` -I../../../include
LDFLAGS += -g  `pkg-config --libs opencv`

OBJS = main.o


.PHONY: all
all: $(TARGET) $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS) $(DTBO_FILE) $(BIN_FILE)

.PHONY: run
run: $(TARGET) load
	./$(TARGET)

$(TARGET): $(OBJS)
	g++ $(LDFLAGS) -o $(TARGET) $(OBJS)

%.o : %.cpp
	g++ $(CFLAGS) -c $< -o $@

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
	sudo chmod 666 /dev/i2c-4

.PHONY: unload
unload:
	@if [ -e $(DEVTREE_PATH)/overlays/full ] ; then \
		echo unload ; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi

.PHONY: load2
load2: $(DTBO_FILE) $(BIN_FILE)
	sudo fpgautil -R
	sudo fpgautil -b $(BIT_FILE) -o udmabuf.dtbo
#	sudo fpgautil -b $(BIT_FILE)

.PHONY: unload2
unload2:
	sudo fpgautil -R

