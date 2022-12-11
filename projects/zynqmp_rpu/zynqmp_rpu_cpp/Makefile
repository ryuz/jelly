
# ターゲット名
PRJ_NAME = zynqmp_rpu_cpp
TARGET = $(PRJ_NAME).elf

RUN_PROC ?= remoteproc0

# ツール定義
ARCH    = arm-none-eabi-
CC      = $(ARCH)gcc
CXX     = $(ARCH)g++
AS      = $(ARCH)gcc
LD      = $(ARCH)gcc
OBJCOPY = $(ARCH)objcopy

# オブジェクトファイル
OBJS = vectors.o crt0.o hw_setup.o armcpu.o main.o uart.o

# リンカスクリプト
LINK_SCRIPT = link.lds

# フラグ設定
CFLAGS    = -mcpu=cortex-r5 -mthumb-interwork
CXXFLAGS  = -mcpu=cortex-r5 -mthumb-interwork -std=c++11 -fno-use-cxa-atexit -fno-exceptions -fno-rtti
AFLAGS    = -mcpu=cortex-r5 -mthumb-interwork
LDFLAGS   = -mcpu=cortex-r5 -mthumb-interwork -nostartfiles -Wl,-Map,$(PRJ_NAME).map,-T$(LINK_SCRIPT)

# VFPフラグ
DEBUG ?= No
ifneq ($(DEBUG),Yes)
CFLAGS   += -O2
CXXFLAGS += -O2
AFLAGS  += -O2
LDFLAGS +=
else
CFLAGS   += -O0 -g -D_DEBUG
CXXFLAGS += -O0 -g -D_DEBUG
AFLAGS  += -O0 -g -D_DEBUG
LDFLAGS += -g
endif

# VFPフラグ
WITH_VFP ?= Yes
ifeq ($(WITH_VFP),Yes)
AFLAGS  += -mfloat-abi=softfp -mfpu=vfpv3-d16 -D_WITH_VFP
CFLAGS  += -mfloat-abi=softfp -mfpu=vfpv3-d16 -D_WITH_VFP
LDFLAGS += -mfloat-abi=softfp -mfpu=vfpv3-d16
endif


# --------------------------------------
#  %jp{ルール}
# --------------------------------------

.PHONY : all
all: $(TARGET)

.PHONY : clean
clean:
	rm -f $(TARGET) $(OBJS) $(TARGET).map

.PHONY: run
run: $(TARGET) stop
	@sudo cp $(TARGET) /lib/firmware
	@sudo sh -c "echo $(TARGET) > /sys/class/remoteproc/$(RUN_PROC)/firmware"
	@sudo sh -c "echo start > /sys/class/remoteproc/$(RUN_PROC)/state"
	@echo "[run] $(RUN_PROC)"

.PHONY: stop
stop:
	@if grep -q running /sys/class/remoteproc/$(RUN_PROC)/state; then \
		sudo sh -c "echo stop > /sys/class/remoteproc/$(RUN_PROC)/state" ; \
		echo "[stop] $(RUN_PROC)" ; \
	fi \


# 依存関係
$(TARGET): $(LINK_SCRIPT) $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $(TARGET)


%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

%.o : %.cpp
	$(CXX) -c $(CXXFLAGS) $< -o $@

%.o : %.S
	$(AS) -c $(AFLAGS) $< -o $@


# end of file
