#!/bin/bash

set -eux

if [ "$UID" -ne 0 ]; then
  echo -e "(!) User must be root: $UID"
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != 'amd64' ] && [ "$ARCH" != 'arm64' ]; then
  echo "(!) Unsupported architecture: $ARCH"
  exit 1
fi

#---

#? https://www.npmjs.com/package/cdk?activeTab=versions
npm install -g cdk@2.1001.0

#---

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
