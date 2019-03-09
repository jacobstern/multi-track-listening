#!/usr/bin/env bash

set -o nounset
set -o errexit

PROJECT_ID=${PROJECT_ID-multi-track-listening}

TAG="$(git rev-parse --verify HEAD)"
NAME="gcr.io/$PROJECT_ID/multi_track_listening"
IMAGE="$NAME:$TAG"

docker build \
  -f "apps/multi_track_listening/Dockerfile" \
  -t "$IMAGE" \
  --build-arg "project_id=$PROJECT_ID" \
  .

docker tag "$IMAGE" "$NAME:latest"

docker push "gcr.io/$PROJECT_ID/multi_track_listening:$TAG"
