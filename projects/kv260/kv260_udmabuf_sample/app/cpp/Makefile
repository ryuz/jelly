BASE_NAME = kv260_udmabuf_sample

TARGET     = $(BASE_NAME).out
ACCEL_NAME = $(BASE_NAME)
BIT_FILE   = ../$(BASE_NAME).bit
BIN_FILE   = $(BIT_FILE).bin
DTBO_FILE  = ../$(BASE_NAME).dtbo

KV260_SERVER_ADDRESS ?= 127.0.0.1:8051
KV260_SSH_ADDRESS    ?= kria

# 実行環境のネイティブアーキテクチャを取得
HOST_ARCH   := $(shell uname -m)
TARGET_ARCH := aarch64
TARGET_TRIPLET := aarch64-linux-gnu-

CFLAGS  += -Wall -g -O2 -I../../../../../include
LDFLAGS += -g

ifeq ($(HOST_ARCH),$(TARGET_ARCH))
    CC  := gcc
    CXX := g++
    CFLAGS  +=
    LDFLAGS +=
else
    CC  = $(TARGET_TRIPLET)gcc
    CXX = $(TARGET_TRIPLET)g++
    CFLAGS  +=
    LDFLAGS += -L/usr/lib/aarch64-linux-gnu
endif

OBJS = main.o

.PHONY: all
all: $(TARGET)

.PHONY: build
build: $(TARGET)

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS)

.PHONY: run
run: $(TARGET)
	mkdir -p rec
	./$(TARGET) $(RUN_OPT)

$(TARGET): $(OBJS)
	$(CXX) -o $(TARGET) $(OBJS) $(LDFLAGS)

%.o : %.cpp
	$(CXX) $(CFLAGS) -c $< -o $@

main.o: main.cpp


.PHONY: load
load:
	make -C ..
	jelly-fpga-loader unload --ip $(KV260_SERVER_ADDRESS)
	jelly-fpga-loader register-accel $(ACCEL_NAME) $(DTBO_FILE) $(BIN_FILE) --ip $(KV260_SERVER_ADDRESS)
	jelly-fpga-loader load $(ACCEL_NAME) --ip $(KV260_SERVER_ADDRESS)

.PHONY: remote_run
remote_run: $(TARGET) load
	scp $(TARGET) $(KV260_SSH_ADDRESS):/tmp/
	ssh -Y -t $(KV260_SSH_ADDRESS) /tmp/$(TARGET)
