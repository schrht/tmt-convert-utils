#!/bin/bash

# Desciption: this script helps with the TMT enablement.
# Owner: Charles Shi <cheshi@redhat.com>

# Functions
function analyse_metadata() {
  [ -f $real_path/metadata ] || return 1

  case_owner="$(grep ^owner= $real_path/metadata | cut -d = -f 2-)"
  case_description="$(grep ^description= $real_path/metadata | cut -d = -f 2-)"
  case_duration="$(grep ^max_time= $real_path/metadata | cut -d = -f 2-)"
  case_packages="$(grep ^dependencies= $real_path/metadata | cut -d = -f 2- | tr ';' ' ')"
}

function analyse_makefile() {
  [ -f $real_path/Makefile ] || return 1

  tmpd=$(mktemp -d)
  pushd $tmpd || return 1

  # Extract metadata from Makefile
  cp $real_path/Makefile .
  sed -i 's/^include/#include/' Makefile
  sed -i 's/rhts-lint/#rhts-lint/' Makefile
  sed -i 's/\$(METADATA)/metadata.info/' Makefile
  make metadata.info

  # Query metadata
  case_owner="$(grep ^Owner: metadata.info | cut -d : -f 2- | xargs)"
  case_description="$(grep ^Description: metadata.info | cut -d : -f 2- | xargs)"
  case_duration="$(grep ^TestTime: metadata.info | cut -d : -f 2- | xargs)"
  case_packages="$(grep ^Requires: metadata.info | cut -d : -f 2- | xargs)"

  case_license="$(grep ^License: metadata.info | cut -d : -f 2- | xargs)"
  case_confidential="$(grep ^Confidential: metadata.info | cut -d : -f 2- | xargs)"
  case_destructive="$(grep ^Destructive: metadata.info | cut -d : -f 2- | xargs)"

  popd
  rm -rf $tmpd
}

function create_tmt_files() {
  echo "INFO: Creating tmt files."

  echo "DEBUG: CASE_NAME: ${case_name:='TBD_NAME'}"
  echo "DEBUG: CASE_DESCRIPTION: ${case_description:='TBD_CASE_DESCRIPTION'}"
  echo "DEBUG: CASE_OWNER: ${case_owner:='TBD_CASE_OWNER'}"
  echo "DEBUG: CASE_DURATION: ${case_duration:='TBD_CASE_DURATION'}"
  echo "DEBUG: CASE_PACKAGES: ${case_packages:='TBD_CASE_PACKAGES'}"

  mkdir -p $real_path/plans $real_path/tests || exit 1
  mkdir -p $real_path/plans $real_path/tests || exit 1

  echo "INFO: Creating $real_path/plans/tmt.env"
  touch $real_path/plans/tmt.env

  echo "INFO: Creating $real_path/plans/${case_name}.fmf"
  cat >$real_path/plans/${case_name}.fmf <<EOF
summary: ${case_description}
discover:
    how: fmf
    test:
        - ${case_path}
execute:
    how: tmt
    framework: shell
prepare:
    - name: Enable Repos
      how: shell
      script: |
          . ./automotive/include/include.sh
          install_repos
    - name: Install packages
      how: install
      package: [${case_packages// /\, }]
environment-file:
    - .${case_path}/plans/tmt.env
EOF

  echo "INFO: Creating $real_path/tests/${case_name}.fmf"
  cat >$real_path/tests/${case_name}.fmf <<EOF
summary: ${case_description}
description: ${case_description}
contact: ${case_owner}
component:
  - kernel
path: ${case_path}
test: bash -x ./runtest.sh
framework: beakerlib
duration: ${case_duration}
extra-summary: ${case_path}
extra-task: ${case_path}
EOF
}

function update_metadata() {
  echo "INFO: Updating metadata for restraint."
  [ -f $real_path/metadata ] || exit 1

  if (grep -q '^repoRequires=.*automotive/include' $real_path/metadata); then
    echo "INFO: 'automotive/include' is already in 'repoRequires', skipped."
    return 0
  fi

  echo "INFO: Updating $real_path/metadata"
  if (grep -q '^repoRequires=' $real_path/metadata); then
    echo "INFO: Appending 'automotive/include' to 'repoRequires'."
    sed -i 's#^repoRequires=.*#&;/automotive/include#' $real_path/metadata
  else
    echo "INFO: Adding 'repoRequires=automotive/include'."
    sed -i '/^\[restraint\]$/a repoRequires=automotive/include' $real_path/metadata
  fi

  return 0
}

function create_metadata() {
  echo "INFO: Creating metadata for restraint."
  [ -f $real_path/metadata ] && exit 1

  echo "DEBUG: CASE_NAME: ${case_name:='TBD_NAME'}"
  echo "DEBUG: CASE_DESCRIPTION: ${case_description:='TBD_CASE_DESCRIPTION'}"
  echo "DEBUG: CASE_OWNER: ${case_owner:='TBD_CASE_OWNER'}"
  echo "DEBUG: CASE_DURATION: ${case_duration:='TBD_CASE_DURATION'}"
  echo "DEBUG: CASE_PACKAGES: ${case_packages:='TBD_CASE_PACKAGES'}"
  echo "DEBUG: CASE_LICENSE: ${case_license:='TBD_CASE_LICENSE'}"
  echo "DEBUG: CASE_CONFIDENTIAL: ${case_confidential:='TBD_CASE_CONFIDENTIAL'}"
  echo "DEBUG: CASE_DESTRUTIVE: ${case_destructive:='TBD_CASE_DESTRUTIVE'}"

  echo "INFO: Creating $real_path/metadata"
  cat >$real_path/metadata <<EOF
[General]
name=${case_path/\//}
owner=${case_owner}
description=${case_description}
license=${case_license}
confidential=${case_confidential}
destructive=${case_destructive}

[restraint]
entry_point=make run
dependencies=${case_packages// /\;}
repoRequires=automotive/include
max_time=${case_duration}
use_pty=false
EOF
}

# Main
real_path=$PWD
echo "DEBUG: WORKSPACE: $real_path"

# Get basic information
if [[ $real_path =~ '/kernel-tests/' ]]; then
  repo_name=kernel-tests
  case_path=${real_path/#*kernel-tests/}
elif [[ $real_path =~ '/kernel/' ]]; then
  repo_name=kernel
  case_path=${real_path/#*kernel/}
else
  echo "ERROR: path '$real_path' cannot be handled."
  exit 1
fi

case_name=$(basename $real_path)
echo "DEBUG: REPO_NAME: $repo_name"
echo "DEBUG: CASE_PATH: $case_path"
echo "DEBUG: CASE_NAME: $case_name"

if [ -f $real_path/metadata ]; then
  analyse_metadata
  create_tmt_files
  update_metadata
elif [ -f $real_path/Makefile ]; then
  analyse_makefile
  create_tmt_files
  create_metadata
fi

exit 0
