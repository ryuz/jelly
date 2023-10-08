
FS_FILE = impl/pnr/tang_nano_9k_blinking_led.fs
RTL     = ../rtl/tang_nano_9k_blinking_led.sv

all: $(FS_FILE)

$(FS_FILE): $(RTL)
	gw_sh tang_nano_9k_blinking_led.tcl

clean:
	rm -fr impl

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

run2:
	programmer_cli --device GW1NR-9C --run 2 --fsFile $(TARGET).fs --location `programmer_cli --scan-cable | grep -oP 'USB location:\K\d+'`
