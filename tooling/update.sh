#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/tooling/lib.sh"

usage() {
  printf 'usage: %s [--check] <project-dir>\n' "$0" >&2
  exit 2
}

check=0
if [[ $# -eq 2 && "$1" == --check ]]; then
  check=1
  shift
fi
[[ $# -eq 1 && "$1" != -* ]] || usage
target_arg="$1"

# The Agent Engineering checkout is the source of truth: its committed HEAD, never uncommitted edits.
git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { fail "not a git work tree: $root"; exit 1; }
if [[ -n "$(git -C "$root" status --porcelain -- templates/core)" ]]; then
  fail 'uncommitted template changes; commit or stash them first'
  exit 1
fi
new_revision="$(git -C "$root" rev-parse --short HEAD)"
new_version="$(tr -d '\r\n' < "$root/TEMPLATE_VERSION")"

validate_shell_path "$target_arg" || exit 1
[[ -d "$target_arg" ]] || { fail "project directory not found: $target_arg"; exit 1; }
target="$(cd "$target_arg" && pwd -P)"
manifest="$target/.engineering-manifest"
if [[ -L "$manifest" || ! -f "$manifest" ]]; then
  fail "missing or non-regular .engineering-manifest in $target"
  exit 1
fi

# Parse the manifest as data; never source or evaluate it.
m_template='' m_version='' m_revision='' m_name='' m_addons=''
seen=','
line_no=0
while IFS= read -r raw || [[ -n "$raw" ]]; do
  line_no=$((line_no + 1))
  raw="${raw%$'\r'}"
  line="$(trim "$raw")"
  [[ -z "$line" || "${line:0:1}" == '#' ]] && continue
  [[ "$line" == *=* ]] || { fail "invalid manifest line $line_no: expected KEY=value"; exit 1; }
  key="$(trim "${line%%=*}")"
  value="$(trim "${line#*=}")"
  case "$key" in
    TEMPLATE) m_template="$value" ;;
    TEMPLATE_VERSION) m_version="$value" ;;
    TEMPLATE_REVISION) m_revision="$value" ;;
    PROJECT_NAME) m_name="$value" ;;
    ADDONS) m_addons="$value" ;;
    TEMPLATE_PATHS) ;;
    *) fail "unknown manifest key '$key' on line $line_no"; exit 1 ;;
  esac
  [[ "$seen" != *",$key,"* ]] || { fail "duplicate manifest key '$key' on line $line_no"; exit 1; }
  seen="$seen$key,"
done < "$manifest"

for key in TEMPLATE TEMPLATE_VERSION TEMPLATE_REVISION PROJECT_NAME ADDONS; do
  [[ "$seen" == *",$key,"* ]] || { fail "manifest is missing $key"; exit 1; }
done
[[ "$m_template" == agent-engineering ]] || { fail "manifest TEMPLATE is not agent-engineering: $m_template"; exit 1; }
validate_project_name "$m_name" || exit 1
if [[ -n "$m_addons" ]]; then
  IFS=',' read -r -a items <<< "$m_addons"
  for item in "${items[@]}"; do
    is_supported_addon "$(trim "$item")" || { fail "unknown add-on in manifest: $item"; exit 1; }
  done
fi
[[ "$m_version" =~ ^[A-Za-z0-9._-]+$ ]] || { fail "invalid TEMPLATE_VERSION: $m_version"; exit 1; }
if [[ ! "$m_revision" =~ ^[0-9a-f]{7,40}$ ]]; then
  fail "TEMPLATE_REVISION '$m_revision' is not a commit; this project has no baseline to update from"
  exit 1
fi
baseline="$(git -C "$root" rev-parse -q --verify "$m_revision^{commit}" 2>/dev/null)" \
  || { fail "unknown baseline revision $m_revision; fetch the Agent Engineering history that contains it"; exit 1; }
