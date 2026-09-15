#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/tooling/lib.sh"

if [[ $# -ne 1 ]]; then
  printf 'usage: %s <project.conf>\n' "$0" >&2
  exit 2
fi

load_project_config "$1"
validate_output_dir "$RESOLVED_OUTPUT_DIR"

printf 'PROJECT_NAME=%s\n' "$CONFIG_PROJECT_NAME"
printf 'ADDONS=%s\n' "$NORMALIZED_ADDONS"
printf 'OUTPUT_DIR=%s\n' "$RESOLVED_OUTPUT_DIR"
