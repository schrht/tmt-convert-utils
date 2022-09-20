# tmt-convert-utils
Some scripts to help with TMT conversion

# tmt-convert.sh

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

# tmt-test.sh

```
Description:
  Trigger TMT tests over Local VM or Respberry Pi.
Usage:
  tmt-test.sh <-p PLATFORM> <-r REPOSITORY> <-t TESTS>
  - PLATFORM  : vm|pi
  - REPOSITORY: public|private
  - TESTS     : 'casename1 casename2 ...'
Example:
  tmt-test.sh -p vm -r private -t "auto_kernel_check rt_check"
Notes:
  Update hardcoded VARIABLEs before using.
```

# tmt-log-push.sh

```
Description:
  This script pushes log to the file server.
Usage:
  tmt-log-push.sh <logfile1> [logfile2] ...
Example:
  tmt-log-push.sh *.log
Notes:
  Update hardcoded VARIABLEs before using.
```

# tmt-vm.sh

This script help to start a RHIVOS VM through QEMU. Notes: Update hardcoded VARIABLEs before using.

# tmt-beaker.sh

```
Description:
  Trigger beaker jobs for verifiying code changes on RHEL.
Usage:
  tmt-beaker.sh <-f HOSTFILTER> <-d DISTRO> <-a ARCH> <-r REPOSITORY> <-b BRANCH> <-p PATH> [-D]
  - HOSTFILTER: Filter name defined in ~/.beaker_client/host-filter
  - DISTRO    : RHEL-9.1.0
  - ARCH      : x86_64, ppc64le, s390x, aarch64 (separated by commas)
  - REPOSITORY: public, private
  - BRANCH    : main, mr_branch_name
  - PATH      : Ex. rt-tests/env_test
  - DRYRUN(-D): If presents, show bkr command only
Available HOSTFILTER(s):
  INTEL_6_79_1 INTEL_6_63_2 INTEL_6_85_4 AMD_23 INTEL_6_60_3 INTEL_6_58_9 INTEL_6_44_2 INTEL_6_42_7 INTEL_6_30_5 AMD INTEL ICELAKE CASCADELAKE KABYLAKE SKYLAKE BROADWELL HASWELL1 HASWELL2 IVY1 IVY2 SANDY1 SANDY2 RHEL8 RHEL6VM RHEL7VM RHEL8VM RHEL9VM THUNDERX_2 HUAWEI_D05 HUAWEI_D06 NVME ROME MILAN WIRELESS NOGSS NOGSS_MEMORY_MIN_16G RHEL7z RHEL8z RHEL83z RHELRT INTEL_RT AMD_RT IBM__POWER9_NUMAGT_1 INTEL__ICELAKE_NUMAGT_1 TRACEBLACKLIST RTS_NUMA2 AUTOQE_NUMA2
Example:
  tmt-beaker.sh -h INTEL -d RHEL-9.1.0 -a x86_64 -r private -b master -p rt-tests/env_test
Notes:
  1. Follow https://docs.engineering.redhat.com/display/Automotive/Configure+beaker+client to setup;
  2. Update hardcoded VARIABLEs before using.
```

# tmt-check-code.sh (developing)

Locate code needs to be updated by searching for specific patterns.

# tmt-check-code.sh (developing)

Find potential errors in log file by searching for specific patterns.
