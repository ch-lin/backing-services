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

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# Default to .env if no argument is provided
export TARGET_ENV=${1:-.env}

# Shift past the first argument to capture any specific services provided
if [ $# -gt 0 ]; then
    shift
fi

TARGET_SERVICES="$@"

build_all() {
  echo "Starting Shared Backing Services (${TARGET_SERVICES:-all}) using docker-compose..."
  echo "Using environment file selection: ${TARGET_ENV}"
  
  # Ensure the shared network exists to avoid network not found errors during isolated startup
  docker network inspect shared-services-network >/dev/null 2>&1 || docker network create shared-services-network

  if [ -z "${TARGET_SERVICES}" ]; then
    docker compose -p backing-object-storage -f ./object-storage/docker-compose.yml --env-file ./object-storage/${TARGET_ENV} up -d --wait
    docker compose -p backing-central-logging -f ./central-logging/docker-compose.yml --env-file ./central-logging/${TARGET_ENV} up -d --wait
  else
    # Route target services to prevent passing non-existent services to docker compose, avoiding errors
    OBJ_SVCS=""
    LOG_SVCS=""
    for svc in ${TARGET_SERVICES}; do
      case "${svc}" in
        s3|s3-setup|s3-proxy) OBJ_SVCS="${OBJ_SVCS} ${svc}" ;;
        logging-db|database)  LOG_SVCS="${LOG_SVCS} ${svc}" ;;
        *) OBJ_SVCS="${OBJ_SVCS} ${svc}"; LOG_SVCS="${LOG_SVCS} ${svc}" ;;
      esac
    done

    if [ -n "${OBJ_SVCS}" ]; then
      docker compose -p backing-object-storage -f ./object-storage/docker-compose.yml --env-file ./object-storage/${TARGET_ENV} up -d --wait ${OBJ_SVCS}
    fi
    if [ -n "${LOG_SVCS}" ]; then
      docker compose -p backing-central-logging -f ./central-logging/docker-compose.yml --env-file ./central-logging/${TARGET_ENV} up -d --wait ${LOG_SVCS}
    fi
  fi
  echo "Starting Shared Backing Services...done!"
}

build_all
exit 0
