TARGET = test_app

CFLAGS  += -I../../../soft/Utility
LDFLAGS += 

OBJS   = main.o


.PHONY: all
all: $(TARGET) udmabuf.dtbo

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS) udmabuf.dtbo

.PHONY: run
run:
	sudo ./$(TARGET)

$(TARGET): $(OBJS)
	g++ $(LDFLAGS) -o $(TARGET) $(OBJS)

main.o: main.cpp
	g++ $(CFLAGS) -c main.cpp

udmabuf.dtbo: udmabuf.dts
	dtc -I dts -O dtb -o udmabuf.dtbo udmabuf.dts

.PHONY: load
load: udmabuf.dtbo
	sudo fpgautil -R
	sudo fpgautil -b ultra96v2_udmabuf_top.bit -o udmabuf.dtbo
	sudo fpgautil -b ultra96v2_udmabuf_top.bit

.PHONY: unload
unload:
	sudo fpgautil -R
#	sudo fpgautil -b ultra96v2_base_top.bit
#	sudo fpgautil -b ultra96v2_base_top.bit -o udmabuf.dtbo
