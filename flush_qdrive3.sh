#!/bin/bash

# Description: download image and flush the qdrive3 board.
set -e

function usage() {
	echo "Description: download image and flush the qdrive3 board."
	echo "Usage: $0 <IMAGE_LABEL> <SOC#>"
	echo "Example: $0 ER1.2.1 SOC1"
}

if [[ ! "$1" =~ "ER*" ]]; then
	echo "ERROR: Got unsupported IMAGE_LABEL ($1)."
	usage
	exit 1
fi

if [ "$2" != "SOC1" ] || [ "$2" != "SOC2" ]; then
	echo "ERROR: Got unsupported SOC# ($2)."
	usage
	exit 1
fi

label=$1
soc=$2

baseurl=http://10.29.162.171:8080/in-vehicle-os-9/$label/QDrive3/

# Identify image name and files
echo "INFO: Identifing image name and files..."
tmpd=$(mktemp -d)
if curl $baseurl -o $tmpd/page.txt; then
	root_img=$(cat $tmpd/page.txt | grep 'a href=".*.xz"' | cut -d '"' -f 6)
	root_img_hash=$(cat $tmpd/page.txt | grep 'a href=".*.xz.sha256"' | cut -d '"' -f 6)
	boot_img=$(cat $tmpd/page.txt | grep 'a href=".*.img"' | cut -d '"' -f 6)
else
	echo "ERROR: Cannot analyse $baseurl. Check the label ($label)."
fi

if [ -n "$root_img" ] && [ -n "$root_img_hash" ] && [ -n "$boot_img" ]; then
	echo "INFO: Identified 3 image files."
else
	echo "ERROR: Some of the files cannot be identified. Exiting."
	exit 1
fi

root_img_name=$(basename $root_img .xz)
echo "INFO: Got the Root Image Name $root_img_name"

# Download the files if needed
echo "INFO: Downloading the files..."
if [ -f "$root_img" ] || [ -f "$root_img_name" ] || [ -f "${root_img_name}.simg" ]; then
	echo "INFO: root image already exists."
else
	curl -O $/baseurl/root_img
	curl -O $/baseurl/root_img_hash

	echo "INFO: Verifying the downloads..."
	sha256sum -c $root_img_bash || exit 1
fi

if [ -f "$boot_img" ]; then
	echo "INFO: $boot_img already exists."
else
	curl -O $baseurl/$boot_img
fi

# Deal with the root image
if [ -f "${root_img_name}.simg" ]; then
	echo "INFO: Root image is ready."
else
	if [ -f "$root_img_name" ]; then
		echo "INFO: Root image has been unzipped."
	else
		echo "INFO: Unzipping root image..."
		xz -d $root_img || exit 1
	fi

	echo "INFO: Converting root image..."
	img2simg $root_img_name ${root_img_name}.simg && rm -f $root_img_name || exit 1
fi

# Prepare to flush the board
if [ $soc = SOC1 ]; then
	echo "Preparing to flush SOC1 ..."
	python ~/qdrive_alpaca_python/PowerOffSOC1.py || exit 1
	sleep 2
	python ~/qdrive_alpaca_python/BootToFastBoot.py || exit 1
elif [ $soc = SOC2 ]; then
	echo "Preparing to flush SOC2 ..."
	python ~/qdrive_alpaca_python/PowerOffSOC2.py || exit 1
	sleep 2
	python ~/qdrive_alpaca_python/BootToFastBootSecondary.py || exit 1
fi

# Get the bootable device
if [ $(fastboot -l devices | grep usb: | wc -l) = 1 ]; then
	boot_dev=$(fastboot -l devices | grep usb: | xargs)
else
	echo "ERROR: Zero or more than one bootable USB devices found. Exiting."
	exit 1
fi
[ -z "$boot_dev" ] && echo "ERROR: Failed to get the bootable USB device."

fastboot -s $boot_dev flash boot_a $boot_img || exit 1
sleep 5
fastboot -s $boot_dev flash system_a ${root_img_name}.simg || exit 1
sleep 10
fastboot -s $boot_dev continue

exit 0

