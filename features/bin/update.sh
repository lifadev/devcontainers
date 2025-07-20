#!/bin/bash

FEATURE="$1"
SCRIPTDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG=$SCRIPTDIR/../src/$FEATURE/devcontainer-feature.json
SCENARIOS=$SCRIPTDIR/../test/$FEATURE/scenarios.json

DEBUG=${DEBUG:-0}
export DEBUG

set -eu
[[ "$DEBUG" == 1 ]] && set -x

PARALLEL_OPTS=()
[[ "${DEBUG:-0}" != 1 ]] && PARALLEL_OPTS+=(--line-buffer)

TMPDIR=$(mktemp -d /tmp/update.XXXXXXXX)
mkdir -p "$TMPDIR"/{in,out,pkg}
export TMPDIR

trap 'rm -rf "$TMPDIR"' EXIT HUP INT TERM

die() {
  echo "❌ ERROR: $*" >&2
  exit 1
}
export -f die

update_image() {
  CURRENT=$(grep -Poh 'debian:[^"]+' "$SCENARIOS" | uniq)
  LATEST=$(
    curl -fLsS "https://hub.docker.com/v2/repositories/library/debian" |
      grep -Poh "\[[^\]]+\`latest\`\]" |
      sed 's/`/"/g' | jq -r '"debian:" + .[1]'
  )
  if [ "$CURRENT" != "$LATEST" ]; then
    echo "🐳 $CURRENT -> $LATEST"
    sed -i -e "s/$CURRENT/$LATEST/g" "$SCENARIOS"
  else
    echo "🐳 $CURRENT"
  fi
}

update_artifact() {
  set -eu
  [[ "$DEBUG" == 1 ]] && set -x

  local REPO="$1"
  local i="$2"
  local j="$3"
  local VERSION="$4"

  local INPUT="$TMPDIR/in/dependency.${i}.artifact.${j}.json"
  local OUTPUT="$TMPDIR/out/dependency.${i}.artifact.${j}.json"

  local ARTIFACT
  ARTIFACT=$(<"$INPUT")

  local ARCH
  ARCH=$(echo "$ARTIFACT" | jq -r '.architecture')

  local URL
  URL=$(
    jq -r \
      --arg VERSION "$VERSION" \
      '.url | gsub("\\${VERSION}"; $VERSION)' \
      <<<"$ARTIFACT"
  )

  local PACKAGE
  PACKAGE=$(mktemp "$TMPDIR/pkg/package.XXXXXXXX")
  echo "⬇  $REPO""[$ARCH]: $URL"
  curl -fLsS "$URL" -o "$PACKAGE"
  local CHECKSUM
  CHECKSUM=$(sha256sum -b "$PACKAGE" | cut -d' ' -f1)
  ARTIFACT=$(echo "$ARTIFACT" | jq --arg CHECKSUM "$CHECKSUM" '.checksum = $CHECKSUM')

  echo "$ARTIFACT" >"$OUTPUT"
  echo "🔑 $REPO""[$ARCH]: $CHECKSUM"
}
export -f update_artifact

