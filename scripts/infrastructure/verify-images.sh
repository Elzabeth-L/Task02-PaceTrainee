#!/usr/bin/env bash
set -Eeuo pipefail

owner="${GHCR_OWNER:?GHCR_OWNER is required}"
prefix="${GHCR_REPOSITORY_PREFIX:?GHCR_REPOSITORY_PREFIX is required}"
owner="${owner,,}"
prefix="${prefix,,}"
for service in frontend backend; do
  docker manifest inspect "ghcr.io/$owner/$prefix-$service:${IMAGE_SHA:?IMAGE_SHA is required}" >/dev/null
done
