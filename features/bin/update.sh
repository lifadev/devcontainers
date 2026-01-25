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
  local current
  current=$(grep -Poh 'debian:[^"]+' "$SCENARIOS" | uniq)

  local latest
  latest=$(
    curl --proto "=https" --tlsv1.2 -fLsS "https://hub.docker.com/v2/repositories/library/debian" |
      grep -Poh "\[[^\]]+\`latest\`\]" |
      sed 's/`/"/g' | jq -r '"debian:" + .[1]'
  )
  if [[ "$current" != "$latest" ]]; then
    echo "🐳 $current -> $latest"
    sed -i -e "s/$current/$latest/g" "$SCENARIOS"
  else
    echo "🐳 $current"
  fi

  return 0
}

update_artifact() {
  set -eu
  [[ "$DEBUG" == 1 ]] && set -x

  local repo="$1"
  local i="$2"
  local j="$3"
  local version="$4"

  local input="$TMPDIR/in/dependency.${i}.artifact.${j}.json"
  local output="$TMPDIR/out/dependency.${i}.artifact.${j}.json"

  local artifact
  artifact=$(<"$input")

  local arch
  arch=$(echo "$artifact" | jq -r '.architecture')

  local url
  url=$(
    jq -r \
      --arg VERSION "$version" \
      '.url | gsub("\\${VERSION}"; $VERSION)' \
      <<<"$artifact"
  )

  local package
  package=$(mktemp "$TMPDIR/pkg/package.XXXXXXXX")
  echo "⬇  $repo""[$arch]: $url"
  curl --proto "=https" --tlsv1.2 -fLsS "$url" -o "$package"

  local checksum
  checksum=$(sha256sum -b "$package" | cut -d' ' -f1)
  artifact=$(echo "$artifact" | jq --arg CHECKSUM "$checksum" '.checksum = $CHECKSUM')

  echo "$artifact" >"$output"
  echo "🔑 $repo""[$arch]: $checksum"

  return 0
}
export -f update_artifact

update_dependency() {
  set -eu
  [[ "$DEBUG" == 1 ]] && set -x
  PARALLEL_OPTS=()
  [[ "$DEBUG" != 1 ]] && PARALLEL_OPTS+=(--line-buffer)

  local i="$1"

  local input="$TMPDIR/in/dependency.${i}.json"
  local output="$TMPDIR/out/dependency.${i}.json"

  local dependency
  dependency=$(<"$input")

  local current
  current=$(echo "$dependency" | jq -r '.version')

  local repo
  repo=$(echo "$dependency" | jq -r '.repository')

  local hint
  hint=$(echo "$dependency" | jq -r '.hint')

  [[ "$repo" == github.com/* ]] || die "Unsupported repository: $repo"
  [[ "$hint" == tags/* || "$hint" == releases/* ]] || die "Unsupported hint: $hint"

  local latest=""
  local page=1
  while [[ -z "$latest" ]]; do
    latest=$(
      gh api \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${repo#github.com/}/${hint%%/*}?page=$page&per_page=100" 2>/dev/null ||
        die "GitHub API call failed: $repo"
    ) || die "Failed to retrieve ${hint%%/*} from GitHub"
    latest=$(
      echo "$latest" |
        jq -r '.[].name' |
        grep -E "^${hint#*/}$" |
        sed 's/^[^0-9]*//' |
        sort -rV |
        head -1
    )
    ((page++))
  done

  if dpkg --compare-versions "$latest" le "$current"; then
    echo "✅ $repo: $latest"
    echo "$dependency" >"$output"
    return 0
  fi

  echo "🔄 $repo: $current -> $latest"
  dependency=$(echo "$dependency" | jq --arg VERSION "$latest" '.version = $VERSION')

  if echo "$dependency" | jq -e 'has("artifacts")' >/dev/null; then
    j=0
    INDEX=$TMPDIR/dependency.${i}.artifacts
    while read -r ART; do
      echo "$ART" >"$TMPDIR/in/dependency.${i}.artifact.${j}.json"
      echo "$j"
      j=$((j + 1))
    done < <(echo "$dependency" | jq -c '.artifacts[]') >"$INDEX"
    parallel \
      "${PARALLEL_OPTS[@]}" \
      --halt now,fail=1 \
      --jobs "$(nproc)" \
      update_artifact ::: "$repo" ::: "${i}" ::: "$(<"$INDEX")" ::: "$latest"
    mapfile -t ARTIFACT_PARTS < <(
      find "$TMPDIR/out" \
        -name "dependency.${i}.artifact.*.json" |
        sort -V
    )
    ARTIFACTS=$(jq -s '.' "${ARTIFACT_PARTS[@]}")

    dependency=$(
      jq -n \
        --argjson DEPENDENCY "$dependency" \
        --argjson ARTIFACTS "$ARTIFACTS" \
        '$DEPENDENCY | .artifacts = $ARTIFACTS'
    )
  fi

  echo "$dependency" >"$output"
  echo "✅ $repo: $latest"

  return 0
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
