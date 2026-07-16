#!/usr/bin/env bash
set -Eeuo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
"$root/scripts/frontend-test.sh"
"$root/scripts/backend-test.sh"
terraform fmt -check -recursive "$root/infra"
tflint --recursive --chdir "$root/infra/modules/ecs-fargate-webapp"
checkov --directory "$root/infra" --framework terraform
trivy config --exit-code 1 --severity HIGH,CRITICAL "$root/infra"
hadolint "$root/app/frontend/Dockerfile" "$root/app/backend/Dockerfile"
find "$root" -name '*.json' -not -path '*/node_modules/*' -print0 | xargs -0 -n1 jq empty
find "$root/docs/diagrams" -name '*.svg' -print0 | xargs -0 -n1 xmllint --noout
actionlint
shellcheck "$root"/scripts/*.sh
yamllint "$root/.github"
markdownlint "$root/README.md" "$root/docs" "$root/app" --ignore '**/node_modules/**'
