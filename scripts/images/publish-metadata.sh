#!/usr/bin/env bash
set -Eeuo pipefail

frontend_uri="${FRONTEND_IMAGE:?FRONTEND_IMAGE is required}:${GITHUB_SHA:?GITHUB_SHA is required}"
backend_uri="${BACKEND_IMAGE:?BACKEND_IMAGE is required}:$GITHUB_SHA"
docker push "$frontend_uri"
docker push "$backend_uri"

frontend_digest="$(docker buildx imagetools inspect "$frontend_uri" --format '{{json .Manifest.Digest}}' | tr -d '"')"
backend_digest="$(docker buildx imagetools inspect "$backend_uri" --format '{{json .Manifest.Digest}}' | tr -d '"')"
test -n "$frontend_digest"
test -n "$backend_digest"

jq -n \
  --arg source_sha "$GITHUB_SHA" \
  --arg frontend_image_uri "$frontend_uri" \
  --arg frontend_digest "$frontend_digest" \
  --arg backend_image_uri "$backend_uri" \
  --arg backend_digest "$backend_digest" \
  '{source_sha:$source_sha,frontend_image_uri:$frontend_image_uri,frontend_digest:$frontend_digest,backend_image_uri:$backend_image_uri,backend_digest:$backend_digest}' \
  > "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}/image-metadata.json"

{
  echo '## Immutable images published'
  echo
  echo '| Field | Value |'
  echo '|---|---|'
  echo "| Source commit | \`$GITHUB_SHA\` |"
  echo "| Frontend | \`$frontend_uri\` |"
  echo "| Frontend digest | \`$frontend_digest\` |"
  echo "| Backend | \`$backend_uri\` |"
  echo "| Backend digest | \`$backend_digest\` |"
  echo "| Built at | \`${BUILD_CREATED_AT:?BUILD_CREATED_AT is required}\` |"
  echo "| Workflow run | \`${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}\` |"
  echo
  echo 'The infrastructure workflow automatically selects this SHA when its image SHA input is blank.'
  echo
  echo '> After the first publication, an owner must configure both GHCR packages as public in GitHub package settings.'
} >> "${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY is required}"
