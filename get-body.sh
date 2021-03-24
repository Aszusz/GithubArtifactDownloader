#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

readonly progdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
readonly github_netrc_file="$progdir/github.netrc"
readonly log_file="$progdir/log.txt"

readonly srv="https://api.github.com"
readonly user="prominic"
readonly repo="SwitchBoard-Internal-Use-Only"

readonly request_header="Accept: application/vnd.github.v3+json"

get_body()
{
    local url
    url=$1

    curl \
    --request GET \
    --header "$request_header" \
    --netrc-file "$github_netrc_file" \
    --silent \
    --show-error \
    --fail \
    -- "$url" \
    | jq --raw-output
}

if [ "$0" = "${BASH_SOURCE[0]}" ] ; then
    get_body "$@"
fi