#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

CREDENTIALS=$(<credentials.json)
USER=$(echo "$CREDENTIALS" | jq -r ".user")
TOKEN=$(echo "$CREDENTIALS" | jq -r ".token")
CREDS="${USER}:${TOKEN}"

echo "$CREDS"

CACHED_ARTIFACT_DATA=$(<cached-artifact-data.json) || true

LATEST_ARTIFACT_DATA=$(curl \
	-H "Accept: application/vnd.github.v3+json" \
	-u "$CREDS" \
	https://api.github.com/repos/prominic/SwitchBoard-Internal-Use-Only/actions/artifacts \
	| jq ".artifacts[0]")
	
CACHED_ID=$(echo "$CACHED_ARTIFACT_DATA" | jq ".id")
LATEST_ID=$(echo "$LATEST_ARTIFACT_DATA" | jq ".id")

CACHED_DATE=$(echo "$CACHED_ARTIFACT_DATA" | jq ".updated_at")
LATEST_DATE=$(echo "$LATEST_ARTIFACT_DATA" | jq ".updated_at")

if [ "$CACHED_ID" != "$LATEST_ID" ] || [ "$CACHED_DATE" != "$LATEST_DATE" ]; then
	DOWNLOAD_URL=$(echo "$LATEST_ARTIFACT_DATA" | jq -r ".archive_download_url")
	LOCATION_URL=$(curl \
	-H "Accept: application/vnd.github.v3+json" \
	-u "$CREDS" \
	-sIXGET \
	"$DOWNLOAD_URL" \
	| grep location: \
	| awk '{print $2}')
	
	wget -nv "$LOCATION_URL" -O artifact.zip
	
    echo "$LATEST_ARTIFACT_DATA" > cached-artifact-data.json
fi