#!/bin/bash

# Owner: cheshi@redhat.com
# Description: Run TMT test with VM or Pi.

CODEPATH=/home/cheshi/mirror/codespace/kernel
VM_HOST=localhost
VM_PORT=2222
PI_HOST=10.18.89.168
PI_PORT=22

function usage() {
	echo "$0 <vm/pi> <casename1> [casename2] ..."
}

[ $# -lt 2 ] && usage && exit 1

testbed=$1
shift
casenames=$@

case $testbed in
vm)
	arch=x86_64
	host=$VM_HOST
	port=$VM_PORT
	;;
pi)
	arch=aarch64
	host=$PI_HOST
	port=$PI_PORT
	;;
*)
	usage
	exit 1
	;;
esac

[ -w $PWD ] && path=$PWD || path=$HOME

for casename in $casenames; do
	echo -e "\nRun case $casename ..."

	timestamp=$(date +%y%m%d%H%M%S)
	TESTLOG=$path/$casename.$arch.$timestamp.log

	tmt --root $CODEPATH run -vvv --debug --all plans -n $casename \
		provision --how=connect --guest=$host --port=$port --user=root \
		--password=password 2>&1 | tee $TESTLOG
done

exit 0
