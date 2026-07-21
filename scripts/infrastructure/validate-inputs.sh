#!/usr/bin/env bash
set -Eeuo pipefail

operation="${OPERATION:?OPERATION is required}"
target="${TARGET_ACCOUNT:?TARGET_ACCOUNT is required}"
image_sha="${IMAGE_SHA:-}"
confirmation="${DESTROY_CONFIRMATION:-}"

case "$operation" in
  plan|apply|destroy) ;;
  *) echo "Unsupported operation: $operation" >&2; exit 1 ;;
esac
case "$target" in
  account-1|account-2|account-3|all) ;;
  *) echo "Unsupported target account: $target" >&2; exit 1 ;;
esac

if [[ "$operation" == apply ]]; then
  if [[ -z "$image_sha" ]]; then
    response="$(curl --fail-with-body --silent --show-error \
      --header "Authorization: Bearer ${GH_TOKEN:?GH_TOKEN is required}" \
      --header 'Accept: application/vnd.github+json' \
      --header 'X-GitHub-Api-Version: 2022-11-28' \
      "https://api.github.com/repos/${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}/actions/workflows/build-images.yml/runs?branch=main&status=success&per_page=1")"
    image_sha="$(jq -r '.workflow_runs[0].head_sha // empty' <<<"$response")"
    [[ -n "$image_sha" ]] || { echo 'No successful main image build was found.' >&2; exit 1; }
    echo "Automatically selected latest successful image build: $image_sha"
  else
    echo "Using explicitly requested image build: $image_sha"
  fi
  [[ "$image_sha" =~ ^[0-9a-f]{40}$ ]] || {
    echo 'Resolved image SHA must be a lowercase full 40-character Git SHA.' >&2
    exit 1
  }
fi

if [[ "$operation" == destroy && "$confirmation" != "DESTROY $target" ]]; then
  echo "Destroy confirmation must be exactly: DESTROY $target" >&2
  exit 1
fi

echo "image_sha=$image_sha" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
if [[ "$target" == all ]]; then
  echo 'accounts=["account-1","account-2","account-3"]' >> "$GITHUB_OUTPUT"
else
  echo "accounts=[\"$target\"]" >> "$GITHUB_OUTPUT"
fi
