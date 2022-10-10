#!/bin/bash
echo run

qemu-system-aarch64 \
    -M arm-generic-fdt \
    -serial null -serial mon:stdio \
    -device loader,file=$1,cpu-num=4 \
    -device loader,addr=0XFF5E023C,data=0x80088fde,data-len=4 \
    -device loader,addr=0xff9a0000,data=0x80000218,data-len=4 \
    -hw-dtb ../zynqmp-qemu-arm.dtb \
    -display none
