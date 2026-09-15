#!/usr/bin/env bash
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
generator="$root/tooling/generate.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

passed=0
failed=0
contract_errors=0

fail_contract() {
  printf '  - %s\n' "$1" >&2
  contract_errors=$((contract_errors + 1))
}

finish_contract() {
  local label="$1"
  if [[ "$contract_errors" -eq 0 ]]; then
    printf 'ok - %s\n' "$label"
    passed=$((passed + 1))
  else
    printf 'not ok - %s (%d issue%s)\n' "$label" "$contract_errors" "$([[ "$contract_errors" -eq 1 ]] && printf '' || printf 's')" >&2
    failed=$((failed + 1))
  fi
  contract_errors=0
}

require_file() {
  [[ -f "$1" ]] || fail_contract "missing file: $1"
}

require_dir() {
  [[ -d "$1" ]] || fail_contract "missing directory: $1"
}

require_absent() {
  [[ ! -e "$1" ]] || fail_contract "unexpected path: $1"
}

require_contains() {
  local path="$1" needle="$2"
  if [[ ! -f "$path" ]] || ! grep -Fq -- "$needle" "$path"; then
    fail_contract "expected '$needle' in $path"
  fi
}

require_not_contains() {
  local path="$1" needle="$2"
  if [[ ! -f "$path" ]] || grep -Fq -- "$needle" "$path"; then
    fail_contract "did not expect '$needle' in $path"
  fi
}

require_same() {
  cmp -s "$1" "$2" || fail_contract "files differ: $1 and $2"
}

require_validate_rejected() {
  if bash "$root/tooling/validate-config.sh" "$1" >/dev/null 2>&1; then
    fail_contract "unsafe or invalid config was accepted by validation: $1"
  fi
}

run_generate() {
  bash "$generator" "$1" >/dev/null
}

require_generate() {
  if ! run_generate "$1"; then
    fail_contract "generation failed for $1"
  fi
}

require_rejected() {
  if run_generate "$1" >/dev/null 2>&1; then
    fail_contract "unsafe or invalid config was accepted: $1"
  fi
}

write_config() {
  local path="$1" name="$2" addons="$3" output="$4"
  cat > "$path" <<EOF_CONFIG
PROJECT_NAME=$name
ADDONS=$addons
OUTPUT_DIR=$output
EOF_CONFIG
}

# 1. Core generation proves the base template composes into a usable project.
core_config="$tmp/core.conf"
core_out="$tmp/core-output"
write_config "$core_config" "core-agent" "" "$core_out"
require_generate "$core_config"
require_file "$core_out/.engineering-manifest"
require_file "$core_out/src/README.md"
require_contains "$core_out/README.md" "# core-agent"
require_contains "$core_out/.engineering-manifest" "ADDONS="
require_absent "$core_out/LICENSE"
require_absent "$core_out/OWNERS"
require_absent "$core_out/addons"
if [[ -x "$core_out/scripts/verify-repo.sh" ]]; then
  bash "$core_out/scripts/verify-repo.sh" >/dev/null || fail_contract "generated core repository failed its own verifier"

  printf '{{PROJECT_NAME}}\n' > "$core_out/unreplaced-token.txt"
  if bash "$core_out/scripts/verify-repo.sh" >/dev/null 2>&1; then
    fail_contract "generated repository verifier missed an unreplaced template token"
  fi
  rm -f "$core_out/unreplaced-token.txt"

  minimal_out="$tmp/minimal-core-output"
  cp -a "$core_out" "$minimal_out"
  rm -rf \
    "$minimal_out/src" "$minimal_out/tests" "$minimal_out/evals" "$minimal_out/experiments" \
    "$minimal_out/docs" "$minimal_out/config" "$minimal_out/artifacts" "$minimal_out/.github"
  rm -f "$minimal_out/ROADMAP.md" "$minimal_out/CONTRIBUTING.md" "$minimal_out/Makefile"
  bash "$minimal_out/scripts/verify-repo.sh" >/dev/null || fail_contract "generated repository required optional starter structure"

  cp "$minimal_out/AGENTS.md" "$tmp/core-agents.md"
  rm -f "$minimal_out/AGENTS.md"
  if bash "$minimal_out/scripts/verify-repo.sh" >/dev/null 2>&1; then
    fail_contract "generated repository verifier allowed a permanent core invariant to disappear"
  fi
  cp "$tmp/core-agents.md" "$minimal_out/AGENTS.md"