git -C "$root" merge-base --is-ancestor "$baseline" HEAD \
  || { fail "this checkout is not newer than baseline $m_revision"; exit 1; }

stage="$(mktemp -d)"
n=0
cleanup() {
  local i=1
  while [[ "$i" -le "$n" ]]; do rm -f "$stage/$i"; i=$((i + 1)); done
  rmdir "$stage" 2>/dev/null || printf 'warning: left temporary directory %s\n' "$stage" >&2
}
trap cleanup EXIT

# next_file sets $f to a fresh numbered file in $stage.
next_file() { n=$((n + 1)); f="$stage/$n"; : > "$f"; }
# blob <rev> <path>: sets $f to the template file at that revision, or '' if it does not exist there.
blob() {
  if git -C "$root" cat-file -e "$1:templates/core/$2" 2>/dev/null; then
    next_file
    git -C "$root" cat-file blob "$1:templates/core/$2" > "$f"
  else
    f=''
  fi
}
crlf_of() { next_file; awk '{ printf "%s\r\n", $0 }' "$1" > "$f"; }
size_of() { wc -c < "$1" | tr -d ' '; }
list_paths() {
  local path
  while IFS= read -r path || [[ -n "$path" ]]; do
    path="${path%$'\r'}"
    [[ -z "$path" || "${path:0:1}" == '#' ]] && continue
    printf '%s\n' "$path"
  done < "$1"
}

blob HEAD scripts/backbone.list
new_list="$f"
[[ -n "$new_list" ]] || { fail 'backbone list missing at HEAD'; exit 1; }
blob "$baseline" scripts/backbone.list
old_list="$f"
[[ -n "$old_list" ]] || { next_file; old_list="$f"; }
next_file
paths="$f"
{ list_paths "$new_list"; list_paths "$old_list"; } | awk '!seen[$0]++' > "$paths"

# Preflight: decide every action before writing anything.
kinds=() targets=() sources=() modes=()
conflicts=0 changes=0
report() { printf '%s\n' "$1"; }
conflict() { report "conflict $1: $2"; conflicts=$((conflicts + 1)); }
plan() { kinds+=("$1"); targets+=("$2"); sources+=("$3"); modes+=("${4:-}"); changes=$((changes + 1)); report "$1 $2"; }

unsafe_location() {
  local path="$1" dir="$target" part rest="$1"
  while [[ "$rest" == */* ]]; do
    part="${rest%%/*}"
    rest="${rest#*/}"
    dir="$dir/$part"
    if [[ -L "$dir" || ( -e "$dir" && ! -d "$dir" ) ]]; then
      return 0
    fi
  done
  [[ -L "$target/$path" || ( -e "$target/$path" && ! -f "$target/$path" ) ]]
}

while IFS= read -r path; do
  case "$path" in GOAL.md|STATUS.md|ARCHITECTURE.md|SECURITY.md) continue ;; esac
  case "/$path/" in
    //*|*/../*|*/./*) conflict "$path" 'unsafe path in backbone list'; continue ;;
  esac
  if unsafe_location "$path"; then
    conflict "$path" 'symlink or non-regular file'
    continue
  fi
  if ! grep -Fqx -- "$path" <(list_paths "$new_list"); then
    report "keep $path (removed from template; automatic removal unsupported)"
    continue
  fi

  t="$target/$path"
  blob "$baseline" "$path"; o="$f"
  blob HEAD "$path"; c="$f"
  crlf_of "$c"; c_crlf="$f"
  o_crlf=''
  if [[ -n "$o" ]]; then crlf_of "$o"; o_crlf="$f"; fi

  if [[ "$path" == AGENTS.md ]]; then
    if [[ ! -f "$t" ]]; then
      conflict "$path" 'managed file missing'
      continue
    fi
    # The template owns only a byte prefix; everything after it belongs to the project.
    best='' best_len=-1
    for cand in "$c" "$c_crlf" "$o" "$o_crlf"; do
      [[ -n "$cand" ]] || continue
      len="$(size_of "$cand")"
      if [[ "$len" -gt "$best_len" ]] && head -c "$len" "$t" | cmp -s - "$cand"; then
        best="$cand" best_len="$len"
      fi
    done
    case "$best" in
      '') conflict "$path" 'Agent Engineering prefix modified' ;;
      "$c"|"$c_crlf") report "current $path" ;;
      *)
        next_file
        if [[ "$best" == "$o" ]]; then cat "$c" > "$f"; else cat "$c_crlf" > "$f"; fi
        tail -c +"$((best_len + 1))" "$t" >> "$f"
        plan replace "$path" "$f"
        ;;
    esac
    continue
  fi

  if [[ ! -e "$t" ]]; then
    if [[ -n "$o" ]] && grep -Fqx -- "$path" <(list_paths "$old_list"); then
      conflict "$path" 'managed file missing'
    else
      mode=644
      [[ "$(git -C "$root" ls-tree HEAD "templates/core/$path")" == 100755* ]] && mode=755
      plan add "$path" "$c" "$mode"
    fi
  elif cmp -s "$t" "$c" || cmp -s "$t" "$c_crlf"; then
    report "current $path"
  elif [[ -n "$o" ]] && cmp -s "$t" "$o"; then
    plan replace "$path" "$c"
  elif [[ -n "$o" ]] && cmp -s "$t" "$o_crlf"; then
    plan replace "$path" "$c_crlf"
  else
    conflict "$path" 'locally modified'
  fi
