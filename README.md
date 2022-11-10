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
. ../../automotive/include/include.sh
declare -F kernel_automotive && kernel_automotive && is_rhivos=1 || is_rhivos=0

if ! (($is_rhivos)); then
    # Include rhts environment
    . /usr/bin/rhts-environment.sh || exit 1
fi
```

## tmt-test.sh

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

## tmt-log-push.sh

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

## tmt-vm.sh

This script help to start a RHIVOS VM through QEMU. Notes: Update hardcoded VARIABLEs before using.

## tmt-beaker.sh

Usage:

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

Example:

```
[cheshi@dhcp-89-35 ~]$ tmt-beaker.sh -f AUTOQE_NUMA2 -d RHEL-9.1.0 -r private -b auto-rt-tests-mr3 -a x86_64,aarch64,ppc64le,s390x -p general/scheduler/sched_rt_app
Verifing https://gitlab.cee.redhat.com/cheshi/kernel/-/raw/auto-rt-tests-mr3/general/scheduler/sched_rt_app ...
Verified general/scheduler/sched_rt_app: SUCCESS (PATH EXISTS AND AUTOMOTIVE CODE FOUND)
----
Command to schedule this job:
bkr workflow-tomorrow --restraint --distro RHEL-9.1.0 --arch x86_64,aarch64,ppc64le,s390x     --systype Machine --host-filter AUTOQE_NUMA2 --crb --ignore-panic     --ks-meta redhat_ca_cert --whiteboard "tmt-beaker.sh general/scheduler/sched_rt_app RHEL-9.1.0 (x86_64,aarch64,ppc64le,s390x)" --url     --task https://gitlab.cee.redhat.com/cheshi/kernel/-/archive/auto-rt-tests-mr3/kernel-auto-rt-tests-mr3.tar.gz#general/scheduler/sched_rt_app
 
Scheduling this job...
Using distro rhel-9.1.0 from the command line
Distro RHEL-9.1.0% scheduled using latest CTS_NIGHTLY tag
Distro RHEL-9.1.0% scheduled using latest CTS_NIGHTLY tag
Distro RHEL-9.1.0% scheduled using latest CTS_NIGHTLY tag
Distro RHEL-9.1.0% scheduled using latest CTS_NIGHTLY tag
Found 1 singlehost task, 4 recipe sets created
Successfully submitted as TJ#7004757
https://beaker.engineering.redhat.com//jobs/7004757
```

## tmt-check-code.sh (developing)

Locate code needs to be updated by searching for specific patterns.

## tmt-check-log.sh (developing)

Find potential errors in log file by searching for specific patterns.

## insert_required_packages.py

In the early days of tmt conversion, we only inserted the required packages into the plan-fmf file, and current best practice requires us to insert the required packages into the test-fmf file as well. This script helps us fix it.

```
usage: insert_required_packages.py [-h] --pfmf PFMF --tfmf TFMF

Read required packages from plan-fmf and write to test-fmf.

options:
  -h, --help   show this help message and exit
  --pfmf PFMF  plan fmf file
  --tfmf TFMF  test fmf file
```

Note: The `tmt-convert.sh` has been updated to insert required packages into test-fmf for you.

Example:
```
# Copy package list for the specific test "ktst_msg"
[cheshi@fedora kernel]$ cd misc/ktst_msg/

[cheshi@fedora ktst_msg]$ tree
.
├── ktst-cred.c
├── ktst-fcntl.c
├── ktst-msg.c
├── ktst-sem.c
├── ktst-shm.c
├── Makefile
├── plans
│   ├── ktst_msg.fmf
│   └── tmt.env
├── PURPOSE
├── runtest.sh
└── tests
    └── ktst_msg.fmf

2 directories, 11 files

# 4 packages are defined in plan-fmf
[cheshi@fedora ktst_msg]$ cat ./plans/ktst_msg.fmf
summary: "Kernel messaging test Written by Ulirich Drepper"
discover:
    how: fmf
    test:
        - /misc/ktst_msg/tests/ktst_msg
execute:
    how: tmt
    framework: beakerlib
prepare:
  - name: Enable Repos
    how: shell
    script: |
        . ./general/include/rhivos.sh
        install_repos
  - name: Install packages
    how: install
    package: [beakerlib, gcc,kernel-devel,glibc-devel]
environment-file:
  - ./misc/ktst_msg/plans/tmt.env

# Copy the package list to the corresponding test-fmf
[cheshi@fedora ktst_msg]$ insert_required_packages.py --pfmf ./plans/ktst_msg.fmf --tfmf ./tests/ktst_msg.fmf

# 4 packages have been copied to test-fmf
[cheshi@fedora ktst_msg]$ git diff
diff --git a/misc/ktst_msg/tests/ktst_msg.fmf b/misc/ktst_msg/tests/ktst_msg.fmf
index b382af9546..80df66c8da 100644
--- a/misc/ktst_msg/tests/ktst_msg.fmf
+++ b/misc/ktst_msg/tests/ktst_msg.fmf
@@ -30,6 +30,11 @@ component:
 test: make run
 path: /misc/ktst_msg
 framework: shell 
+require:
+  - beakerlib
+  - gcc
+  - kernel-devel
+  - glibc-devel
 duration: 180m
 extra-summary: /kernel/misc/ktst_msg
 extra-task: /kernel/misc/ktst_msg
```

In the example above, `insert_required_packages.py` read 4 packages from `./plans/ktst_msg.fmf` and inserted them into `./tests/ktst_msg.fmf`. You can also batch do this for all similar cases:

```
cd kernel-tests
for pfmf in $(find . -type f -name *.fmf | grep '/plans/'); do
    tfmf=${pfmf/plans/tests}
    [ ! -f $tfmf ] && continue
    ./insert_required_packages.py --pfmf $pfmf --tfmf $tfmf
done
```

WARNING: This script is used to "copy" package list "inside" a specific test, you shouldn't use it across repos.
