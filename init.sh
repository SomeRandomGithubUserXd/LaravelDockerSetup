#!/bin/sh
set -e
docker build -q -t project-setup ./setup > /dev/null
docker run --rm -it \
  -v "$PWD":/project \
  -u "$(id -u):$(id -g)" \
  project-setup