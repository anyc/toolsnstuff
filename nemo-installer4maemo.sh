#! /bin/bash

### Nemo installer for Maemo
#
# This installer writes the nemo raw image to the SD card and
# adds a menu entry for u-boot
#
# Written 2013 by Mario Kicherer (http://kicherer.org)

RAWFILE=nemo-armv7hl-n900-mmcblk0p.raw.bz2
SDCARD=/dev/mmcblk1
BOOTMENU_ITEM=/etc/bootmenu.d/20-nemo-mobile.item

if [ "$(whoami)" != "root" ]; then
	echo "You need to be root for this script!"
	exit 1
fi

if ! which u-boot-update-bootmenu > /dev/null; then
	echo ""
	echo "It looks like you don't have u-boot installed!"
	echo ""
fi

if [ ! -e ${RAWFILE} ]; then
	echo "Raw file ${RAWFILE} not found"
	echo "Download latest release from http://releases.nemomobile.org/snapshots/images/"
	echo ""
	echo "E.g.: wget http://releases.nemomobile.org/snapshots/images/0.20130411.1.NEMO.2013-04-26.1/nemo-armv7hl-n900/nemo-armv7hl-n900-mmcblk0p.raw.bz2"
	exit 1
fi

# safety check if mmcblk0 is really internal mmc
if ! grep "/dev/mmcblk0p2 /home" /proc/mounts > /dev/null; then
	echo "Safety check failed"
	exit 1
fi

if [ ! -e ${SDCARD} ]; then
	echo "SD card ${SDCARD} not found, is your SD card in the device?"
	exit 1
fi

if grep mmcblk1 /proc/mounts > /dev/null; then
	echo "umount SD card"
	for m in /media/mmc1*; do
		umount $m
	done
fi

echo "Notice: this script is only supplementary to the installation guide https://wiki.merproject.org/wiki/Nemo/Installing#Nokia_N900 !"
echo ""

RAWSIZE=$(du -h ${RAWFILE} | cut -f1)

echo "Writting image \"${RAWFILE}\" (${RAWSIZE}) to SD card ${SDCARD} in 5 seconds (abort with STRG+c)... "
for i in `seq 5`; do
	echo -n "$i "
	sleep 1
done
echo ""

echo "Write started, this may take several minutes. Now: $(date)"
if which pv; then
	# pv shows progress information
	bzcat ${RAWFILE} | pv | dd bs=4096 of=${SDCARD}
else
	bzcat ${RAWFILE} | dd bs=4096 of=${SDCARD}
fi

if [ ! -e ${BOOTMENU_ITEM} ]; then
	echo "creating u-boot menu entry"
	cat > ${BOOTMENU_ITEM} << EOF
ITEM_NAME="Nemo Mobile"
ITEM_KERNEL="uImage"
ITEM_DEVICE="\${EXT_CARD}p3"
ITEM_FSTYPE="vfat"
ITEM_CMDLINE="root=/dev/mmcblk0p1 rootwait rw console=tty02,115200n8 console=tty0 omapfb.vram=0:2M,1:2M,2:2M mtdoops.mtddev=2"
ITEM_OMAPATAG="1"
EOF
	echo "updating u-boot menu"
	u-boot-update-bootmenu
fi

echo "Finished. Now: $(date)"
echo ""
echo "1. open the keyboard and reboot your device"
echo "2. select \"u-boot console\" in the menu"
echo "3. Enter \"run sdboot\""