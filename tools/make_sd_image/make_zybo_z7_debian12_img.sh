#!/bin/bash

# https://github.com/ikwzm/FPGA-SoC-Debian12

VERSION="7.0.0"
TGZ_FILE="v$VERSION.tar.gz"

if [ ! -f $TGZ_FILE ]; then
    wget https://github.com/ikwzm/FPGA-SoC-Debian12/archive/refs/tags/$TGZ_FILE
fi
tar zxvf $TGZ_FILE

DEBIAN_PATH=FPGA-SoC-Debian12-$VERSION

echo  $DEBIAN_PATH

DEV_LOOP=`sudo losetup -f`
echo $DEV_LOOP

IMG_FILE="Zybo-Z7-FPGA-SoC-Debian12-7.0.0.img"
rm -f $IMG_FILE
truncate -s 6GiB $IMG_FILE

sudo losetup -P $DEV_LOOP $IMG_FILE

sudo parted $DEV_LOOP -s mklabel msdos -s mkpart primary fat32 1048576B 315621375B -s mkpart primary ext4 315621376B 100% -s set 1 boot
sudo mkfs.vfat ${DEV_LOOP}p1
sudo mkfs.ext4 ${DEV_LOOP}p2

sudo mkdir -p /mnt/img1
sudo mkdir -p /mnt/img2
sudo mount ${DEV_LOOP}p1 /mnt/img1
sudo mount ${DEV_LOOP}p2 /mnt/img2

sudo cp    $DEBIAN_PATH/target/zynq-zybo-z7/boot/*                               /mnt/img1
sudo cp    $DEBIAN_PATH/files/vmlinuz-6.1.108-armv7-fpga-1                       /mnt/img1/vmlinuz-6.1.108-armv7-fpga
sudo cat   $DEBIAN_PATH/debian12-rootfs-vanilla.tgz.files/* | sudo tar xfz - -C  /mnt/img2
sudo mkdir                       /mnt/img2/home/fpga/debian
sudo cp    $DEBIAN_PATH/debian/* /mnt/img2/home/fpga/debian

sudo umount /mnt/img1
sudo umount /mnt/img2
sudo losetup -d $DEV_LOOP

sudo rmdir /mnt/img1
sudo rmdir /mnt/img2
