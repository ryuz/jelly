

all: teat_app udmabuf.dtbo

clean:
	rm teat_app

teat_app: main.cpp
	g++ -o teat_app -I../../../soft/Utility main.cpp

udmabuf.dtbo: udmabuf.dts
	dtc -I dts -O dtb -o udmabuf.dtbo udmabuf.dts

load: udmabuf.dtbo
	sudo fpgautil -R
	sudo fpgautil -b ultra96v2_udmabuf_top.bit -o udmabuf.dtbo
	sudo fpgautil -b ultra96v2_udmabuf_top.bit

unload:
	sudo fpgautil -R
#	sudo fpgautil -b ultra96v2_base_top.bit
#	sudo fpgautil -b ultra96v2_base_top.bit -o udmabuf.dtbo


