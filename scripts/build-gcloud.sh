#!/usr/bin/env bash

gcloud builds submit --substitutions="_TAG=$(git rev-parse --verify HEAD)" .
