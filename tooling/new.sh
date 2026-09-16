#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/tooling/lib.sh"

if [[ $# -lt 4 || "$3" != '--' ]]; then
  printf 'usage: %s <project-name> <target-dir> -- <ecosystem-starter> [args...]\n' "$0" >&2
  exit 2
fi

project_name="$1"
target_arg="$2"
validate_project_name "$project_name"
validate_shell_path "$target_arg"
validate_output_dir "$target_arg"

shift 3
mkdir -p "$target_arg"
target="$(cd "$target_arg" && pwd -P)"

(
  cd "$target"
  "$@"
)

bash "$root/tooling/adopt.sh" "$project_name" "$target"
printf 'created: %s\n' "$target"
