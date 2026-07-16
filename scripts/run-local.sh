#!/usr/bin/env bash
set -Eeuo pipefail
sha="${GIT_SHA:-$(git rev-parse HEAD)}"
owner="${GHCR_OWNER:-local}"
prefix="${GHCR_REPOSITORY_PREFIX:-platform-launchpad}"
docker network inspect platform-local >/dev/null 2>&1 || docker network create platform-local >/dev/null
docker rm -f platform-frontend platform-backend >/dev/null 2>&1 || true
docker run -d --name platform-backend --network platform-local -p 8000:8000 --read-only --tmpfs /tmp --cap-drop ALL "ghcr.io/$owner/$prefix-backend:$sha"
docker run -d --name platform-frontend --network platform-local -p 8080:8080 --read-only --tmpfs /tmp --tmpfs /var/cache/nginx --tmpfs /var/run --cap-drop ALL "ghcr.io/$owner/$prefix-frontend:$sha"
"$(dirname "$0")/smoke-test.sh"
