BASE_NAME = zybo_z7_mnist_seg_imx219_oled

TARGET     = $(BASE_NAME).out
ACCEL_NAME = $(BASE_NAME)
BIT_FILE   = ../$(BASE_NAME).bit
BIN_FILE   = $(BIT_FILE).bin
DTBO_FILE  = ../$(BASE_NAME).dtbo

ZYBO_Z7_SERVER_ADDRESS ?= 127.0.0.1:8051
ZYBO_Z7_SSH_ADDRESS    ?= zybo-z7

# 実行環境のネイティブアーキテクチャを取得
HOST_ARCH := $(shell uname -m)

TARGET_ARCH := armv7l
TARGET_TRIPLET := arm-linux-gnueabihf-

CFLAGS  += -Wall -g -O2 -I../../../../../include
LDFLAGS += -g

ifeq ($(HOST_ARCH),$(TARGET_ARCH))
    CC  := gcc
    CXX := g++
    CFLAGS  += `pkg-config --cflags opencv4`
    LDFLAGS += `pkg-config --libs opencv4`
else
    CC  = $(TARGET_TRIPLET)gcc
    CXX = $(TARGET_TRIPLET)g++
    CFLAGS  += -I/usr/include/opencv4
	LDFLAGS += -L/usr/lib/$(TARGET_TRIPLET)
    LDFLAGS += -lopencv_stitching -lopencv_alphamat -lopencv_aruco -lopencv_bgsegm -lopencv_bioinspired -lopencv_ccalib -lopencv_dnn_objdetect -lopencv_dnn_superres -lopencv_dpm -lopencv_face -lopencv_freetype -lopencv_fuzzy -lopencv_hdf -lopencv_hfs -lopencv_img_hash -lopencv_intensity_transform -lopencv_line_descriptor -lopencv_mcc -lopencv_quality -lopencv_rapid -lopencv_reg -lopencv_rgbd -lopencv_saliency -lopencv_stereo -lopencv_structured_light -lopencv_phase_unwrapping -lopencv_superres -lopencv_optflow -lopencv_surface_matching -lopencv_tracking -lopencv_highgui -lopencv_datasets -lopencv_text -lopencv_plot -lopencv_videostab -lopencv_videoio -lopencv_viz -lopencv_wechat_qrcode -lopencv_shape -lopencv_ml -lopencv_ximgproc -lopencv_video -lopencv_xobjdetect -lopencv_objdetect -lopencv_calib3d -lopencv_imgcodecs -lopencv_features2d -lopencv_dnn -lopencv_flann -lopencv_xphoto -lopencv_photo -lopencv_imgproc -lopencv_core
endif


RUN_OPT ?=

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
	jelly-fpga-loader overlay $(DTBO_FILE) --bin $(BIN_FILE) --ip $(ZYBO_Z7_SERVER_ADDRESS)

.PHONY: remote_run
remote_run: $(TARGET) load
	scp $(TARGET) $(ZYBO_Z7_SSH_ADDRESS):/tmp/
	ssh -Y -t $(ZYBO_Z7_SSH_ADDRESS) /tmp/$(TARGET) $(RUN_OPT)

.PHONY: remote_rerun
remote_rerun: $(TARGET)
	ssh -Y -t $(ZYBO_Z7_SSH_ADDRESS) /tmp/$(TARGET) $(RUN_OPT)
