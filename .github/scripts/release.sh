#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset
IFS=$'\t\n'

function print_link {
  local URL="${1}"
  local CHECKSUM="$(curl -s -S -L "${URL}" | sha256sum | awk '{print $1}')"
  echo "- ${URL} (SHA-256 Checksum: ${CHECKSUM})"
}

VERSION="$1"
BASE_URL="https://github.com/conduktor/builds/releases/${VERSION}"

# $(print_link "${BASE_URL}/conduktor-desktop-${VERSION}.msi")
DATE=$(date -u "+%Y-%m-%d")
NAME="$VERSION ($DATE)"

CURRENT_TAG=$(git describe --abbrev=0 --tags)
PREVIOUS_TAG=$(git describe --abbrev=0 --tags $(git describe --abbrev=0)^)
CHANGELOG=$(git log --no-merges --pretty=%s "$PREVIOUS_TAG".."$CURRENT_TAG" | grep -v "skip ci" | grep -v "skip changelog" | sed -e 's/^/- /')

# These changes WILL appear in Conduktor Desktop UI
# This should contain only text context-independent (no "Download links below" for instance)
BODY=$(cat <<-EOF
### Conduktor Desktop v${VERSION} ($DATE)

$CHANGELOG
EOF
)
# See https://github.community/t5/GitHub-Actions/set-output-Truncates-Multiline-Strings/m-p/38372#M3322
BODY="${BODY//'%'/'%25'}"
BODY="${BODY//$'\n'/'%0A'}"
BODY="${BODY//$'\r'/'%0D'}"

echo "::set-output name=name::$NAME"
echo "::set-output name=body::$BODY"
