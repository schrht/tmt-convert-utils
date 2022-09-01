#!/bin/bash

# Owner: cheshi@redhat.com
# Description: This script help to start a RHIVOS VM through QEMU.
# Dependences: sample-images: https://gitlab.com/CentOS/automotive/sample-images.git

# Update the following variables before use
SAMPLE_IMAGES_PATH=/home/cheshi/workspace/os-tree-trial/sample-images

image=${1:-auto-osbuild-qemu-cs9-qa-ostree-x86_64-579942379.071ed0c0.qcow2}

cpu_opts="-smp cpus=4"

numa_opts="-machine hmat=on \
-m 2G,slots=2,maxmem=4G \
-object memory-backend-ram,size=1G,id=m0 \
-object memory-backend-ram,size=1G,id=m1 \
-numa node,nodeid=0,memdev=m0 \
-numa node,nodeid=1,memdev=m1 \
-smp 4,sockets=2,maxcpus=4  \
-numa cpu,node-id=0,socket-id=0 \
-numa cpu,node-id=1,socket-id=1"

#${SAMPLE_IMAGES_PATH}/osbuild-manifests/runvm --verbose $image -nographic $cpu_opts
${SAMPLE_IMAGES_PATH}/osbuild-manifests/runvm --verbose $image -nographic $numa_opts
