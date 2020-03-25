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
EOF
)

# $(print_link "${BASE_URL}/conduktor-desktop-${VERSION}.msi")
NAME="$VERSION ($(date -u "+%Y-%m-%d"))"

echo "::set-output name=name::$NAME"
echo "::set-output name=body::$BODY"

