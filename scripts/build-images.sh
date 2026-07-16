#!/usr/bin/env bash
set -Eeuo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
sha="${GIT_SHA:-$(git -C "$root" rev-parse HEAD)}"
date="${BUILD_DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
source_url="${SOURCE_URL:-https://github.com/OWNER/REPOSITORY}"
version="${APP_VERSION:-1.0.0}"
owner="${GHCR_OWNER:-local}"
prefix="${GHCR_REPOSITORY_PREFIX:-platform-launchpad}"
docker build --build-arg GIT_SHA="$sha" --build-arg BUILD_DATE="$date" --build-arg SOURCE_URL="$source_url" --build-arg APP_VERSION="$version" -t "ghcr.io/$owner/$prefix-frontend:$sha" "$root/app/frontend"
docker build --build-arg GIT_SHA="$sha" --build-arg BUILD_DATE="$date" --build-arg SOURCE_URL="$source_url" --build-arg APP_VERSION="$version" -t "ghcr.io/$owner/$prefix-backend:$sha" "$root/app/backend"
