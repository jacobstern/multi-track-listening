#!/usr/bin/env bash

set -o nounset
set -o errexit

if [ -z ${PROJECT_ID+x} ]; then
  PROJECT_ID="multi-track-listening";
fi

if [ -z ${TAG+x} ]; then
  TAG="$(git rev-parse --verify HEAD)";
fi

NAME="gcr.io/$PROJECT_ID/multi_track_listening"
IMAGE="$NAME:$TAG"

docker build \
  -f "apps/multi_track_listening/Dockerfile" \
  -t "$IMAGE" \
  --build-arg "project_id=$PROJECT_ID" \
  .

docker tag "$IMAGE" "$NAME:latest"