else
  fail_contract "generated core repository has no verifier"
fi

secret_config="$tmp/secret.conf"
secret_out="$tmp/secret-output"
write_config "$secret_config" "secret-agent" "" "$secret_out"
require_generate "$secret_config"
if [[ -x "$secret_out/scripts/security-check.sh" ]]; then
  nested_parent="$tmp/nested-parent"
  mkdir -p "$nested_parent/generated"
  git -C "$nested_parent" init -q
  cp -a "$secret_out"/. "$nested_parent/generated"/
  bash "$nested_parent/generated/scripts/security-check.sh" > "$tmp/nested-security.out"
  require_contains "$tmp/nested-security.out" "SKIP"

  git -C "$secret_out" init -q
  printf 'EXAMPLE=true\n' > "$secret_out/.env.example"
  git -C "$secret_out" add -f .env.example
  bash "$secret_out/scripts/security-check.sh" >/dev/null || fail_contract "security policy rejected an explicit example env file"

  git -C "$secret_out" rm -q --cached .env.example
  rm -f "$secret_out/.env.example"
  mkdir -p "$secret_out/config"
  printf 'SECRET=value\n' > "$secret_out/config/.env.production"
  git -C "$secret_out" add -f config/.env.production
  if bash "$secret_out/scripts/security-check.sh" >/dev/null 2>&1; then
    fail_contract "security policy allowed a nested tracked environment file"
  fi
  if bash "$secret_out/scripts/verify-repo.sh" >/dev/null 2>&1; then
    fail_contract "repository verifier did not delegate tracked secret-file policy"
  fi

  git -C "$secret_out" rm -q --cached config/.env.production
  rm -f "$secret_out/config/.env.production"
  printf 'SECRET=value\n' > "$secret_out/config/prod.env"
  git -C "$secret_out" add -f config/prod.env
  if bash "$secret_out/scripts/security-check.sh" >/dev/null 2>&1; then
    fail_contract "security policy allowed a tracked *.env file"
  fi

  fake_git_dir="$tmp/fake-git-bin"
  mkdir -p "$fake_git_dir"
  real_git="$(command -v git)"
  cat > "$fake_git_dir/git" <<'EOF_FAKE_GIT'
#!/usr/bin/env bash
for arg in "$@"; do
  if [[ "$arg" == "--show-toplevel" ]]; then
    printf '%s\n' "$FAKE_GIT_ROOT"
    exit 0
  fi
done
exec "$REAL_GIT" "$@"
EOF_FAKE_GIT
  chmod +x "$fake_git_dir/git"
  if REAL_GIT="$real_git" FAKE_GIT_ROOT="$secret_out/." PATH="$fake_git_dir:$PATH" \
    bash "$secret_out/scripts/security-check.sh" >/dev/null 2>&1; then
    fail_contract "security policy skipped the project when Git used an equivalent path spelling"
  fi
  if REAL_GIT="$real_git" FAKE_GIT_ROOT="$tmp/missing-git-root" PATH="$fake_git_dir:$PATH" \
    bash "$secret_out/scripts/security-check.sh" >/dev/null 2>&1; then
    fail_contract "security policy failed open when the reported Git root could not be resolved"
  fi
else
  fail_contract "generated core repository has no security check"
fi

require_not_contains "$root/tooling/lib.sh" "chmod --reference"
require_not_contains "$root/tooling/generate.sh" 'ADDON_LIST[@]'

mode_dir="$tmp/mode-preservation"
mkdir -p "$mode_dir"
printf '#!/usr/bin/env bash\nprintf "{{PROJECT_NAME}}\\n"\n' > "$mode_dir/tool.sh"
chmod +x "$mode_dir/tool.sh"
bash -c 'source "$1"; replace_tokens "$2" mode-test 2026' _ "$root/tooling/lib.sh" "$mode_dir"
[[ -x "$mode_dir/tool.sh" ]] || fail_contract "token replacement changed executable mode bits"
require_contains "$mode_dir/tool.sh" "mode-test"
finish_contract "core generation"

