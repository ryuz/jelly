# ----------------------------------------------------------------------------
# Hyper Operating System V4 Advance
#
# Copyright (C) 1998-2020 by Project HOS
# http://sourceforge.jp/projects/hos/
# ----------------------------------------------------------------------------

# %jp{ターゲット名}
TARGET ?= sample
EXT_EXE ?= elf

# %jp{ツール定義}
GCC_ARCH   ?= arm-none-eabi-
CMD_CC     ?= $(GCC_ARCH)gcc
CMD_ASM    ?= $(GCC_ARCH)gcc
CMD_LINK   ?= $(GCC_ARCH)gcc
CMD_OBJCNV ?= $(GCC_ARCH)objcopy


# %jp{ディレクトリ定義}
OS_DIR            = ../../../../../../hos-v4a
KERNEL_DIR        = $(OS_DIR)/kernel
KERNEL_CFGRTR_DIR = $(OS_DIR)/cfgrtr/build/gcc
KERNEL_MAKINC_DIR = $(KERNEL_DIR)/build/common/gmake
KERNEL_BUILD_DIR  = $(KERNEL_DIR)/build/arm/cortex_r5/gcc
OBJS_DIR          = objs_$(TARGET)

# %jp{共通定義読込み}
include $(KERNEL_MAKINC_DIR)/common.inc

# デバッグ版のターゲット名変更
ifeq ($(DEBUG),Yes)
TARGET := $(TARGET)dbg
endif

# リンカスクリプト
LINK_SCRIPT = link.lds


# %jp{フラグ設定}
CFLAGS  = -mcpu=cortex-r5 -mthumb-interwork
AFLAGS  = -mcpu=cortex-r5 -mthumb-interwork
LNFLAGS = -mcpu=cortex-r5 -mthumb-interwork -nostartfiles -Wl,-Map,$(TARGET).map,-T$(LINK_SCRIPT)

# %jp{VFPフラグ}%en{VFP flags}
WITH_VFP ?= Yes
ifneq ($(WITH_VFP),No)
AFLAGS  += -mfloat-abi=softfp -mfpu=vfpv3-d16 
CFLAGS  += -mfloat-abi=softfp -mfpu=vfpv3-d16 
LNFLAGS += -mfloat-abi=softfp -mfpu=vfpv3-d16 
A_DEFS += _KERNEL_ARM_WITH_VFP
C_DEFS += _KERNEL_ARM_WITH_VFP
endif


# %jp{コンフィギュレータ定義}
KERNEL_CFGRTR = $(KERNEL_CFGRTR_DIR)/h4acfg-cortex_r5

# 出力ファイル名
TARGET_EXE = $(TARGET).$(EXT_EXE)
TARGET_MOT = $(TARGET).$(EXT_MOT)
TARGET_HEX = $(TARGET).$(EXT_HEX)


# %jp{gcc用の設定読込み}
include $(KERNEL_MAKINC_DIR)/gcc_d.inc

# %jp{実行ファイル生成用設定読込み}%en{definitions for exection file}
include $(KERNEL_MAKINC_DIR)/makexe_d.inc

# ソースディレクトリ
SRC_DIRS += . ..

# アセンブラファイルの追加
ASRCS += ./vectors.S		\
         ./crt0.S

# %jp{C言語ファイルの追加}
CSRCS += ../kernel_cfg.c	\
         ../main.c			\
         ../sample.c		\
         ../ostimer.c		\
         ../uart.c



# --------------------------------------
#  %jp{ルール}
# --------------------------------------

.PHONY : all
all: makeexe_all $(TARGET_EXE) $(TARGET_MOT) $(TARGET_HEX)

.PHONY : clean
clean: makeexe_clean
	-$(CMD_RM) $(TARGET_EXE) $(TARGET_EXE) $(TARGET_MOT) $(TARGET_HEX) $(OBJS) ../system.i ../kernel_cfg.c ../kernel_id.h
	-$(CMD_RM) $(TARGET).map

.PHONY : distclean
distclean: clean makeexe_distclean

../kernel_cfg.c ../kernel_id.h: ../system.cfg
	$(CMD_CPP) -E ../system.cfg ../system.i
	$(KERNEL_CFGRTR) ../system.i -c ../kernel_cfg.c -i ../kernel_id.h
	-$(CMD_RM) ../system.i


# %jp{実行ファイル生成用設定読込み}%en{rules for exection file}
include $(KERNEL_MAKINC_DIR)/makexe_r.inc

# %jp{gcc用のルール定義読込み}
include $(KERNEL_MAKINC_DIR)/gcc_r.inc


start: $(TARGET_EXE)
	sudo cp $(TARGET_EXE) /lib/firmware
	sudo sh -c "echo $(TARGET_EXE) > /sys/class/remoteproc/remoteproc0/firmware"
	sudo sh -c "echo start > /sys/class/remoteproc/remoteproc0/state"

stop:
	sudo sh -c "echo stop > /sys/class/remoteproc/remoteproc0/state"


# --------------------------------------
#  %jp{依存関係}
# --------------------------------------

$(TARGET_EXE): $(LINK_SCRIPT)

$(OBJS_DIR)/sample.$(EXT_OBJ): ../sample.c ../kernel_id.h


# end of file

