#!/usr/bin/env bash

set -o nounset
set -o errexit

if [ -z ${PROJECT_ID+x} ]; then
  PROJECT_ID="multi-track-listening";
fi

TAG=${1-x}

if [ -z "$TAG" ]; then
  docker push "gcr.io/$PROJECT_ID/multi_track_listening";
else
  docker push "gcr.io/$PROJECT_ID/multi_track_listening:$TAG";
fi
