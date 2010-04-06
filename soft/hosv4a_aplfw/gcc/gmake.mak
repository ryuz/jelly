# ----------------------------------------------------------------------------
# Hyper Operating System V4 Advance
#
# Copyright (C) 1998-2008 by Project HOS
# http://sourceforge.jp/projects/hos/
# ----------------------------------------------------------------------------


# %jp{ターゲット名}
TARGET ?= hosv4a_aplfw

# %jp{ツール定義}
GCC_ARCH    ?= mips-elf-
CMD_CC      ?= $(GCC_ARCH)gcc
CMD_ASM     ?= $(GCC_ARCH)gcc
CMD_LINK    ?= $(GCC_ARCH)gcc
CMD_OBJCNV  ?= $(GCC_ARCH)objcopy
CMD_OBJDUMP ?= $(GCC_ARCH)objdump
CMD_GDB     ?= $(GCC_ARCH)gdb


# %jp{ディレクトリ}
HOS_DIR           = $(HOME)/hos-v4a
KERNEL_DIR        = $(HOS_DIR)/kernel
KERNEL_CFGRTR_DIR = $(HOS_DIR)/cfgrtr/build/gcc
KERNEL_MAKINC_DIR = $(KERNEL_DIR)/build/common/gmake
KERNEL_BUILD_DIR  = $(KERNEL_DIR)/build/mips/jelly/gcc
APLFW_DIR         = $(HOS_DIR)/aplfw
APLFW_INC_DIR     = $(APLFW_DIR)
APLFW_BUILD_DIR   = $(APLFW_DIR)/build/mips/jelly/gcc
TOOLS_DIR         = ../../../tools
OBJS_DIR          = objs_$(TARGET)

# %jp{カーネル設定}
KERNEL_HOK_TSK = Yes
KERNEL_HOK_ISR = Yes


# %jp{共通定義読込み}
include $(KERNEL_MAKINC_DIR)/common.inc


# %jp{コンフィギュレータ定義}
KERNEL_CFGRTR = $(KERNEL_CFGRTR_DIR)/h4acfg-jelly


# %jp{ライブラリ定義}
APLFW_LIB = $(APLFW_BUILD_DIR)/hosaplfw.a


# %jp{デバッグ版の定義変更}
ifeq ($(DEBUG),Yes)
TARGET := $(TARGET)dbg
APLFW_LIB = $(APLFW_BUILD_DIR)/hosaplfwdbg.a
endif


# %jp{メモリマップ}
ifeq ($(MEMMAP),ram)
# %jp{内蔵RAM}
TARGET       := $(TARGET)_ram
LINK_SCRIPT = ram.lds
else
# %jp{内蔵ROM}
LINK_SCRIPT = rom.lds
endif


# %jp{フラグ設定}
CFLAGS  = -march=mips1 -msoft-float -G 0
AFLAGS  = -march=mips1 -msoft-float -G 0
LNFLAGS = -march=mips1 -msoft-float -G 0 -nostartfiles -Wl,-Map,$(TARGET).map,-T$(LINK_SCRIPT)


# %jp{出力ファイル名}
TARGET_EXE = $(TARGET).$(EXT_EXE)
TARGET_BIN = $(TARGET).$(EXT_BIN)

TARGETS = $(TARGET_EXE) $(TARGET_BIN)


# %jp{gcc用の設定読込み}
include $(KERNEL_MAKINC_DIR)/gcc_d.inc


# %jp{インクルードディレクトリ}
INC_DIRS += $(APLFW_INC_DIR)

# %jp{ソースディレクトリ}
SRC_DIRS += . ..


# %jp{アセンブラファイルの追加}
ASRCS += ./crt0.S


# %jp{C言語ファイルの追加}
CSRCS += ../kernel_cfg.c
CSRCS += ../main.c
CSRCS += ../boot.c
CSRCS += ../ostimer.c
#CSRCS += memcpy.c
#CSRCS += strlen.c

SRC_DIRS +=  ../mmcdrv
CSRCS += ../mmcdrv/mmcdrv_create.c
CSRCS += ../mmcdrv/mmcdrv_delete.c
CSRCS += ../mmcdrv/mmcdrv_constructor.c
CSRCS += ../mmcdrv/mmcdrv_destructor.c
CSRCS += ../mmcdrv/mmcdrv_close.c
CSRCS += ../mmcdrv/mmcdrv_flush.c
CSRCS += ../mmcdrv/mmcdrv_getinformation.c
CSRCS += ../mmcdrv/mmcdrv_iocontrol.c
CSRCS += ../mmcdrv/mmcdrv_open.c
CSRCS += ../mmcdrv/mmcdrv_read.c
CSRCS += ../mmcdrv/mmcdrv_spictl.c
CSRCS += ../mmcdrv/mmcdrv_seek.c
CSRCS += ../mmcdrv/mmcdrv_write.c
CSRCS += ../mmcdrv/mmcfile_create.c
CSRCS += ../mmcdrv/mmcfile_delete.c
CSRCS += ../mmcdrv/mmcfile_constructor.c
CSRCS += ../mmcdrv/mmcfile_destructor.c

SRC_DIRS +=  ../dhrystone
CSRCS += ../dhrystone/dhry21a.c
CSRCS += ../dhrystone/dhry21b.c
# CSRCS += ../dhrystone/timers.c

# %jp{ライブラリファイルの追加}
LIBS += $(APLFW_LIB) -lc



# --------------------------------------
#  %jp{ルール}
# --------------------------------------

.PHONY : all
all: kernel_make make_subprj makeexe_all $(TARGETS)
	$(CMD_OBJDUMP) -D $(TARGET_EXE)             > $(TARGET).das
	$(TOOLS_DIR)/bin2hex.pl $(TARGET_BIN) 32768 > $(TARGET).hex

.PHONY : run
run: all
	jelly_loader -r $(TARGET_BIN)

.PHONY : gdb
gdb: all
	$(CMD_GDB) $(TARGET_EXE) -x gdb.txt


.PHONY : make_subprj
make_subprj:
	$(MAKE) -C $(APLFW_BUILD_DIR) -f gmake.mak

.PHONY : clean
clean: makeexe_clean
	rm -f  $(TARGETS) $(OBJS) ../kernel_cfg.c ../kernel_id.h

.PHONY : depend
depend: makeexe_depend

.PHONY : mostlyclean
mostlyclean: clean kernel_clean
	$(MAKE) -C $(APLFW_BUILD_DIR) -f gmake.mak clean

.PHONY : mostlydepend
mostlydepend: depend
	$(MAKE) -C $(APLFW_BUILD_DIR) -f gmake.mak depend


../kernel_cfg.c ../kernel_id.h: ../system.cfg
	cpp -E ../system.cfg ../system.i
	$(KERNEL_CFGRTR) ../system.i -c ../kernel_cfg.c -i ../kernel_id.h


$(TARGET_EXE): $(LINK_SCRIPT)


# %jp{ライブラリ生成用設定読込み}
include $(KERNEL_MAKINC_DIR)/makeexe.inc

# %jp{gcc用のルール定義読込み}
include $(KERNEL_MAKINC_DIR)/gcc_r.inc



# --------------------------------------
#  %jp{依存関係}
# --------------------------------------

$(OBJS_DIR)/sample.obj: ../sample.c ../kernel_id.h


# end of file