done < "$paths"

if [[ -n "$m_addons" ]]; then
  report "note: add-on files ($m_addons) are not updated"
fi
if [[ "$conflicts" -gt 0 ]]; then
  report "refused: $conflicts conflict(s)"
  exit 1
fi
if [[ "$changes" -eq 0 ]]; then
  report 'up to date'
  exit 0
fi
if [[ "$check" -eq 1 ]]; then
  report "update available: $changes change(s)"
  exit 0
fi

# Apply: each file goes through a sibling temp and an atomic rename.
written=''
sibling=''
abort() {
  [[ -n "$sibling" ]] && rm -f "$sibling"
  fail "update stopped at $1; already written:${written:- none}; manifest unchanged; re-run after fixing the cause"
  exit 1
}
i=0
while [[ "$i" -lt "${#kinds[@]}" ]]; do
  path="${targets[$i]}"
  t="$target/$path"
  sibling="$t.ae-update.$$"
  if [[ "${kinds[$i]}" == add ]]; then
    mkdir -p "$(dirname "$t")" || abort "$path"
    cat "${sources[$i]}" > "$sibling" || abort "$path"
    chmod "${modes[$i]}" "$sibling" || abort "$path"
  else
    cp -p "$t" "$sibling" || abort "$path"
    cat "${sources[$i]}" > "$sibling" || abort "$path"
  fi
  mv -f "$sibling" "$t" || abort "$path"
  sibling=''
  written="$written $path"
  i=$((i + 1))
done

sibling="$manifest.ae-update.$$"
cp -p "$manifest" "$sibling" || abort .engineering-manifest
while IFS= read -r raw || [[ -n "$raw" ]]; do
  cr=''
  [[ "$raw" == *$'\r' ]] && cr=$'\r'
  case "$(trim "${raw%%=*}")" in
    TEMPLATE_VERSION) printf 'TEMPLATE_VERSION=%s%s\n' "$new_version" "$cr" ;;
    TEMPLATE_REVISION) printf 'TEMPLATE_REVISION=%s%s\n' "$new_revision" "$cr" ;;
    *) printf '%s\n' "$raw" ;;
  esac
done < "$manifest" > "$sibling" || abort .engineering-manifest
mv -f "$sibling" "$manifest" || abort .engineering-manifest

report "updated: $changes change(s)"
