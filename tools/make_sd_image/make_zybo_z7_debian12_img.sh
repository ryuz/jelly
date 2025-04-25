#!/bin/bash

# ikwzm氏の Debian12 イメージを img化する
# https://github.com/ikwzm/FPGA-SoC-Debian12


VERSION="7.0.0"
TGZ_FILE="v$VERSION.tar.gz"
IMG_SIZE=2GiB

MNT_P1=/mnt/img1
MNT_P2=/mnt/img2

if [ ! -f $TGZ_FILE ]; then
    wget https://github.com/ikwzm/FPGA-SoC-Debian12/archive/refs/tags/$TGZ_FILE
fi
tar zxvf $TGZ_FILE

DEBIAN_PATH=FPGA-SoC-Debian12-$VERSION

DEV_LOOP=`sudo losetup -f`

IMG_FILE="Zybo-Z7-FPGA-SoC-Debian12-7.0.0.img"
rm -f $IMG_FILE
truncate -s $IMG_SIZE $IMG_FILE

sudo losetup -P $DEV_LOOP $IMG_FILE

sudo parted $DEV_LOOP -s mklabel msdos -s mkpart primary fat32 1048576B 315621375B -s mkpart primary ext4 315621376B 100% -s set 1 boot
sudo mkfs.vfat ${DEV_LOOP}p1
sudo mkfs.ext4 ${DEV_LOOP}p2

sudo mkdir -p $MNT_P1
sudo mkdir -p $MNT_P2
sudo mount ${DEV_LOOP}p1 $MNT_P1
sudo mount ${DEV_LOOP}p2 $MNT_P2

sudo cp    $DEBIAN_PATH/target/zynq-zybo-z7/boot/*                               $MNT_P1
sudo cp    $DEBIAN_PATH/files/vmlinuz-6.1.108-armv7-fpga-1                       $MNT_P1/vmlinuz-6.1.108-armv7-fpga
sudo cat   $DEBIAN_PATH/debian12-rootfs-vanilla.tgz.files/* | sudo tar xfz - -C  $MNT_P2
sudo mkdir                       $MNT_P2/home/fpga/debian
sudo cp    $DEBIAN_PATH/debian/* $MNT_P2/home/fpga/debian

# パーティーション自動拡張
# qemu のインストールや binfmt の設定は事前にしておくこと
# HOST で sudo apt-get reinstall binfmt-support
sudo cp resize2fs_once $MNT_P2/etc/init.d/
sudo chmod 755         $MNT_P2/etc/init.d/resize2fs_once

sudo mv $MNT_P2/etc/resolv.conf    $MNT_P2/etc/resolv.conf.org
sudo cp /etc/resolv.conf           $MNT_P2/etc
sudo cp /usr/bin/qemu-arm-static   $MNT_P2/usr/bin

sudo sh -c "cat <<EOT >> $MNT_P2/setup.sh
#!/bin/bash
apt update
apt install -y parted
update-rc.d resize2fs_once defaults
exit
EOT"
sudo chmod 755 $MNT_P2/setup.sh
sudo chroot $MNT_P2/ /setup.sh
sudo rm     $MNT_P2/setup.sh
sudo rm     $MNT_P2/usr/bin/qemu-arm-static
sudo rm     $MNT_P2/etc/resolv.conf
sudo mv     $MNT_P2/etc/resolv.conf.org $MNT_P2/etc/resolv.conf

sudo umount $MNT_P1
sudo umount $MNT_P2
sudo losetup -d $DEV_LOOP

sudo rmdir $MNT_P1
sudo rmdir $MNT_P2
