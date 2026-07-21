#!/usr/bin/env bash
set -Eeuo pipefail

operation="${OPERATION:?OPERATION is required}"
account="${ACCOUNT_ALIAS:?ACCOUNT_ALIAS is required}"
summary="${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY is required}"

if [[ "$operation" == destroy-complete ]]; then
  echo "## Destroy complete - $account" >> "$summary"
  echo 'Shared S3 state infrastructure and GHCR images were preserved.' >> "$summary"
  exit 0
fi

{
  echo "## $operation plan - $account"
  echo
  echo "- Commit: \`${GITHUB_SHA:?GITHUB_SHA is required}\`"
  echo "- Expected account: \`${TG_AWS_ACCOUNT_ID:?TG_AWS_ACCOUNT_ID is required}\`"
  echo "- Region: \`${TG_AWS_REGION:?TG_AWS_REGION is required}\`"
  echo "- Binary SHA-256: \`$(cut -d' ' -f1 "$RUNNER_TEMP/reviewed.tfplan.sha256")\`"
  if [[ "$operation" == apply ]]; then
    echo "- Image SHA: \`${IMAGE_SHA:?IMAGE_SHA is required}\`"
  fi
  if [[ "$operation" == plan ]]; then
    echo '- No infrastructure or SSM mutation was performed.'
  else
    echo '- Execution starts automatically after the exact plan artifact is created.'
  fi
} >> "$summary"
