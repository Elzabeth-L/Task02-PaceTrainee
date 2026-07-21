#!/usr/bin/env bash
set -Eeuo pipefail

test "$(git rev-parse HEAD)" = "${GITHUB_SHA:?GITHUB_SHA is required}"
owner="${GITHUB_REPOSITORY_OWNER:?GITHUB_REPOSITORY_OWNER is required}"
prefix="${GHCR_REPOSITORY_PREFIX:?GHCR_REPOSITORY_PREFIX is required}"
owner="${owner,,}"
prefix="${prefix,,}"
[[ "$owner" =~ ^[a-z0-9][a-z0-9.-]*$ ]] || { echo 'Invalid GHCR owner.' >&2; exit 1; }
[[ "$prefix" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || { echo 'Invalid GHCR repository prefix.' >&2; exit 1; }

echo "FRONTEND_IMAGE=ghcr.io/$owner/$prefix-frontend" >> "${GITHUB_ENV:?GITHUB_ENV is required}"
echo "BACKEND_IMAGE=ghcr.io/$owner/$prefix-backend" >> "$GITHUB_ENV"
echo "created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
echo "source=https://github.com/${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}" >> "$GITHUB_OUTPUT"
