#!/usr/bin/env bash
set -Eeuo pipefail

terragrunt init -input=false
terragrunt apply -input=false -no-color "${RUNNER_TEMP:?RUNNER_TEMP is required}/plan/reviewed.tfplan"
