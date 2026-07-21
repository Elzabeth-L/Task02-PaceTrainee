#!/usr/bin/env bash
set -Eeuo pipefail

operation="${OPERATION:?OPERATION is required}"
previous_ssm="$RUNNER_TEMP/previous-ssm.json"
parameter_script="$GITHUB_WORKSPACE/scripts/infrastructure/image-parameters.sh"

restore_ssm() {
  bash "$parameter_script" restore "$previous_ssm"
}

if [[ "$operation" == apply ]]; then
  trap 'restore_ssm; echo "SSM values restored after plan failure" >&2' ERR
fi

terragrunt init -input=false
if [[ "$operation" == destroy ]]; then
  terragrunt plan -destroy -input=false -no-color -out="$RUNNER_TEMP/reviewed.tfplan"
else
  terragrunt plan -input=false -no-color -out="$RUNNER_TEMP/reviewed.tfplan"
fi
terragrunt show -no-color "$RUNNER_TEMP/reviewed.tfplan" > "$RUNNER_TEMP/reviewed-plan.txt"
(
  cd "$RUNNER_TEMP"
  sha256sum reviewed.tfplan > reviewed.tfplan.sha256
)
cp "$previous_ssm" "$RUNNER_TEMP/previous-ssm-artifact.json"

if [[ "$operation" == apply ]]; then
  trap - ERR
  restore_ssm
fi
