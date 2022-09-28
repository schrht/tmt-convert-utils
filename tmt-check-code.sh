#!/bin/bash

# Owner: cheshi@redhat.com
# Description: Locate code needs to be updated by searching for specific patterns.

# Update the following variables before use
PATTERNS=("rhts" "yum" "dnf" "report_result" "/boot/config")

# Function
function show_usage() {
    echo "Description:"
    echo "  Locate code needs to be updated by searching for specific patterns."
    echo "Usage:"
    echo "  $(basename $0) <shell-script>"
    echo "Example:"
    echo "  $(basename $0) runtest.sh"
    echo "Notes:"
    echo "  Update hardcoded VARIABLEs before using."
}

function title() {
    echo
    echo $@
    echo "----------"
}

# Main
[ -z $1 ] && show_usage && exit 1

if [ -f $1 ]; then
    file=$1
else
    echo "Cannot found a bash script ($1)."
fi

for p in "${PATTERNS[@]}"; do
    title $p
    grep -n -e "$p" $file
done

exit 0
