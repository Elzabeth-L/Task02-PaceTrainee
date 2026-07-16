#!/usr/bin/env bash
set -Eeuo pipefail
frontend_url="${FRONTEND_URL:-http://127.0.0.1:8080}"
backend_url="${BACKEND_URL:-http://127.0.0.1:8000}"
for attempt in {1..30}; do curl --fail --silent "$frontend_url/health" >/dev/null && break; sleep 1; done
curl --fail --silent "$frontend_url/health" | grep -q healthy
for attempt in {1..30}; do curl --fail --silent "$backend_url/api/health" >/dev/null && break; sleep 1; done
curl --fail --silent "$backend_url/api/health" | grep -q '"status":"healthy"'
curl --fail --silent "$backend_url/api/ready" | grep -q '"status":"ready"'
curl --fail --silent "$backend_url/api/info" | grep -q '"service_name"'