# 2. Engineering doctrine proves critical inherited behavior survives generation.
for file in AGENTS.md ARCHITECTURE.md GOAL.md STATUS.md SECURITY.md CONTRIBUTING.md WORKER_TASK.md ARCHITECT_TASK.md REVIEWER_TASK.md SECURITY_REVIEWER_TASK.md RESEARCH_TASK.md; do
  require_same "$root/templates/core/$file" "$core_out/$file"
done
require_contains "$root/templates/core/AGENTS.md" "Stop at the first option that works."
require_contains "$root/templates/core/AGENTS.md" "Judge agents by externally verified outcomes under fixed constraints, not by activity."
require_contains "$root/templates/core/WORKER_TASK.md" "Anything not listed is denied."
require_contains "$root/templates/core/WORKER_TASK.md" "Write or modify tests."
require_contains "$root/templates/core/AGENTS.md" "Agents do not silently switch roles."
require_contains "$root/templates/core/ARCHITECT_TASK.md" "Do not absorb worker implementation."
require_contains "$root/templates/core/REVIEWER_TASK.md" "Do not write or modify code or tests."
require_contains "$root/templates/core/SECURITY_REVIEWER_TASK.md" "Do not write or modify code or tests."
require_contains "$root/templates/core/RESEARCH_TASK.md" "The researcher proposes; the architect reviews; the user decides whether implementation proceeds."
require_contains "$root/templates/core/AGENTS.md" "Reviewers do not write or modify code or tests."
require_contains "$root/templates/core/AGENTS.md" "Do not add a test merely because code changed."
require_contains "$root/templates/core/AGENTS.md" "Anything not explicitly granted is denied."
require_contains "$root/templates/core/AGENTS.md" "Do not reselect the stack"
require_contains "$root/templates/core/AGENTS.md" "## Operating loop"
require_contains "$root/templates/core/AGENTS.md" "Excellent is the default. Timeless is the goal."
require_contains "$root/templates/core/WORKER_TASK.md" "## Quality bar"
require_contains "$root/templates/core/SECURITY.md" "Runtime controls enforce authority"
require_contains "$root/templates/core/ARCHITECTURE.md" "goal → constraints → required capabilities → system choices → evidence → observed bottleneck"
require_contains "$root/templates/core/GOAL.md" "## Constraint categories"
require_contains "$root/standards/engineering.md" "## Constraints before tools"
require_contains "$root/standards/documentation.md" "sentence-case headings"
require_contains "$root/templates/core/README.md" "GOAL.md -> ROADMAP.md + ARCHITECTURE.md -> STATUS.md"
require_contains "$root/templates/core/AGENTS.md" 'Read in this order: `GOAL.md` -> `ROADMAP.md` -> `ARCHITECTURE.md` -> `STATUS.md`.'
require_contains "$root/templates/core/GOAL.md" "## Success conditions"
require_not_contains "$root/templates/core/GOAL.md" "## Current bottleneck"
require_contains "$root/templates/core/REVIEWER_TASK.md" "State the change or decision under review."
require_not_contains "$root/templates/core/REVIEWER_TASK.md" "accept or reject"
finish_contract "inherited engineering doctrine"

# 3. Open-source composition proves public-facing add-ons compose without organization policy.
oss_config="$tmp/oss.conf"
oss_out="$tmp/oss-output"
write_config "$oss_config" "public-agent" "open-source,releases,benchmarks" "$oss_out"
require_generate "$oss_config"
require_file "$oss_out/LICENSE"
require_file "$oss_out/GOVERNANCE.md"
require_file "$oss_out/.github/workflows/release.yml"
require_file "$oss_out/.github/workflows/benchmarks.yml"
require_absent "$oss_out/OWNERS"
require_absent "$oss_out/CODE_OF_CONDUCT.md"
require_not_contains "$oss_out/LICENSE" "{{YEAR}}"
require_contains "$oss_out/.engineering-manifest" "ADDONS=open-source,releases,benchmarks"
if [[ -x "$oss_out/scripts/verify-repo.sh" ]]; then
  bash "$oss_out/scripts/verify-repo.sh" >/dev/null || fail_contract "open-source composition failed repository verification"
