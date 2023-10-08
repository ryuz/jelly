


FS_FILE = impl/pnr/top.fs

all: $(FS_FILE)

$(FS_FILE): top.v top.cst
	gw_sh build.tcl

clean:
	rm -fr impl

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

run2: $(FS_FILE)
	programmer_cli --device GW1NR-9C --run 2 --fsFile $(TARGET).fs --location `programmer_cli --scan-cable | grep -oP 'USB location:\K\d+'`


