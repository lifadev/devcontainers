#!/bin/bash

IMAGE="$1"
SCRIPTDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKSPACE=$SCRIPTDIR/../src/$IMAGE
CONFIG=$WORKSPACE/.devcontainer/devcontainer.json
LOCK=$WORKSPACE/.devcontainer/devcontainer-lock.json

DEBUG=${DEBUG:-0}
export DEBUG

set -eu
[[ "$DEBUG" == 1 ]] && set -x

PREV_SUM=$(md5sum "$LOCK")

rm -f "$LOCK"
npx -y @devcontainers/cli upgrade --workspace-folder "$WORKSPACE"
npx -y prettier -w "$WORKSPACE"

NEW_SUM=$(md5sum "$LOCK")

UPDATED=$(
  jq -n \
    --arg PREV "$PREV_SUM" \
    --arg NEW "$NEW_SUM" \
    '$PREV != $NEW'
)

VERSION=$(jq -r '.customizations.manifest.version' "$CONFIG")

if [[ $UPDATED == "true" ]]; then
  NEXT=$(date "+%Y.%-m.%-d")
  IFS='-' read -r BASE SUFFIX <<<"$VERSION"
  SUFFIX="${SUFFIX:-0}"
  if [[ $BASE == "$NEXT" ]]; then
    VERSION="${BASE}-$((SUFFIX + 1))"
  else
    VERSION=$NEXT
  fi
fi

jq \
  --arg VERSION "$VERSION" \
  '.customizations.manifest.version = $VERSION' \
  "$CONFIG" | sponge "$CONFIG"
