#!/usr/bin/env bash

TAG=${1-$(git rev-parse --verify HEAD)}

gcloud builds submit --substitutions="_TAG=$TAG" .
