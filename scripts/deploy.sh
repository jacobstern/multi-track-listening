#!/usr/bin/env bash

TAG=${1-$(git rev-parse --verify HEAD)}

kubectl set image deployment/multi-track-listening \
  "multi-track-listening=gcr.io/multi-track-listening/multi_track_listening:$TAG"
