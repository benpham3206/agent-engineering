#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/tooling/lib.sh"

if [[ $# -ne 2 ]]; then
  printf 'usage: %s <project-name> <existing-project-dir>\n' "$0" >&2
  exit 2
fi

project_name="$1"
target_arg="$2"
validate_project_name "$project_name"
validate_shell_path "$target_arg"

if [[ ! -d "$target_arg" ]]; then
  fail "existing project directory not found: $target_arg"
  exit 1
fi

target="$(cd "$target_arg" && pwd -P)"

if [[ -L "$target/scripts" || ( -e "$target/scripts" && ! -d "$target/scripts" ) ]]; then
  fail 'ADOPT conflict: scripts must be a real directory when present'
  exit 1
fi

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

backbone_paths() {
  printf '%s\n' \
    GOAL.md \
    STATUS.md \
    ARCHITECTURE.md \
    AGENTS.md \
    SECURITY.md \
    WORKER_TASK.md \
    ARCHITECT_TASK.md \
    REVIEWER_TASK.md \
    SECURITY_REVIEWER_TASK.md \
    RESEARCH_TASK.md \
    scripts/verify-repo.sh \
    scripts/security-check.sh \
    scripts/run-hook.sh
}

while IFS= read -r path; do
  if [[ -e "$target/$path" || -L "$target/$path" ]]; then
    fail "ADOPT conflict: $path already exists"
    exit 1
  fi
done < <(backbone_paths)

if [[ -e "$target/.engineering-manifest" || -L "$target/.engineering-manifest" ]]; then
  fail 'ADOPT conflict: .engineering-manifest already exists'
  exit 1
fi

while IFS= read -r path; do
  mkdir -p "$stage/$(dirname "$path")"
  cp -p "$root/templates/core/$path" "$stage/$path"
done < <(backbone_paths)

if [[ ! -e "$target/README.md" && ! -L "$target/README.md" ]]; then
  printf '# %s\n\nThis project uses the Agent Engineering operating layer. Start with `GOAL.md`, `ARCHITECTURE.md`, `STATUS.md`, `AGENTS.md`, and `SECURITY.md`.\n' \
    "$project_name" > "$stage/README.md"
fi

replace_tokens "$stage" "$project_name" "$(date +%Y)"
write_engineering_manifest "$stage" "$project_name" ''

while IFS= read -r path; do
  mkdir -p "$target/$(dirname "$path")"
  cp -p "$stage/$path" "$target/$path"
done < <(backbone_paths)

if [[ -f "$stage/README.md" ]]; then
  cp -p "$stage/README.md" "$target/README.md"
fi
cp -p "$stage/.engineering-manifest" "$target/.engineering-manifest"

printf 'adopted: %s\n' "$target"
