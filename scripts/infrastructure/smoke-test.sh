#!/usr/bin/env bash
set -Eeuo pipefail

url="$(terragrunt output -raw alb_http_url)"
for attempt in {1..30}; do
  if curl --fail --silent "$url/health" >/dev/null \
    && curl --fail --silent "$url/api/health" >/dev/null; then
    break
  fi
  sleep 10
done
curl --fail --silent "$url/health" | grep -q healthy
curl --fail --silent "$url/api/health" | grep -q '"status":"healthy"'

echo '### Deployment endpoint' >> "${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY is required}"
echo "$url" >> "$GITHUB_STEP_SUMMARY"
