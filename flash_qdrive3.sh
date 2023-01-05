#!/bin/bash

# Owner: cheshi@redhat.com
# Description: Download image and flash the qdrive3 board.

BASEURL=http://10.29.162.171:8080/in-vehicle-os-9

function show_usage() {
	echo "Description:"
	echo "  Download image and flash the qdrive3 board."
	echo "Usage 1:"
	echo "  $0 <-l IMAGE_LABEL> <-s SOC#> [-p PARTITION]"
	echo "    - IMAGE_LABEL: the label to find images (ex. ER1.2.1)"
	echo "    - SOC#       : the SOC to be flashed (value: 1,2)"
	echo "    - PARTITION  : the partition to flash the OS image to"
	echo "                   (value: userdata,system_a,system_b; default: userdata)"
	echo "Usage 2:"
	echo "  $0 <-r ROOT_IMAGE> <-b BOOT_IMAGE> <-s SOC#> [-p PARTITION]"
	echo "    - ROOT_IMAGE: the local path for root image."
	echo "    - BOOT_IMAGE: the local path for boot image."
	echo "Example 1:"
	echo "  $0 -l ER1.2.1 -s 1 -p userdata"
	echo "  $0 -l ER1.2.1-rc2 -s 2"
	echo "Example 2:"
	echo "  $0 -r ./auto-osbuild-qemu-rhel9.ext4 -b ./sa8540p-boot.img -s 1"
	echo "Notes:"
	echo "  This tool should be used on sidekick."
}

while getopts :hl:r:b:s:p: ARGS; do
	case $ARGS in
	h)
		# Help option
		show_usage
		exit 0
		;;
	l)
		# IMAGE_LABEL option
		image_label=$OPTARG
		;;
	r)
		# ROOT_IMAGE option
		root_img=$OPTARG
		;;
	b)
		# BOOT_IMAGE option
		boot_img=$OPTARG
		;;
	s)
		# SOC# option
		soc=$OPTARG
		;;
	p)
		# PARTITION option
		partition=$OPTARG
		;;
	"?")
		echo "$(basename $0): unknown option: $OPTARG" >&2
		;;
	":")
		echo "$(basename $0): option requires an argument -- '$OPTARG'" >&2
		echo "Try '$(basename $0) -h' for more information." >&2
		exit 1
		;;
	*)
		# Unexpected errors
		echo "$(basename $0): unexpected error -- $ARGS" >&2
		echo "Try '$(basename $0) -h' for more information." >&2
		exit 1
		;;
	esac
done

# Parse parameters
if [ -n "$root_img" ] && [ -n "$boot_img" ]; then
	echo "INFO: Will flash with '$root_img' and '$boot_img'."
elif [ -n "$image_label" ]; then
	echo "INFO: Will identify images by IMAGE_LABEL '$image_label'."
else
	echo "ERROR: Missing mandatory parameters."
	show_usage
	exit 1
fi

if [ -z "$soc" ]; then
	echo "ERROR: Missing mandatory parameters."
	show_usage
	exit 1
fi

if [ "$soc" != "1" ] && [ "$soc" != "2" ]; then
	echo "ERROR: Unsupported SOC# ($2)."
	show_usage
	exit 1
fi

case $partition in
"")
	echo "INFO: Will flash to partition 'userdata'."
	partition=userdata
	;;
"userdata")
	echo "INFO: Will flash to partition 'userdata'."
	;;
"system_a")
	echo "INFO: Will flash to partition 'system_a'."
	;;
"system_b")
	echo "INFO: Will flash to partition 'system_b'."
	;;
*)
	echo "ERROR: Unsupported PARTITION ($partition)."
	show_usage
	exit 1
	;;
esac

# Check environment
space=$(df --block-size M . | tail -1 | awk '{print $4}' | tr -d 'M')
[ $space -lt 4096 ] && echo "ERROR: There is no enough space left (at least 4GB)." && exit 1
[ ! -d ~/qdrive_alpaca_python/ ] && echo "ERROR: ~/qdrive_alpaca_python/ does not exist." && exit 1
! type fastboot &>/dev/null && echo "ERROR: 'fastboot' is not installed." && exit 1

# Identify images
if [ -n "$root_img" ] && [ -n "$boot_img" ]; then
	if [ -f "$root_img" ]; then
		echo "INFO: Will flash with ROOT_IMAGE '$root_img'."
	else
		echo "ERROR: Cannot read the ROOT_IMAGE from '$root_img'."
		exit 1
	fi

	if [ -f "$boot_img" ]; then
		echo "INFO: Will flash with BOOT_IMAGE '$boot_img'."
	else
		echo "ERROR: Cannot read the BOOT_IMAGE from '$boot_img'."
		exit 1
	fi
else
	baseurl=$BASEURL/$image_label/QDrive3/
	echo "INFO: Identifing images from \"$baseurl\"..."

	tmpd=$(mktemp -d)
	curl $baseurl -o $tmpd/page.txt

	if grep "Not Found" $tmpd/page.txt &>/dev/null; then
		echo "ERROR: Failed to retrieve \"$baseurl\". Check the IMAGE_LABEL ($image_label)."
	fi

	root_img=$(cat $tmpd/page.txt | grep 'a href=".*.xz"' | cut -d '"' -f 6)
	root_img_hash=$(cat $tmpd/page.txt | grep 'a href=".*.xz.sha256"' | cut -d '"' -f 6)
	boot_img=$(cat $tmpd/page.txt | grep 'a href=".*.img"' | cut -d '"' -f 6)

	if [ -n "$root_img" ] && [ -n "$root_img_hash" ] && [ -n "$boot_img" ]; then
		echo "INFO: Identified 3 related files."
	else
		echo "ERROR: Some of the files cannot be identified."
		exit 1
	fi
fi

root_img_name=$(basename $root_img .xz)
echo "INFO: Got the Root Image Name $root_img_name"

# Download the images
if [ -f "$root_img" ] || [ -f "$root_img_name" ] || [ -f "${root_img_name}.simg" ]; then
	echo "INFO: ${root_img_name}* already exists, skip downloading."
else
	echo "INFO: Downloading the images..."
	curl -O $baseurl/$root_img
	curl -O $baseurl/$root_img_hash

	echo "INFO: Verifying the downloads..."
	sha256sum -c $root_img_hash || exit 1
fi

if [ -f "$boot_img" ]; then
	echo "INFO: $boot_img already exists, skip downloading."
else
	curl -O $baseurl/$boot_img
fi

# Prepare the root image
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

# Prepare to flash the board
if [ $soc = 1 ]; then
	echo "Preparing to flash SOC1 ..."
	python ~/qdrive_alpaca_python/PowerOffSOC1.py && sleep 2 || exit 1
	python ~/qdrive_alpaca_python/BootToFastBoot.py || exit 1
elif [ $soc = 2 ]; then
	echo "Preparing to flash SOC2 ..."
	python ~/qdrive_alpaca_python/PowerOffSOC2.py && sleep 2 || exit 1
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
fastboot -s $boot_dev flash $partition ${root_img_name}.simg || exit 1
sleep 10
fastboot -s $boot_dev continue

exit 0
