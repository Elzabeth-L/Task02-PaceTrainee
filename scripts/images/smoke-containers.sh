#!/usr/bin/env bash
set -Eeuo pipefail

cleanup() {
  docker rm -f smoke-frontend smoke-backend >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d --name smoke-frontend -p 8080:8080 \
  --read-only --tmpfs /tmp --tmpfs /var/cache/nginx --tmpfs /var/run \
  --cap-drop ALL "${FRONTEND_IMAGE:?FRONTEND_IMAGE is required}:${GITHUB_SHA:?GITHUB_SHA is required}"
docker run -d --name smoke-backend -p 8000:8000 \
  --read-only --tmpfs /tmp --cap-drop ALL \
  "${BACKEND_IMAGE:?BACKEND_IMAGE is required}:$GITHUB_SHA"
bash "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}/scripts/smoke-test.sh"
