
TARGET    = test_udmabuf
DT_NAME   = udmabuf
BIT_NAME  = zybo_z7_udmabuf_top

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin


CFLAGS  += -I../../../soft/Utility
LDFLAGS += 

OBJS   = main.o


.PHONY: all
all: $(TARGET) $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS) $(DTBO_FILE) $(BIN_FILE)

.PHONY: run
run:
	sudo ./$(TARGET)

$(TARGET): $(OBJS)
	g++ $(LDFLAGS) -o $(TARGET) $(OBJS)

main.o: main.cpp
	g++ $(CFLAGS) -c main.cpp

$(DTBO_FILE): $(DTS_FILE)
	dtc -I dts -O dtb -o $(DTBO_FILE) $(DTS_FILE)

$(BIN_FILE): $(BIF_FILE) $(BIT_FILE)
	bootgen -image $(BIF_FILE) -arch zynq -process_bitstream bin

.PHONY: load
load: $(DTBO_FILE) $(BIN_FILE)
	sudo mkdir -p /lib/firmware
	sudo cp $(BIN_FILE) /lib/firmware/
	sudo cp $(DTBO_FILE) /lib/firmware/
	sudo mkdir -p /configfs
	sudo mount -t configfs configfs /configfs
	sudo mkdir -p /configfs/device-tree/overlays/full
	sudo cp $(DTBO_FILE) /configfs/device-tree/overlays/full/dtbo
	sudo sh -c "echo 1 > /config/device-tree/overlays/full/status"

#	sudo fpgautil -R
#	sudo fpgautil -b $(BIT_FILE) -o $(DTBO_FILE)
#	sudo fpgautil -b $(BIT_FILE)

.PHONY: unload
unload:
	sudo sh -c "echo 0 > /config/device-tree/overlays/full/status"
	sudo umount /configfs
#	sudo fpgautil -R

