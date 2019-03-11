#!/usr/bin/env bash

set -o nounset
set -e

TAG=$("${BASH_SOURCE%/*}/get-default-tag.sh")

gcloud builds submit "--substitutions=_TAG=$TAG" .