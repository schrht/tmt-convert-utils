#!/bin/bash

# Owner: cheshi@redhat.com
# Description: Trigger TMT tests over Local VM or Respberry Pi.

# Update the following variables before use
PUBLIC_CODEPATH=/home/cheshi/mirror/codespace/kernel-tests
PRIVATE_CODEPATH=/home/cheshi/mirror/codespace/kernel
VM_ARCH=x86_64
VM_HOST=localhost
VM_PORT=2222
PI_HOST=10.18.89.168
PI_PORT=22

function show_usage() {
	echo "Description:"
	echo "  Trigger TMT tests over Local VM or Respberry Pi."
	echo "Usage:"
	echo "  $(basename $0) <-r REPOSITORY> <-p PLATFORM> <-t TESTS>"
	echo "  - REPOSITORY: public|private"
	echo "  - PLATFORM  : vm|pi"
	echo "  - TESTS     : 'casename1 casename2 ...'"
	echo "Notes:"
	echo "  Update VARIABLEs before using."
}

while getopts :hr:p:t: ARGS; do
	case $ARGS in
	h)
		# Help option
		show_usage
		;;
	r)
		# Repository option
		repository=$OPTARG
		;;
	p)
		# Platform option
		platform=$OPTARG
		;;
	t)
		# Tests option
		tests=$OPTARG
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

if [ -z "$repository" ] || [ -z "$platform" ] || [ -z "$tests" ]; then
	show_usage
	exit 1
fi

case $repository in
public)
	codepath=$PUBLIC_CODEPATH
	;;
private)
	codepath=$PRIVATE_CODEPATH
	;;
*)
	echo "$(basename $0): unexpected REPOSITORY." >&2
	show_usage
	exit 1
	;;
esac

case $platform in
vm)
	arch=$VM_ARCH
	host=$VM_HOST
	port=$VM_PORT
	;;
pi)
	arch=aarch64
	host=$PI_HOST
	port=$PI_PORT
	;;
*)
	echo "$(basename $0): unexpected PLATFORM." >&2
	show_usage
	exit 1
	;;
esac

[ -w $PWD ] && path=$PWD || path=$HOME

for casename in $tests; do
	echo -e "\nRun case $casename ..."
	found=$(tmt --root $codepath test ls ${casename} | wc -l)
	if [ $found -ne 1 ]; then
		echo "$(basename $0): Found $found case(s), expected 1, skiped." >&2
		continue
	fi

	timestamp=$(date +%y%m%d%H%M%S)
	testlog=$path/$casename.$arch.$timestamp.log

	tmt --root $codepath run -vvv --debug --all plans -n ${casename}$ \
		provision --how=connect --guest=$host --port=$port --user=root \
		--password=password 2>&1 | tee $testlog
done

exit 0
