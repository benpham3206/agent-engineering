#!/usr/bin/env bash

set -euo pipefail

AE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

fail() {
  printf 'error: %s\n' "$1" >&2
  return 1
}

is_supported_addon() {
  case "$1" in
    open-source|organization|deployment|releases|observability|benchmarks|performance|security-hardening) return 0 ;;
    *) return 1 ;;
  esac
}

load_project_config() {
  local config="$1"
  [[ -f "$config" ]] || fail "config file not found: $config" || return 1

  CONFIG_PROJECT_NAME=''
  CONFIG_ADDONS=''
  CONFIG_OUTPUT_DIR=''

  local raw line key value
  local line_no=0
  local seen_project_name=0
  local seen_addons=0
  local seen_output_dir=0

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    line_no=$((line_no + 1))
    raw="${raw%$'\r'}"
    line="$(trim "$raw")"
    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" == '#' ]] && continue

    if [[ "$line" != *=* ]]; then
      fail "invalid config line $line_no: expected KEY=value" || return 1
    fi

    key="$(trim "${line%%=*}")"
    value="$(trim "${line#*=}")"

    case "$key" in
      PROJECT_NAME|ADDONS|OUTPUT_DIR) ;;
      *) fail "unknown config key '$key' on line $line_no" || return 1 ;;
    esac

    case "$key" in
      PROJECT_NAME)
        [[ "$seen_project_name" -eq 0 ]] || fail "duplicate config key '$key' on line $line_no" || return 1
        seen_project_name=1
        CONFIG_PROJECT_NAME="$value"
        ;;
      ADDONS)
        [[ "$seen_addons" -eq 0 ]] || fail "duplicate config key '$key' on line $line_no" || return 1
        seen_addons=1
        CONFIG_ADDONS="$value"
        ;;
      OUTPUT_DIR)
        [[ "$seen_output_dir" -eq 0 ]] || fail "duplicate config key '$key' on line $line_no" || return 1
        seen_output_dir=1
        CONFIG_OUTPUT_DIR="$value"
        ;;
    esac
  done < "$config"

  if [[ -z "$CONFIG_PROJECT_NAME" ]]; then
    fail 'PROJECT_NAME is required' || return 1
  fi

  if [[ ! "$CONFIG_PROJECT_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    fail "unsafe PROJECT_NAME '$CONFIG_PROJECT_NAME'; use letters, numbers, '.', '_', or '-'" || return 1
  fi

  NORMALIZED_ADDONS=''

  if [[ -n "$CONFIG_ADDONS" ]]; then
    local item addon items
    local seen_addon_names=','
    IFS=',' read -r -a items <<< "$CONFIG_ADDONS"
    for item in "${items[@]}"; do
      addon="$(trim "$item")"
      [[ -n "$addon" ]] || fail 'ADDONS contains an empty entry' || return 1
      if ! is_supported_addon "$addon"; then
        fail "unknown add-on '$addon'" || return 1
      fi
      if [[ "$seen_addon_names" == *",$addon,"* ]]; then
        fail "duplicate add-on '$addon'" || return 1
      fi
      seen_addon_names="${seen_addon_names}${addon},"
      if [[ -n "$NORMALIZED_ADDONS" ]]; then
        NORMALIZED_ADDONS="$NORMALIZED_ADDONS,$addon"
      else
        NORMALIZED_ADDONS="$addon"
      fi
    done
  fi

  if [[ -n "$CONFIG_OUTPUT_DIR" ]]; then
    if [[ "$CONFIG_OUTPUT_DIR" == [A-Za-z]:/* || "$CONFIG_OUTPUT_DIR" == [A-Za-z]:\\* ]]; then
      fail "Windows drive path '$CONFIG_OUTPUT_DIR' is not accepted; in Git Bash use a POSIX path such as /d/Codex/project" || return 1
    fi
    if [[ "$CONFIG_OUTPUT_DIR" = /* ]]; then
      RESOLVED_OUTPUT_DIR="$CONFIG_OUTPUT_DIR"
    else
      RESOLVED_OUTPUT_DIR="$AE_ROOT/$CONFIG_OUTPUT_DIR"
    fi
  else
    RESOLVED_OUTPUT_DIR="$AE_ROOT/dist/$CONFIG_PROJECT_NAME"
  fi
}

validate_output_dir() {
  local output="$1"
  if [[ -e "$output" ]]; then
    if [[ ! -d "$output" ]]; then
      fail "OUTPUT_DIR exists and is not a directory: $output" || return 1
    fi
    if find "$output" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
      fail "OUTPUT_DIR is not empty: $output" || return 1
    fi
  fi
}

copy_overlay() {
  local source="$1" destination="$2"
  [[ -d "$source" ]] || fail "overlay source missing: $source" || return 1
  mkdir -p "$destination"
  cp -a "$source"/. "$destination"/
}

replace_tokens() {
  local destination="$1" project_name="$2" year="$3"
  local file tmp

  while IFS= read -r -d '' file; do
    if grep -Iq . "$file" 2>/dev/null || [[ ! -s "$file" ]]; then
      if grep -Eq '\{\{(PROJECT_NAME|YEAR)\}\}' "$file" 2>/dev/null; then
        tmp="${file}.ae-tmp"
        cp -p "$file" "$tmp"
        sed \
          -e "s/{{PROJECT_NAME}}/$project_name/g" \
          -e "s/{{YEAR}}/$year/g" \
          "$file" > "$tmp"
        mv "$tmp" "$file"
      fi
    fi
  done < <(find "$destination" -type f -print0)
}
