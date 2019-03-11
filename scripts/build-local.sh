#!/usr/bin/env bash

set -o nounset
set -e

PROJECT_ID=${PROJECT_ID-multi-track-listening}

TAG=${1-$("${BASH_SOURCE%/*}/get-default-tag.sh")}
NAME="gcr.io/$PROJECT_ID/multi_track_listening"
IMAGE="$NAME:$TAG"

docker build \
  -f "apps/multi_track_listening/Dockerfile" \
  -t "$IMAGE" \
  -t "$NAME:latest" \
  --build-arg "project_id=$PROJECT_ID" \
  .
