

TARGET = tang_nano_9k_blinking_led

FS_FILE = impl/pnr/$(TARGET).fs

all: $(FS_FILE)

$(FS_FILE): tang_nano_9k_blinking_led.v tang_nano_9k_blinking_led.cst
	gw_sh tang_nano_9k_blinking_led.tcl

clean:
	rm -fr impl

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

run2: $(FS_FILE)
	cp $(FS_FILE) . 
	programmer_cli --device GW1NR-9C --run 2 --fsFile $(TARGET).fs --location 641


