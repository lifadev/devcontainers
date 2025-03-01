#!/bin/bash

set -eux

# region Prerequisites

if [ "$UID" -ne 0 ]; then
  echo -e "(!) User must be root: $UID"
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != 'amd64' ] && [ "$ARCH" != 'arm64' ]; then
  echo "(!) Unsupported architecture: $ARCH"
  exit 1
fi

INSTALL_DIR=/opt
BIN_DIR=$INSTALL_DIR/bin
mkdir -p $BIN_DIR

# endregion

# region Installations

mapfile -t NODE_VERSIONS < <(compgen -A variable | awk -F = '$1 ~ /^NODE[0-9]+_BIN_DIR/ { print $1 }')
if [ "${#NODE_VERSIONS[@]}" -gt "1" ]; then
  echo "(!) Unsupported multiple versions of Node"
  exit 1
fi

NODE_BIN_DIR=${NODE_VERSIONS[0]}
NODE_BIN_DIR=${!NODE_BIN_DIR}
PATH=$PATH:$NODE_BIN_DIR

#? https://www.npmjs.com/package/cdk?activeTab=versions
PACKAGE_VERSION=2.1001.0

npm install -g "cdk@$PACKAGE_VERSION"

# endregion

# region Shell integration

mkdir -p /etc/bash_completion.d

#? https://github.com/aws/aws-cdk/discussions/24380#discussioncomment-5158176
cat <<EOF >>/etc/bash_completion.d/cdk
_cdk_yargs_completions() {
  local cur_word args type_list

  cur_word="\${COMP_WORDS[COMP_CWORD]}"
  args=("\${COMP_WORDS[@]}")

  # ask yargs to generate completions.
  type_list=\$(cdk --get-yargs-completions "\${args[@]}")

  COMPREPLY=(\$(compgen -W "\${type_list}" -- \${cur_word}))

  # if no match was found, fall back to filename completion
  if [ \${#COMPREPLY[@]} -eq 0 ]; then
    COMPREPLY=()
  fi

  return 0
}
complete -o default -F _cdk_yargs_completions cdk
EOF

# endregion
