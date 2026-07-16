#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/../app/frontend"
npm ci
npm run lint
npm run typecheck
npm test
npm run build
