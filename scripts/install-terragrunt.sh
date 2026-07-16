#!/usr/bin/env bash
set -Eeuo pipefail

version="${1:?Terragrunt version is required}"
destination="${2:?Destination path is required}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid Terragrunt version: $version" >&2
  exit 1
fi

release_url="https://github.com/gruntwork-io/terragrunt/releases/download/v${version}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

curl --fail --silent --show-error --location \
  "$release_url/terragrunt_linux_amd64" \
  --output "$work_dir/terragrunt_linux_amd64"
curl --fail --silent --show-error --location \
  "$release_url/SHA256SUMS" \
  --output "$work_dir/SHA256SUMS"

grep -E '[[:space:]]+terragrunt_linux_amd64$' "$work_dir/SHA256SUMS" \
  > "$work_dir/terragrunt.sha256"
(cd "$work_dir" && sha256sum --check --strict terragrunt.sha256)

install -m 0755 "$work_dir/terragrunt_linux_amd64" "$destination"
