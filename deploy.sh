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

deploy()
{
    local run_id
    run_id=$1

    log_info "Requested deplyment for run: $run_id"

    local artifacts_url
    artifacts_url="$srv/repos/$user/$repo/actions/runs/$run_id/artifacts"

    local artifacts_metadata
    artifacts_metadata=$(get_body $artifacts_url 2>&1) \
        && log_info "Got artifacts metadata : $artifacts_metadata" \
        || log_error "Cannot get artifacts metadata : $artifacts_metadata"

    local artifact_metadata
    artifact_metadata=$(echo "$artifacts_metadata" | jq --join-output ".artifacts[0]") \
		&& log_info "Got artifact metadata : $artifact_metadata" \
        || log_error "Cannot get artifact metadata : $artifact_metadata"

    local artifact_id
    artifact_id=$(echo "$artifact_metadata" | jq --join-output ".id")

    log_info "Artifact id is: $artifact_id"

    local expired
    expired=$(echo "$artifact_metadata" | jq --join-output ".expired")

    if [[ $expired != "false" ]] ; then
        log_error "Artifact has expired"
        exit 1
    fi
    
    local download_url
    download_url=$(echo $artifact_metadata | jq --join-output ".archive_download_url")

    local download_headers=$(get_headers $download_url 2>&1) \
        && log_info "Got download headers" \
        || log_error "Cannot get download headers : $download_headers"

    local download_location
    download_location=$(echo "$download_headers" \
        | grep --ignore-case 'location:' \
        | awk '{print $2}')

    if [[ $download_location == "" ]] ; then
        log_error "Download location is empty"
    else
        log_info "Starting download"
    fi

    local download_result
    download_result=$(wget --quiet --output-document artifact.zip -- "$download_location" 2>&1) \
        && log_info "Artifact downloaded successfully" \
        || log_error "Cannot download artifact : $download_result"
}

log_info()
{
    local message
    message=$1

    echo "$(date "+%Y-%m-%d %T") : INFO : $message" >> $log_file
    echo "INFO : $message" <&2
}

log_error()
{
    local message
    message=$1

    echo "$(date "+%Y-%m-%d %T") : ERROR : $message" >> $log_file
    echo "ERROR : $message" <&2
    exit 1
}

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

get_headers()
{
    local url
    url=$1

    curl \
    --request GET \
    --head \
    --header "$request_header" \
    --netrc-file "$github_netrc_file" \
    --silent \
    --show-error \
    --fail \
    -- "$url"
}

if [ "$0" = "${BASH_SOURCE[0]}" ] ; then
    deploy "$@"
fi