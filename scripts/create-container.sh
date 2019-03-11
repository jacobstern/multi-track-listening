#! /usr/bin/env bash

set -o nounset
set -e

TAG=${1-$("${BASH_SOURCE%/*}/get-default-tag.sh")}
CONTAINER_NAME=${2-multi_track_listening_prod}
PROJECT_ID=${PROJECT_ID-multi-track-listening}
NAME="gcr.io/$PROJECT_ID/multi_track_listening"
IMAGE="$NAME:$TAG"

docker rm "$CONTAINER_NAME" || true
docker create --env GOOGLE_APPLICATION_CREDENTIALS=/opt/gcloud/application_default_credentials.json \
  -p 8080:8080 --name "$CONTAINER_NAME" -v ~/.config/gcloud:/opt/gcloud "$IMAGE"
