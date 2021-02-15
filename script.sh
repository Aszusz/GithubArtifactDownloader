#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

CREDENTIALS_FILE=$"credentials.json" 	# Required
METADATA_FILE=$"metadata.json"			# Optional

main() {
	CREDENTIALS=$(load_credentials)
	echo "Loaded credentials."
	
	CACHED_METADATA=$(load_metadata)
	if [[ -z "$CACHED_METADATA" ]]; then
		echo "No cached metadata."
	else
		echo "Loaded metadata form cache."
	fi
	
	LATEST_METADATA=$(download_metadata "$CREDENTIALS")
	
	if [[ "$CACHED_METADATA" == "$LATEST_METADATA" ]]; then
		echo "Cached metadata is up to date, nothing to do."
	else		
		echo "Cached metadata is old or empty, downloading new artifact."
		LOCATION_URL=$(get_location_url "$LATEST_METADATA" "$CREDENTIALS")
		download_artifact "$LOCATION_URL"	
		echo "Artifact downloaded."
		
		echo "$LATEST_METADATA" > "$METADATA_FILE"
		echo "Cached latest metadata on disk."
	fi	
}

load_credentials () {
	CONTENT=$(cat "$CREDENTIALS_FILE")

	USER=$(echo "$CONTENT" | jq -r ".user")
	if [[ "$USER" == null ]]; then
		echo "Error: No user." >&2
		exit 1
	fi

	TOKEN=$(echo "$CONTENT" | jq -r ".token")
	if [[ "$TOKEN" == null ]]; then
		echo "Error: No token." >&2
		exit 1
	fi

	echo "$USER":"$TOKEN"
}

load_metadata() {
	CONTENT=$(cat "$METADATA_FILE" || true)
	echo "$CONTENT"
}

download_metadata () { 
	HEADER=$"Accept: application/vnd.github.v3+json"
	CREDENTIALS="$1"
	URL="https://api.github.com/repos/prominic/SwitchBoard-Internal-Use-Only/actions/artifacts"	
	METADATA=$(curl -H "$HEADER" -u "$CREDENTIALS" "$URL" -s | jq ".artifacts[0]")
	echo "$METADATA"
}

get_location_url () {
	METADATA="$1"
	CREDENTIALS="$2"	
	HEADER=$"Accept: application/vnd.github.v3+json"	
	DOWNLOAD_URL=$(echo "$METADATA" | jq -r ".archive_download_url")
	RESPONSE_HEADER=$(curl -H "$HEADER" -u "$CREDENTIALS" -sIXGET "$DOWNLOAD_URL")
	LOCATION_PART=$(echo "$RESPONSE_HEADER" | grep 'Location:')
	LOCATION_URL=$(echo "$LOCATION_PART" | awk '{print $2}')
	echo "$LOCATION_URL"
}

download_artifact () {
	LOCATION_URL="$1"
	wget -q --show-progress --progress=bar:force:noscroll "$LOCATION_URL" -O artifact.zip
}

main "$@"; exit