fi
finish_contract "open-source composition"

# 4. Organization composition proves internal and operational add-ons can compose together.
org_config="$tmp/org.conf"
org_out="$tmp/org-output"
write_config "$org_config" "internal-agent" "organization,deployment,observability,performance,security-hardening" "$org_out"
require_generate "$org_config"
require_file "$org_out/OWNERS"
require_file "$org_out/SERVICE.md"
require_file "$org_out/.github/workflows/deploy.yml"
require_file "$org_out/docs/operations/observability.md"
require_dir "$org_out/evals/performance"
require_file "$org_out/THREAT_MODEL.md"
require_file "$org_out/evals/adversarial/README.md"
require_absent "$org_out/LICENSE"
require_absent "$org_out/GOVERNANCE.md"
require_contains "$org_out/.engineering-manifest" "ADDONS=organization,deployment,observability,performance,security-hardening"
if [[ -x "$org_out/scripts/verify-repo.sh" ]]; then
  bash "$org_out/scripts/verify-repo.sh" >/dev/null || fail_contract "organization composition failed repository verification"
fi
finish_contract "organization composition"

# 5. Manifest rejection proves malformed, obsolete, and unsupported configuration fails closed.
legacy_profile_config="$tmp/legacy-profile.conf"
cat > "$legacy_profile_config" <<EOF_CONFIG
PROJECT_NAME=legacy-profile
PROFILE=open-source
ADDONS=
OUTPUT_DIR=$tmp/legacy-profile-output
EOF_CONFIG
require_rejected "$legacy_profile_config"

bad_addon_config="$tmp/bad-addon.conf"
write_config "$bad_addon_config" "bad-addon" "unknown" "$tmp/bad-addon-output"
require_rejected "$bad_addon_config"

unknown_key_config="$tmp/unknown-key.conf"
cat > "$unknown_key_config" <<EOF_CONFIG
PROJECT_NAME=unknown-key
ADDONS=
OUTPUT_DIR=$tmp/unknown-key-output
SURPRISE=true
EOF_CONFIG
require_rejected "$unknown_key_config"

duplicate_key_config="$tmp/duplicate-key.conf"
cat > "$duplicate_key_config" <<EOF_CONFIG
PROJECT_NAME=duplicate-key
PROJECT_NAME=duplicate-key-again
ADDONS=
OUTPUT_DIR=$tmp/duplicate-key-output
EOF_CONFIG
require_rejected "$duplicate_key_config"

unsafe_name_config="$tmp/unsafe-name.conf"
write_config "$unsafe_name_config" "../escape" "" "$tmp/unsafe-name-output"
require_rejected "$unsafe_name_config"

windows_drive_config="$tmp/windows-drive.conf"
write_config "$windows_drive_config" "windows-drive" "" "D:/Codex/windows-drive"
require_validate_rejected "$windows_drive_config"
finish_contract "manifest rejection"

# 6. Destructive-input safety proves generation fails without overwriting data or executing config text.
nonempty_out="$tmp/nonempty-output"
mkdir -p "$nonempty_out"
printf 'keep me\n' > "$nonempty_out/existing.txt"
nonempty_config="$tmp/nonempty.conf"
write_config "$nonempty_config" "nonempty" "" "$nonempty_out"
require_rejected "$nonempty_config"
require_contains "$nonempty_out/existing.txt" "keep me"

marker="$tmp/manifest-executed"
inert_config="$tmp/inert.conf"
cat > "$inert_config" <<EOF_CONFIG
PROJECT_NAME=\$(touch $marker)
ADDONS=
OUTPUT_DIR=$tmp/inert-output
EOF_CONFIG
require_rejected "$inert_config"
require_absent "$marker"
finish_contract "destructive-input safety"

printf '\n%d contracts passed; %d failed\n' "$passed" "$failed"
[[ "$failed" -eq 0 ]]
