# $Id: Makefile,v 1.1 2008/10/05 00:48:48 ryuji Exp $

CROSS_COMPILE	= mipsel-elf-
CC		= $(CROSS_COMPILE)gcc
OBJCOPY		= $(CROSS_COMPILE)objcopy

CPPFLAGS	= -D_ABIN32=2 -D_MIPS_SIM=_ABIN32 -D_MIPS_SZLONG=32 -D_MIPS_SZPTR=32
CFLAGS		= -O2 -Wall
ASFLAGS		= -O3 -Wall -D__ASSEMBLY__
LDFLAGS		= -T gdb-stub.lds -nostdlib -nostartfiles


TARGETS = gdb-stub.dat

all: $(TARGETS)

clean:
	rm -f *.o *.elf
	rm -f $(TARGETS)

gdb-stub.elf: entry.o main.o gdb-stub.o gdb-low.o string.o serio.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.dat: %.elf
	$(OBJCOPY) -O binary $< $@

main.o: main.c gdb-stub.h string.h
gdb-stub.o: gdb-stub.c gdb-stub.h
serio.o: serio.c gdb-stub.h
string.o: string.c string.h
