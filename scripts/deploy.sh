#!/usr/bin/env bash

set -o nounset
set -e

TAG=${1-$("${BASH_SOURCE%/*}/get-default-tag.sh")}

kubectl set image deployment/web "web=gcr.io/multi-track-listening/multi_track_listening:$TAG"
