
TARGET    = zybo_z7_imx219.out
DT_NAME   = zybo_z7_imx219
BIT_NAME  = zybo_z7_imx219

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree

CFLAGS  += -Wall -g -O0 `pkg-config --cflags opencv` -I../../../include
LDFLAGS += `pkg-config --libs opencv`

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
	bootgen -w -image $(BIF_FILE) -arch zynq -process_bitstream bin

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
	sudo mkdir -p $(DEVTREE_PATH)/overlays/full
	sudo cp $(DTBO_FILE) $(DEVTREE_PATH)/overlays/full/dtbo
	sudo sh -c "echo 1 > $(DEVTREE_PATH)/overlays/full/status"
	sleep 1
	sudo rm /lib/firmware/$(BIN_FILE)
	sudo chmod 666 /dev/i2c-0
	sudo chmod 666 /dev/uio0*
	sudo chmod 666 /dev/udmabuf0

.PHONY: unload
unload:
	@if [ -f /config/device-tree/overlays/full/status ] ; then \
		echo unload ; \
		sudo sh -c "echo 0 > $(DEVTREE_PATH)/overlays/full/status" ; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi

