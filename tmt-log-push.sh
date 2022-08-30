#!/bin/bash

# Desciption: This script pushes log to the file server.
# Owner: Charles Shi <cheshi@redhat.com>

# Variables
SERVER_NAME=file.bos.redhat.com
SERVER_USER=cheshi
SERVER_PATH=~/public_html/automotive/tmt_enablement/sst_kernel_rts/

# Function
function show_usage() {
    echo "Description:"
    echo "  This script pushes log to the file server."
    echo "Usage:"
    echo "  $(basename $0) <logfile1> [logfile2] ..."
    echo "Notes:"
    echo "  Update VARIABLEs before using."
}

# Main
[ -z $1 ] && show_usage && exit 1

echo -e "\nINFO: Identifing..."
files=()
for f in $@; do
    [ -f $f ] && ls -l $f && files+=($f)
done

if [ -n "${files[0]}" ]; then
    echo "Identified ${#files[@]} files."
else
    echo "No logfiles identified."
    exit 1
fi

echo -e "\nINFO: Uploading..."
scp ${files[@]} ${SERVER_USER}@${SERVER_NAME}:${SERVER_PATH#*${SERVER_USER}/} || exit 1

echo -e "\nINFO: Summary"
url_prefix=http://${SERVER_NAME}/${SERVER_USER}/${SERVER_PATH#*public_html/}

echo "The logfiles can be accessed by:"
for f in ${files[@]}; do
    echo ${url_prefix}$(basename $f)
done

exit 0
