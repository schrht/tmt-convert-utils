#!/bin/bash

# Desciption: Trigger beaker jobs for verifiying code changes on RHEL.
# Owner: Charles Shi <cheshi@redhat.com>

# Update the following variables before use
DEFAULT_HOSTFILTER=INTEL
DEFAULT_DISTRO=RHEL-9.1.0
DEFAULT_ARCH=x86_64,ppc64le,s390x,aarch64
PUBLIC_REPO_URL=https://gitlab.com/schrht/kernel-tests
PRIVATE_REPO_URL=https://gitlab.cee.redhat.com/cheshi/kernel

# Function
function show_usage() {
  echo "Description:"
  echo "  Trigger beaker jobs for verifiying code changes on RHEL."
  echo "Usage:"
  echo "  $(basename $0) <-f HOSTFILTER> <-d DISTRO> <-a ARCH> <-r REPOSITORY> <-b BRANCH> <-p PATH> [-D]"
  echo "  - HOSTFILTER: Filter name defined in ~/.beaker_client/host-filter"
  echo "  - DISTRO    : RHEL-9.1.0"
  echo "  - ARCH      : x86_64, ppc64le, s390x, aarch64 (separated by commas)"
  echo "  - REPOSITORY: public, private"
  echo "  - BRANCH    : main, mr_branch_name"
  echo "  - PATH      : Ex. rt-tests/env_test"
  echo "  - DRYRUN    : Show bkr command only if '-D' presents"
  echo "Available HOSTFILTER(s):"
  echo "  $(cat ~/.beaker_client/host-filter | awk '{print $1}' | xargs)"
  echo "Example:"
  echo "  $(basename $0) -h INTEL -d RHEL-9.1.0 -a x86_64 -r private -b master -p rt-tests/env_test"
  echo "Notes:"
  echo "  1. Follow https://docs.engineering.redhat.com/display/Automotive/Configure+beaker+client to setup;"
  echo "  2. Update hardcoded VARIABLEs before using."
}

function verify_task() {
  echo "Verifing $verify_url ..."

  if (curl $verify_url/metadata 2>/dev/null | grep -q 'automotive/include' ||
    curl $verify_url/runtest.sh 2>/dev/null | grep -q 'kernel_automotive'); then
    echo "Verified $path: SUCCESS (PATH EXISTS AND AUTOMOTIVE CODE FOUND)"
    return 0
  fi

  if (curl $verify_url/metadata 2>/dev/null | grep -q 'restraint' ||
    curl $verify_url/Makefile 2>/dev/null | grep -q '^run:' ||
    curl $verify_url/runtest.sh 2>/dev/null | grep -q '^#!/bin/bash'); then
    echo "Verified $path: FAIL (PATH EXISTS BUT AUTOMOTIVE CODE NOT FOUND)"
    return 1
  else
    echo "Verified $path: FAIL (PATH NOT FOUND)"
    return 2
  fi
}

while getopts :hf:d:a:r:b:p:D ARGS; do
  case $ARGS in
  h)
    # Help option
    show_usage
    exit 0
    ;;
  f)
    # HOSTFILTER option
    hostfilter=$OPTARG
    ;;
  d)
    # DISTRO option
    distro=$OPTARG
    ;;
  a)
    # ARCH option
    arch=$OPTARG
    ;;
  r)
    # REPOSITORY option
    repository=$OPTARG
    ;;
  b)
    # BRANCH option
    branch=$OPTARG
    ;;
  p)
    # PATH option
    path=$OPTARG
    ;;
  D)
    # DRYRUN option
    dryrun=1
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

[ -z "$hostfilter" ] && hostfilter=$DEFAULT_HOSTFILTER
[ -z "$distro" ] && distro=$DEFAULT_DISTRO
[ -z "$arch" ] && arch=$DEFAULT_ARCH
[ -z "$repository" ] && repository=public

if [ -z "$path" ]; then
  show_usage
  exit 1
fi

case $repository in
public)
  [ -z "$branch" ] && branch=main
  task_url=$PUBLIC_REPO_URL/-/archive/$branch/kernel-$branch.tar.gz#$path
  verify_url=$PUBLIC_REPO_URL/-/raw/$branch/$path
  ;;
private)
  [ -z "$branch" ] && branch=master
  task_url=$PRIVATE_REPO_URL/-/archive/$branch/kernel-$branch.tar.gz#$path
  verify_url=$PRIVATE_REPO_URL/-/raw/$branch/$path
  ;;
*)
  echo "$(basename $0): unexpected REPOSITORY." >&2
  show_usage
  exit 1
  ;;
esac

if ! verify_task; then
  echo -e "\nWARNING: The test can be failed or becomes meaningless."
  dryrun=1
fi

whiteboard="$(basename $0) $path $distro ($arch)"
cmd="bkr workflow-tomorrow --restraint --distro $distro --arch $arch \
  --systype Machine --host-filter $hostfilter --crb --ignore-panic \
  --ks-meta redhat_ca_cert --url --whiteboard \"$whiteboard\" \
  --task $task_url"

echo -e "----\nCommand to schedule this job:\n$cmd"

if ! ((dryrun)); then
  echo -e "\nScheduling this job..."
  eval $cmd
else
  echo -e "\nAbove job has not been scheduled."
fi
