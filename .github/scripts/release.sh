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

BODY=$(cat <<-EOF
### Conduktor Desktop v${VERSION}
The download links can be found below.

Changes:

- foo
- bar
EOF
)

# See https://github.community/t5/GitHub-Actions/set-output-Truncates-Multiline-Strings/m-p/38372#M3322
BODY="${BODY//'%'/'%25'}"
BODY="${BODY//$'\n'/'%0A'}"
BODY="${BODY//$'\r'/'%0D'}"

# $(print_link "${BASE_URL}/conduktor-desktop-${VERSION}.msi")
NAME="$VERSION ($(date -u "+%Y-%m-%d"))"

echo "::set-output name=name::$NAME"
echo "::set-output name=body::$BODY"

CURRENT_TAG=$(git describe --abbrev=0)
PREVIOUS_TAG=$(git describe --abbrev=0 --tags $(git describe --abbrev=0)^)
CHANGELOG=$(git log --pretty=%s $PREVIOUS_TAG..$CURRENT_TAG)
