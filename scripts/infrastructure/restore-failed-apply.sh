#!/usr/bin/env bash
set -Eeuo pipefail

bash "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}/scripts/infrastructure/image-parameters.sh" \
  restore "${RUNNER_TEMP:?RUNNER_TEMP is required}/plan/previous-ssm-artifact.json"
message='Apply failed. Prior SSM values were restored where safe; no automatic Terraform rollback was attempted.'
echo "::error::$message Inspect the deployment and retry apply with image SHA ${IMAGE_SHA:?IMAGE_SHA is required}."
