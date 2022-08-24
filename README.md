# tmt-convert-utils
Some scripts to help with TMT conversion

## tmt-convert.sh

This script helps convert the case, it can do some simple and repetitive things for you, including analyzing the RHTS Makefile and the restraint metadata file, and initializing the tmt support.

Usage:

1. Go to the folder of the case you want to convert (ex `./kernel/rt-tests/smidetect/`).
2. Run `tmt-convert.sh`.

This script will create the following files for you:
- ./plans/smidetect.fmf
- ./plans/tmt.env
- ./tests/smidetect.fmf
- ./metadata (adding `repoRequires=automotive/include` if file exists)

> The conversion logic of the script is designed based on this example:  
> https://gitlab.com/redhat/centos-stream/tests/kernel/kernel-tests/-/tree/main/security/integrity/2063913

What you need to do are inspect the files and modify the `runtest.sh`. For example including the helper functions and skipping some RHEL-only logics:

```
# Enable TMT testing for RHIVOS
. ../../automotive/include/include.sh || exit 1
: ${OUTPUTFILE:=runtest.log}

if ! kernel_automotive; then
    # Include rhts environment
    . /usr/bin/rhts-environment.sh || exit 1
fi
```

## tmt-test.sh and tmt-test-pub.sh

These scripts help run the TMT test against local VM and Respberry Pi.
Update the VERIABLES (ex. CODEPATH) before running the scripts.

Usage:
./tmt-test.sh <vm/pi> <casename1> [casename2] ...

