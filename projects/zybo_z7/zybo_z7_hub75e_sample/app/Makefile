
DT_NAME   = zybo_z7_hub75e_sample
BIT_NAME  = zybo_z7_hub75e_sample

DTS_FILE  = $(DT_NAME).dts
DTBO_FILE = $(DT_NAME).dtbo

BIT_FILE  = $(BIT_NAME).bit
BIF_FILE  = $(BIT_NAME).bif
BIN_FILE  = $(BIT_FILE).bin

FIRMWARE_PATH = /lib/firmware
DEVTREE_PATH  = /configfs/device-tree

.PHONY: all
all: $(DTBO_FILE) $(BIN_FILE)

.PHONY: clean
clean:
	rm -rf $(OBJS) $(DTBO_FILE) $(BIN_FILE)


$(DTBO_FILE): $(DTS_FILE)
	dtc -I dts -O dtb -o $(DTBO_FILE) $(DTS_FILE)

$(BIN_FILE): build_bit $(BIF_FILE) $(BIT_FILE)
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
	sudo chmod 777 /dev/udmabuf*
	sudo chmod 777 /dev/uio*

.PHONY: unload
unload:
	@if [ -f /config/device-tree/overlays/full/status ] ; then \
		echo unload ; \
		sudo sh -c "echo 0 > $(DEVTREE_PATH)/overlays/full/status" ; \
		sudo rmdir $(DEVTREE_PATH)/overlays/full ; \
	fi

.PHONY: remote_load
remote_load: $(DTBO_FILE) $(BIN_FILE) remote_unload
	jelly-fpga-loader overlay $(DTBO_FILE) --bin $(BIN_FILE) --ip $(ZYBO_Z7_SERVER_ADDRESS)

.PHONY: remote_unload
remote_unload:
	-jelly-fpga-loader unload --ip $(ZYBO_Z7_SERVER_ADDRESS)

.PHONY: build_bit
build_bit:
	make -C ../syn/tcl bit_cp
