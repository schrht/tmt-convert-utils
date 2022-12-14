#!/bin/bash

# Owner: cheshi@redhat.com
# Description: Download image and flash the qdrive3 board.

BASEURL=http://10.29.162.171:8080/in-vehicle-os-9

function show_usage() {
	echo "Description:"
	echo "  Download image and flash the qdrive3 board."
	echo "Usage:"
	echo "  $0 <-l IMAGE_LABEL> <-s SOC#> [-p PARTITION]"
	echo "    - IMAGE_LABEL: label to find images (ex. ER1.2.1)"
	echo "    - SOC#       : 1|2"
	echo "    - PARTITION  : userdata|system_a|system_b"
	echo "Example:"
	echo "  $0 -l ER1.2.1 -s 1 -p userdata"
	echo "  $0 -l ER1.2.1-rc2 -s 2"
	echo "Notes:"
	echo "  This tool should be used on sidekick."
}

while getopts :hl:s:p: ARGS; do
	case $ARGS in
	h)
		# Help option
		show_usage
		;;
	l)
		# IMAGE_LABEL option
		image_label=$OPTARG
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

if [ -z "$image_label" ] || [ -z "$soc" ]; then
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
	echo "INFO: Flash to partition 'userdata'."
	partition=userdata
	;;
"userdata")
	echo "INFO: Flash to partition 'userdata'."
	;;
"system_a")
	echo "INFO: Flash to partition 'system_a'."
	;;
"system_b")
	echo "INFO: Flash to partition 'system_b'."
	;;
*)
	echo "ERROR: Unsupported PARTITION ($partition)."
	show_usage
	exit 1
	;;
esac

# Identify images
baseurl=$BASEURL/$image_label/QDrive3/
echo "INFO: Identifing images from \"$baseurl\"..."

tmpd=$(mktemp -d)
curl $baseurl -o $tmpd/page.txt

if grep "Not Found" $tmpd/page.txt; then
	echo "ERROR: Failed to retrieve \"$baseurl\". Check the IMAGE_LABEL ($image_label)."
fi

root_img=$(cat $tmpd/page.txt | grep 'a href=".*.xz"' | cut -d '"' -f 6)
root_img_hash=$(cat $tmpd/page.txt | grep 'a href=".*.xz.sha256"' | cut -d '"' -f 6)
boot_img=$(cat $tmpd/page.txt | grep 'a href=".*.img"' | cut -d '"' -f 6)

if [ -n "$root_img" ] && [ -n "$root_img_hash" ] && [ -n "$boot_img" ]; then
	echo "INFO: Identified 3 image files."
else
	echo "ERROR: Some of the files cannot be identified. Exiting."
	exit 1
fi

root_img_name=$(basename $root_img .xz)
echo "INFO: Got the Root Image Name $root_img_name"

# Prepare the images
echo "INFO: Preparing the images..."
if [ -f "$root_img" ] || [ -f "$root_img_name" ] || [ -f "${root_img_name}.simg" ]; then
	echo "INFO: ${root_img_name}* already exists, skip downloading."
else
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
