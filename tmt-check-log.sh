#!/bin/bash

# Owner: cheshi@redhat.com
# Description: Find potential errors from the log file.

# Update the following variables before use
PATTERNS=(
    "error"
    "ERROR"
    " FAIL "
    "failed"
    " WARN "
    "WARNING"
    "ambiguous redirect"
    "not found"
    "unary operator expected"
    "No such file or directory"
    "rstrnt-report-result.*FAIL"
    "rstrnt-report-result.*SKIP"
)

# Function
function show_usage() {
    echo "Description:"
    echo "  Find potential errors from the log file."
    echo "Usage:"
    echo "  $(basename $0) <logfile>"
    echo "Example:"
    echo "  $(basename $0) runtest.log"
    echo "Notes:"
    echo "  Update hardcoded VARIABLEs before using."
}

# Main
[ -z $1 ] && show_usage && exit 1

if [ -f $1 ]; then
    file=$1
else
    echo "Cannot found a bash script ($1)."
fi

for p in "${PATTERNS[@]}"; do
    grep -n -e "$p" $file
done

exit 0
