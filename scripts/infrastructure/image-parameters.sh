#!/usr/bin/env bash
set -Eeuo pipefail

command="${1:?Usage: image-parameters.sh <capture|set|restore> [file]}"
project="${TG_PROJECT_NAME:?TG_PROJECT_NAME is required}"
account="${ACCOUNT_ALIAS:?ACCOUNT_ALIAS is required}"

parameter_path() {
  local service="$1"
  printf '/%s/%s/%s-image-uri' "$project" "$account" "$service"
}

case "$command" in
  capture)
    output_file="${2:?Capture requires an output file}"
    read_parameter() {
      local path="$1" value exists
      if value="$(aws ssm get-parameter --name "$path" --query 'Parameter.Value' --output text 2>/dev/null)"; then
        exists=true
      else
        value=''
        exists=false
      fi
      jq -n --arg path "$path" --arg value "$value" --argjson exists "$exists" \
        '{path:$path,value:$value,existed:$exists}'
    }
    frontend="$(read_parameter "$(parameter_path frontend)")"
    backend="$(read_parameter "$(parameter_path backend)")"
    jq -n --argjson frontend "$frontend" --argjson backend "$backend" \
      '{frontend:$frontend,backend:$backend}' > "$output_file"
    ;;
  set)
    image_sha="${IMAGE_SHA:?IMAGE_SHA is required}"
    [[ "$image_sha" =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid image SHA.' >&2; exit 1; }
    owner="${GHCR_OWNER:?GHCR_OWNER is required}"
    prefix="${GHCR_REPOSITORY_PREFIX:?GHCR_REPOSITORY_PREFIX is required}"
    owner="${owner,,}"
    prefix="${prefix,,}"
    for service in frontend backend; do
      aws ssm put-parameter \
        --name "$(parameter_path "$service")" \
        --type String \
        --overwrite \
        --value "ghcr.io/$owner/$prefix-$service:$image_sha" >/dev/null
    done
    ;;
  restore)
    input_file="${2:?Restore requires an input file}"
    while IFS=$'\t' read -r path value existed; do
      if [[ "$existed" == true ]]; then
        aws ssm put-parameter --name "$path" --type String --overwrite --value "$value" >/dev/null
      else
        aws ssm delete-parameter --name "$path" >/dev/null 2>&1 || true
      fi
    done < <(jq -r '.frontend,.backend | [.path,.value,(.existed|tostring)] | @tsv' "$input_file")
    ;;
  *) echo "Unsupported image parameter command: $command" >&2; exit 1 ;;
esac
