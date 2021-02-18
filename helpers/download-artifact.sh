#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

# Parameters:
USER="$1"
REPO="$2"
ARTIFACT_ID="$3"

# Imports:
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GET_HEADER=$"${DIR}/get-header.sh"

# Constants:
SRV="https://api.github.com"

# Script:
DOWNLOAD_URL=$"${SRV}/repos/${USER}/${REPO}/actions/artifacts/${ARTIFACT_ID}/zip"
HEADER=$("$GET_HEADER" "$DOWNLOAD_URL")
LOCATION=$(echo "$HEADER" | grep -i "location:" | awk '{print $2}')
wget "$LOCATION" -O artifact.zip