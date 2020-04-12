

all: udmabuf.dtbo

udmabuf.dtbo: udmabuf.dts
	dtc -I dts -O dtb -o udmabuf.dtbo udmabuf.dts

load: udmabuf.dtbo
	sudo fpgautil -R
	sudo fpgautil -b ultra96v2_udmabuf_top.bit -o udmabuf.dtbo
	sudo fpgautil -b ultra96v2_udmabuf_top.bit

unload: udmabuf.dtbo
	sudo fpgautil -R
#	sudo fpgautil -b ultra96v2_base_top.bit
#	sudo fpgautil -b ultra96v2_base_top.bit -o udmabuf.dtbo
