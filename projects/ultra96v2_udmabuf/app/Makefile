
TARGET   = test_udmabuf
BIT_FILE = ultra96v2_udmabuf_top.bit

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
	sudo fpgautil -b $(BIT_FILE) -o udmabuf.dtbo
	sudo fpgautil -b $(BIT_FILE)

.PHONY: unload
unload:
	sudo fpgautil -R

