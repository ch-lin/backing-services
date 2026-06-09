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

# Capture environment file if passed as first argument, otherwise use env var or default to .env
if [ $# -gt 0 ] && [[ "$1" == *.env ]]; then
    export TARGET_ENV="$1"
    shift
else
    export TARGET_ENV="${TARGET_ENV:-.env}"
fi

TARGET_SERVICES="$@"

clean_all() {
  echo "Stopping and removing all Shared Backing Services containers and networks..."
  
  # Tear down each isolated backing service project independently.
  docker compose -p backing-object-storage -f ./object-storage/docker-compose.yml --env-file ./object-storage/${TARGET_ENV} down --remove-orphans || true
  docker compose -p backing-central-logging -f ./central-logging/docker-compose.yml --env-file ./central-logging/${TARGET_ENV} down --remove-orphans || true

  echo "Removing all Backing Services Docker images..."
  docker image rm chrislusf/seaweedfs:latest amazon/aws-cli:latest nginx:alpine mysql:8.0 2>/dev/null || true
  echo "Clean all complete!"
}

clean_specific() {
  echo "Stopping and removing specific Shared Backing Services (${TARGET_SERVICES})..."
  
  # Route target services to precisely stop the corresponding containers
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
    docker compose -p backing-object-storage -f ./object-storage/docker-compose.yml --env-file ./object-storage/${TARGET_ENV} stop ${OBJ_SVCS}
    docker compose -p backing-object-storage -f ./object-storage/docker-compose.yml --env-file ./object-storage/${TARGET_ENV} rm -f ${OBJ_SVCS}
  fi
  if [ -n "${LOG_SVCS}" ]; then
    docker compose -p backing-central-logging -f ./central-logging/docker-compose.yml --env-file ./central-logging/${TARGET_ENV} stop ${LOG_SVCS}
    docker compose -p backing-central-logging -f ./central-logging/docker-compose.yml --env-file ./central-logging/${TARGET_ENV} rm -f ${LOG_SVCS}
  fi

  echo "Removing specific Docker images..."
  for svc in ${TARGET_SERVICES}; do
    if [[ "${svc}" == "s3" ]]; then docker image rm chrislusf/seaweedfs:latest 2>/dev/null || true; fi
    if [[ "${svc}" == "s3-setup" ]]; then docker image rm amazon/aws-cli:latest 2>/dev/null || true; fi
    if [[ "${svc}" == "s3-proxy" ]]; then docker image rm nginx:alpine 2>/dev/null || true; fi
    if [[ "${svc}" == "logging-db" ]]; then docker image rm mysql:8.0 2>/dev/null || true; fi
  done
  echo "Clean specific complete!"
}

if [ -z "${TARGET_SERVICES}" ] || [[ "${TARGET_SERVICES}" == *"all"* ]]; then
  clean_all
else
  clean_specific
fi

exit 0