update_dependency() {
  set -eu
  [[ "$DEBUG" == 1 ]] && set -x
  PARALLEL_OPTS=()
  [[ "$DEBUG" != 1 ]] && PARALLEL_OPTS+=(--line-buffer)

  local i="$1"

  local INPUT="$TMPDIR/in/dependency.${i}.json"
  local OUTPUT="$TMPDIR/out/dependency.${i}.json"

  local DEPENDENCY
  DEPENDENCY=$(<"$INPUT")

  local CURRENT
  CURRENT=$(echo "$DEPENDENCY" | jq -r '.version')

  local REPO
  REPO=$(echo "$DEPENDENCY" | jq -r '.repository')

  local HINT
  HINT=$(echo "$DEPENDENCY" | jq -r '.hint')

  [[ "$REPO" == github.com/* ]] || die "Unsupported repository: $REPO"
  [[ "$HINT" == tags/* || "$HINT" == releases/* ]] || die "Unsupported hint: $HINT"

  local LATEST=""
  local PAGE=1
  while [[ -z "$LATEST" ]]; do
    LATEST=$(
      gh api \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${REPO#github.com/}/${HINT%%/*}?page=$PAGE&per_page=100" 2>/dev/null ||
        die "GitHub API call failed: $REPO"
    ) || die "Failed to retrieve ${HINT%%/*} from GitHub"
    LATEST=$(
      echo "$LATEST" |
        jq -r '.[].name' |
        grep -E "^${HINT#*/}$" |
        sed 's/^[^0-9]*//' |
        sort -rV |
        head -1
    )
    ((PAGE++))
  done

  if dpkg --compare-versions "$LATEST" le "$CURRENT"; then
    echo "✅ $REPO: $LATEST"
    echo "$DEPENDENCY" >"$OUTPUT"
    return
  fi

  echo "🔄 $REPO: $CURRENT -> $LATEST"
  DEPENDENCY=$(echo "$DEPENDENCY" | jq --arg VERSION "$LATEST" '.version = $VERSION')

  if echo "$DEPENDENCY" | jq -e 'has("artifacts")' >/dev/null; then
    j=0
    INDEX=$TMPDIR/dependency.${i}.artifacts
    while read -r ART; do
      echo "$ART" >"$TMPDIR/in/dependency.${i}.artifact.${j}.json"
      echo "$j"
      j=$((j + 1))
    done < <(echo "$DEPENDENCY" | jq -c '.artifacts[]') >"$INDEX"
    parallel \
      "${PARALLEL_OPTS[@]}" \
      --halt now,fail=1 \
      --jobs "$(nproc)" \
      update_artifact ::: "$REPO" ::: "${i}" ::: "$(<"$INDEX")" ::: "$LATEST"
    mapfile -t ARTIFACT_PARTS < <(
      find "$TMPDIR/out" \
        -name "dependency.${i}.artifact.*.json" |
        sort -V
    )
    ARTIFACTS=$(jq -s '.' "${ARTIFACT_PARTS[@]}")

    DEPENDENCY=$(
      jq -n \
        --argjson DEPENDENCY "$DEPENDENCY" \
        --argjson ARTIFACTS "$ARTIFACTS" \
        '$DEPENDENCY | .artifacts = $ARTIFACTS'
    )
  fi

  echo "$DEPENDENCY" >"$OUTPUT"
  echo "✅ $REPO: $LATEST"
}
export -f update_dependency

update_image

i=0
INDEX=$TMPDIR/dependencies
while read -r DEPENDENCY; do
  echo "$DEPENDENCY" >"$TMPDIR/in/dependency.${i}.json"
  echo "$i"
  i=$((i + 1))
done < <(jq -c '(.customizations.manifest.dependencies // [])[]' "$CONFIG") >"$INDEX"
[[ -s "$INDEX" ]] || exit 0

parallel \
  "${PARALLEL_OPTS[@]}" \
  --halt now,fail=1 \
  --jobs "$(nproc)" \
  update_dependency :::: "$INDEX"
mapfile -t DEPENDENCY_PARTS < <(
  find "$TMPDIR/out" \
    -regextype posix-extended \
    -regex '.*/dependency.[0-9]+.json' |
    sort -V
)
DEPENDENCIES=$(jq -s '.' "${DEPENDENCY_PARTS[@]}")

UPDATED=$(
  jq -n \
    --argjson PREV "$(jq '.customizations.manifest.dependencies' "$CONFIG")" \
    --argjson NEW "$DEPENDENCIES" \
    '$PREV != $NEW'
)

VERSION=$(jq -r '.version' "$CONFIG")
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
  --argjson DEPENDENCIES "$DEPENDENCIES" \
  '.version = $VERSION | .customizations.manifest.dependencies = $DEPENDENCIES' \
  "$CONFIG" | sponge "$CONFIG"
