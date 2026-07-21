#!/usr/bin/env bash
set -Eeuo pipefail

target="${TARGET_ACCOUNT:?TARGET_ACCOUNT is required}"
case "$target" in
  account-1)
    account_id="${AWS_ACCOUNT_ID_ACCOUNT_1:-}"
    role="${AWS_ROLE_ARN_ACCOUNT_1:-}"
    region="${AWS_REGION_ACCOUNT_1:-}"
    ;;
  account-2)
    account_id="${AWS_ACCOUNT_ID_ACCOUNT_2:-}"
    role="${AWS_ROLE_ARN_ACCOUNT_2:-}"
    region="${AWS_REGION_ACCOUNT_2:-}"
    ;;
  account-3)
    account_id="${AWS_ACCOUNT_ID_ACCOUNT_3:-}"
    role="${AWS_ROLE_ARN_ACCOUNT_3:-}"
    region="${AWS_REGION_ACCOUNT_3:-}"
    ;;
  *) echo "Unsupported account alias: $target" >&2; exit 1 ;;
esac

test -n "$account_id" && test -n "$role" && test -n "$region"
[[ "$account_id" =~ ^[0-9]{12}$ ]] || { echo 'AWS account ID must contain 12 digits.' >&2; exit 1; }
[[ "$role" == "arn:aws:iam::$account_id:role/"* ]] || {
  echo 'Role ARN does not belong to the selected account.' >&2
  exit 1
}

echo "role=$role" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
echo "region=$region" >> "$GITHUB_OUTPUT"
echo "live_dir=infra/live/$target/app" >> "$GITHUB_OUTPUT"
echo "TG_AWS_ACCOUNT_ID=$account_id" >> "${GITHUB_ENV:?GITHUB_ENV is required}"
echo "TG_AWS_REGION=$region" >> "$GITHUB_ENV"
