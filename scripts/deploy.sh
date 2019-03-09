#!/usr/bin/env bash

TAG=${1-$(git rev-parse --verify HEAD)}

kubectl set image deployment/web "web=gcr.io/multi-track-listening/multi_track_listening:$TAG"
