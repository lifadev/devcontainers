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

PREV_SUM=$(cat "$CONFIG" "$LOCK" | md5sum)

IMAGE=$(
  curl -fLsS "https://hub.docker.com/v2/repositories/library/debian" |
    grep -Poh "\[[^\]]+\`latest\`\]" |
    sed 's/`/"/g' | jq -r '"debian:" + .[1]'
)
jq \
  --arg IMAGE "$IMAGE" \
  '.image = $IMAGE' \
  "$CONFIG" | sponge "$CONFIG"

rm -f "$LOCK"
npx -y @devcontainers/cli upgrade --workspace-folder "$WORKSPACE"
npx -y prettier -w "$WORKSPACE"

NEW_SUM=$(cat "$CONFIG" "$LOCK" | md5sum)

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
