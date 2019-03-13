#!/usr/bin/env bash

set -o nounset
set -e

echo_and_run() { echo "$@" ; "$@" ; }

PROJECT_ID=${PROJECT_ID-multi-track-listening}
NAME="gcr.io/$PROJECT_ID/multi_track_listening"
TAG="$1"

if ! gcloud container images list-tags "$NAME" --filter "$TAG" | grep -q "$TAG";
then
  echo "$0: requested tag is not present in repository" >&2
  exit 1
else
  echo_and_run kubectl set image deployment/web "web=gcr.io/multi-track-listening/multi_track_listening:$TAG"
fi
