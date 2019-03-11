#! /usr/bin/env bash

if [[ -n $(git status -s) ]]
then
  echo "$0: refusing to generate tag for a dirty working directory" >&2
  exit 1
fi

git rev-parse --verify HEAD
