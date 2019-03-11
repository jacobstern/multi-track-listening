#!/usr/bin/env bash

set -o nounset
set -e

echo_and_run() { echo "$@" ; "$@" ; }

TAG=${1-$("${BASH_SOURCE%/*}/get-default-tag.sh")}

echo_and_run kubectl set image deployment/web "web=gcr.io/multi-track-listening/multi_track_listening:$TAG"
