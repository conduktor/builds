#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset
IFS=$'\t\n'

API=${1?"Missing API key"}
VERSION=${2?"Missing version"}
UPDATE_ONLY=true

if $UPDATE_ONLY; then

	echo "Updating links to v$VERSION"

	SYSTEM=macOS
	
	EXTENSION=dmg
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/85cf14f89f2b4d5ea73cfc131ce7cba5' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=pkg
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/356b5a43bca647838d1f43b9e1fb4d01' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=zip
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/d6c7f5b314c049f680766d798c459368' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${SYSTEM}-${VERSION}.${EXTENSION}\"}"

	#

	SYSTEM=win
	
	EXTENSION=exe
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/10e985a741c241918e8f2451aee5fb01' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=msi
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/c3e4aef5563e4639bbfe757ad03eb0f0' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=zip
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/0253c50edbc94ed2a1d239d0bb31c9d5' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${SYSTEM}-${VERSION}.${EXTENSION}\"}"

	#

	SYSTEM=linux
	
	EXTENSION=deb
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/08eae4e53dfd410c825547e7368a0e7d' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=rpm
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/ffbd42109e1f48cea3f2d79c79594838' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=zip
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links/b530f90d0fef4ef6a2ad3ac943b2605d' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${SYSTEM}-${VERSION}.${EXTENSION}\"}"

else

	echo "Creating links to v$VERSION"

	SYSTEM=macOS
	
	EXTENSION=dmg
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=pkg
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=zip
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${SYSTEM}-${VERSION}.${EXTENSION}\"}"

	#

	SYSTEM=win
	
	EXTENSION=exe
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=msi
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=zip
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${SYSTEM}-${VERSION}.${EXTENSION}\"}"

	#

	SYSTEM=linux
	
	EXTENSION=deb
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=rpm
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${VERSION}.${EXTENSION}\"}"

	EXTENSION=zip
	curl -sSf -o /dev/null 'https://api.rebrandly.com/v1/links' -XPOST -H "apikey: $API" -H 'Content-Type: application/json' -d"{\"title\": \"Conduktor ${SYSTEM} .${EXTENSION}\", \"domain\":{ \"fullName\": \"releases.conduktor.io\"}, \"slashtag\": \"${SYSTEM}-${EXTENSION}\", \"destination\": \"https://github.com/conduktor/builds/releases/download/v${VERSION}/Conduktor-${SYSTEM}-${VERSION}.${EXTENSION}\"}"

fi
