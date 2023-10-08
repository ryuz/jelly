
FS_FILE = impl/pnr/tang_nano_9k_blink_led.fs
RTL     = ../rtl/tang_nano_9k_blink_led.sv

all: $(FS_FILE)

$(FS_FILE): $(RTL)
	gw_sh script_file.tcl

clean:
	rm -fr impl

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)
#	programmer_cli --scan-cables
