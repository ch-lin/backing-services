#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2025 Che-Hung Lin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Service and Image Definitions
SVC_S3="seaweedfs"
SVC_SETUP="seaweedfs-setup"
IMG_S3="chrislusf/seaweedfs:latest"
IMG_SETUP="amazon/aws-cli:latest"

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

clean_s3() {
  echo "Stopping and removing S3 containers..."
  docker-compose stop ${SVC_S3} ${SVC_SETUP} 2>/dev/null || true
  docker-compose rm -f ${SVC_S3} ${SVC_SETUP} 2>/dev/null || true
  echo "Removing S3 images..."
  docker image rm ${IMG_S3} 2>/dev/null || true
  docker image rm ${IMG_SETUP} 2>/dev/null || true
}

clean_all() {
  echo "Stopping and removing Docker containers and networks..."
  # Use docker-compose down to stop and remove containers and networks.
  # The --remove-orphans flag cleans up any containers not defined in the compose file.
  docker-compose down --remove-orphans || true
  echo "Stopping and removing Docker containers and networks...done!"

  echo "Removing Docker images..."
  docker image rm ${IMG_S3} 2>/dev/null || true
  docker image rm ${IMG_SETUP} 2>/dev/null || true
  echo "Removing Docker images...done!"
}

if [ $# -eq 0 ]; then
  set -- "all"
fi

DO_ALL=false
DO_S3=false

for arg in "$@"; do
  case "${arg}" in
    s3) DO_S3=true ;;
    all) DO_ALL=true ;;
    help)
      echo "Usage: $0 {s3|all|help} [more args...]"
      exit 0
      ;;
    *)
      echo "Unknown argument: ${arg}"
      echo "Usage: $0 {s3|all|help} [more args...]"
      exit 1
      ;;
  esac
done

if [[ "${DO_ALL}" == "true" ]]; then
  clean_all
elif [[ "${DO_S3}" == "true" ]]; then
  clean_s3
fi

exit 0
