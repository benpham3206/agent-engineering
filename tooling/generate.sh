#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/tooling/lib.sh"

if [[ $# -ne 1 ]]; then
  printf 'usage: %s <project.conf>\n' "$0" >&2
  exit 2
fi

config="$1"
load_project_config "$config"
validate_output_dir "$RESOLVED_OUTPUT_DIR"

output="$RESOLVED_OUTPUT_DIR"
mkdir -p "$output"

copy_overlay "$root/templates/core" "$output"


if [[ -n "$NORMALIZED_ADDONS" ]]; then
  while IFS= read -r addon; do
    copy_overlay "$root/addons/$addon/files" "$output"
  done < <(printf '%s\n' "$NORMALIZED_ADDONS" | tr ',' '\n')
fi

year="$(date +%Y)"
replace_tokens "$output" "$CONFIG_PROJECT_NAME" "$year"

write_engineering_manifest "$output" "$CONFIG_PROJECT_NAME" "$NORMALIZED_ADDONS"

if [[ -x "$output/scripts/verify-repo.sh" ]]; then
  bash "$output/scripts/verify-repo.sh"
else
  fail 'generated repository is missing an executable scripts/verify-repo.sh'
  exit 1
fi

printf 'generated: %s\n' "$output"
