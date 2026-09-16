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

backbone_list="$root/templates/core/scripts/backbone.list"
[[ -f "$backbone_list" ]] || fail 'backbone list missing'

backbone_paths() {
  local path
  while IFS= read -r path || [[ -n "$path" ]]; do
    path="${path%$'\r'}"
    [[ -z "$path" || "${path:0:1}" == '#' ]] && continue
    printf '%s\n' "$path"
  done < "$backbone_list"
}

while IFS= read -r path; do
  if [[ "$path" == AGENTS.md ]]; then
    continue
  fi
  if [[ -e "$target/$path" || -L "$target/$path" ]]; then
    fail "ADOPT conflict: $path already exists"
    exit 1
  fi
done < <(backbone_paths)

if [[ -L "$target/AGENTS.md" || ( -e "$target/AGENTS.md" && ! -f "$target/AGENTS.md" ) ]]; then
  fail 'ADOPT conflict: AGENTS.md must be a regular file when present'
  exit 1
fi

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

if [[ ! -e "$target/Makefile" && ! -L "$target/Makefile" ]]; then
  cp -p "$root/templates/core/Makefile" "$stage/Makefile"
fi

replace_tokens "$stage" "$project_name" "$(date +%Y)"
write_engineering_manifest "$stage" "$project_name" ''

if [[ -f "$target/AGENTS.md" ]]; then
  {
    printf '\n## Project rules\n\n'
    printf "Rules carried over from the project's existing AGENTS.md. Where they are more specific than the sections above, they take precedence.\n\n"
    cat "$target/AGENTS.md"
    if [[ -n "$(tail -c 1 "$target/AGENTS.md")" ]]; then
      printf '\n'
    fi
  } >> "$stage/AGENTS.md"
fi

while IFS= read -r path; do
  mkdir -p "$target/$(dirname "$path")"
  cp -p "$stage/$path" "$target/$path"
done < <(backbone_paths)

if [[ -f "$stage/README.md" ]]; then
  cp -p "$stage/README.md" "$target/README.md"
fi
if [[ -f "$stage/Makefile" ]]; then
  cp -p "$stage/Makefile" "$target/Makefile"
fi
cp -p "$stage/.engineering-manifest" "$target/.engineering-manifest"

printf 'adopted: %s\n' "$target"
