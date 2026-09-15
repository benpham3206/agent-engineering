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

template_version='unversioned'
if [[ -f "$root/TEMPLATE_VERSION" ]]; then
  template_version="$(tr -d '\r\n' < "$root/TEMPLATE_VERSION")"
fi

template_revision='unknown'
if git -C "$root" rev-parse --short HEAD >/dev/null 2>&1; then
  template_revision="$(git -C "$root" rev-parse --short HEAD)"
fi

cat > "$output/.engineering-manifest" <<EOF_MANIFEST
TEMPLATE=agent-engineering
TEMPLATE_VERSION=$template_version
TEMPLATE_REVISION=$template_revision
PROJECT_NAME=$CONFIG_PROJECT_NAME
ADDONS=$NORMALIZED_ADDONS
EOF_MANIFEST

if [[ -x "$output/scripts/verify-repo.sh" ]]; then
  bash "$output/scripts/verify-repo.sh"
else
  fail 'generated repository is missing scripts/verify-repo.sh'
  exit 1
fi

printf 'generated: %s\n' "$output"
