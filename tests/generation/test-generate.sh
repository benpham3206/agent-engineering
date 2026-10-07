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

require_tracked_executable() {
  local relpath="$1"
  local stage mode
  stage="$(git -C "$root" ls-files --stage -- "$relpath")"
  [[ -n "$stage" ]] || fail_contract "missing tracked file: $relpath"
  mode="${stage%% *}"
  [[ "$mode" == "100755" ]] || fail_contract "template script is not executable in git: $relpath (mode $mode)"
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
require_file "$core_out/scripts/backbone.list"
if [[ -x "$core_out/scripts/verify-repo.sh" ]]; then
  bash "$core_out/scripts/verify-repo.sh" >/dev/null || fail_contract "generated core repository failed its own verifier"

  printf '{{PROJECT_NAME}}\n' > "$core_out/unreplaced-token.txt"
  if bash "$core_out/scripts/verify-repo.sh" >/dev/null 2>&1; then
    fail_contract "generated repository verifier missed an unreplaced template token"
  fi
  rm -f "$core_out/unreplaced-token.txt"

  # A repository that ships its own templates (a factory) keeps tokens in them on purpose.
  mkdir -p "$core_out/templates/app"
  printf '{{PROJECT_NAME}}\n' > "$core_out/templates/app/README.md"
  if bash "$core_out/scripts/verify-repo.sh" >/dev/null 2>&1; then
    fail_contract "repository verifier skipped a template folder that TEMPLATE_PATHS does not declare"
  fi
  cp -p "$core_out/.engineering-manifest" "$tmp/manifest.bak"
  printf 'TEMPLATE_PATHS=templates/*\n' >> "$core_out/.engineering-manifest"
  bash "$core_out/scripts/verify-repo.sh" >/dev/null 2>&1 \
    || fail_contract "repository verifier flagged a token in a TEMPLATE_PATHS folder"
  cp -p "$tmp/manifest.bak" "$core_out/.engineering-manifest"
  rm -rf "${core_out:?}/templates"

  minimal_out="$tmp/minimal-core-output"
  cp -a "$core_out" "$minimal_out"
  rm -rf \
    "${minimal_out:?}/src" "${minimal_out:?}/tests" "${minimal_out:?}/evals" "${minimal_out:?}/experiments" \
    "${minimal_out:?}/docs" "${minimal_out:?}/config" "${minimal_out:?}/artifacts" "${minimal_out:?}/.github"
  rm -f "$minimal_out/ROADMAP.md" "$minimal_out/CONTRIBUTING.md" "$minimal_out/Makefile"
  bash "$minimal_out/scripts/verify-repo.sh" >/dev/null || fail_contract "generated repository required optional starter structure"

  cp "$minimal_out/AGENTS.md" "$tmp/core-agents.md"
  rm -f "$minimal_out/AGENTS.md"
  if bash "$minimal_out/scripts/verify-repo.sh" >/dev/null 2>&1; then
    fail_contract "generated repository verifier allowed a permanent core invariant to disappear"
  fi
  cp "$tmp/core-agents.md" "$minimal_out/AGENTS.md"

  mkdir -p "$core_out/node_modules/pkg"
  printf '{{PROJECT_NAME}}\n' > "$core_out/node_modules/pkg/index.js"
  bash "$core_out/scripts/verify-repo.sh" >/dev/null || fail_contract "repository verifier scanned dependency files outside git"
  rm -rf "${core_out:?}/node_modules"

  HOME="$tmp" git -c init.defaultBranch=main -C "$core_out" init -q
  printf 'node_modules/\n' > "$core_out/.gitignore"
  mkdir -p "$core_out/node_modules/pkg"
  printf '{{PROJECT_NAME}}\n' > "$core_out/node_modules/pkg/index.js"
  bash "$core_out/scripts/verify-repo.sh" >/dev/null || fail_contract "repository verifier scanned ignored files inside git"
  rm -rf "${core_out:?}/node_modules"
  printf '{{PROJECT_NAME}}\n' > "$core_out/notes.md"
  if bash "$core_out/scripts/verify-repo.sh" >/dev/null 2>&1; then
    fail_contract "repository verifier missed an untracked token inside git"
  fi
  rm -f "$core_out/notes.md"

  run_hook="$core_out/scripts/run-hook.sh"
  bash "$run_hook" >/dev/null 2>&1
  status=$?
  [[ "$status" -eq 64 ]] || fail_contract "run-hook accepted a missing hook name (exit $status)"
  bash "$run_hook" bogus >/dev/null 2>&1
  status=$?
  [[ "$status" -eq 64 ]] || fail_contract "run-hook accepted an unknown hook name (exit $status)"
  bash "$run_hook" check >/dev/null 2>&1
  status=$?
  [[ "$status" -eq 0 ]] || fail_contract "run-hook failed to skip an unconfigured hook (exit $status)"
  bash "$run_hook" --required check >/dev/null 2>&1
  status=$?
  [[ "$status" -eq 78 ]] || fail_contract "run-hook skipped a missing required hook (exit $status)"

  printf 'printf "should not run\\n"\n' > "$core_out/scripts/project/check"
  bash "$run_hook" check >/dev/null 2>&1
  status=$?
  [[ "$status" -eq 126 ]] || fail_contract "run-hook executed a non-executable project hook (exit $status)"
  printf '#!/usr/bin/env bash\nprintf "project hook ran\\n"\n' > "$core_out/scripts/project/check"
  chmod +x "$core_out/scripts/project/check"
  hook_stdout="$(bash "$run_hook" check 2>/dev/null)"
  status=$?
  [[ "$status" -eq 0 ]] || fail_contract "run-hook failed an executable project hook (exit $status)"
  [[ "$hook_stdout" == *"project hook ran"* ]] || fail_contract "run-hook did not surface project hook output"
  rm -f "$core_out/scripts/project/check"
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

while IFS= read -r relpath; do
  require_tracked_executable "$relpath"
done < <(git -C "$root" ls-files -- '*.sh')

mode_dir="$tmp/mode-preservation"
mkdir -p "$mode_dir"
printf '#!/usr/bin/env bash\nprintf "{{PROJECT_NAME}}\\n"\n' > "$mode_dir/tool.sh"
chmod +x "$mode_dir/tool.sh"
bash -c 'source "$1"; replace_tokens "$2" mode-test 2026' _ "$root/tooling/lib.sh" "$mode_dir"
[[ -x "$mode_dir/tool.sh" ]] || fail_contract "token replacement changed executable mode bits"
require_contains "$mode_dir/tool.sh" "mode-test"

adopt_out="$tmp/adopt-existing"
mkdir -p "$adopt_out/app"
printf 'existing readme\n' > "$adopt_out/README.md"
printf 'existing app\n' > "$adopt_out/app/main.txt"
if ! bash "$root/tooling/adopt.sh" "existing-app" "$adopt_out" >/dev/null; then
  fail_contract "ADOPT failed for an existing project"
else
  require_contains "$adopt_out/README.md" "existing readme"
  require_contains "$adopt_out/app/main.txt" "existing app"
  require_file "$adopt_out/AGENTS.md"
  require_file "$adopt_out/GOAL.md"
  require_file "$adopt_out/Makefile"
  require_file "$adopt_out/.engineering-manifest"
  require_file "$adopt_out/scripts/backbone.list"
  require_contains "$adopt_out/.engineering-manifest" "PROJECT_NAME=existing-app"
  if [[ -x "$adopt_out/scripts/verify-repo.sh" ]]; then
    bash "$adopt_out/scripts/verify-repo.sh" >/dev/null || fail_contract "adopted project failed repository verification"
  else
    fail_contract "ADOPT did not install repository verification"
  fi
fi

adopt_no_readme="$tmp/adopt-no-readme"
mkdir -p "$adopt_no_readme"
printf 'existing app\n' > "$adopt_no_readme/app.txt"
if ! bash "$root/tooling/adopt.sh" "no-readme-app" "$adopt_no_readme" >/dev/null; then
  fail_contract "ADOPT failed for an existing project without a README"
else
  require_contains "$adopt_no_readme/README.md" "# no-readme-app"
  require_contains "$adopt_no_readme/README.md" "Agent Engineering"
  require_contains "$adopt_no_readme/README.md" '`GOAL.md`'
  require_not_contains "$adopt_no_readme/README.md" "make verify"
fi

fake_starter="$tmp/fake-starter.sh"
cat > "$fake_starter" <<'EOF_STARTER'
#!/usr/bin/env bash
set -euo pipefail
printf 'native starter readme\n' > README.md
printf '{"name":"native-app"}\n' > package.json
mkdir -p src
printf 'working product\n' > src/app.txt
EOF_STARTER
chmod +x "$fake_starter"
new_out="$tmp/new-native"
if ! bash "$root/tooling/new.sh" "native-app" "$new_out" -- "$fake_starter" >/dev/null; then
  fail_contract "NEW failed with an ecosystem-native starter"
else
  require_contains "$new_out/README.md" "native starter readme"
  require_contains "$new_out/src/app.txt" "working product"
  require_file "$new_out/AGENTS.md"
  require_contains "$new_out/.engineering-manifest" "PROJECT_NAME=native-app"
fi
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
require_contains "$root/templates/core/AGENTS.md" "## Feature path"
require_contains "$root/templates/core/AGENTS.md" "Treat working product behavior as the initial bottleneck"
require_contains "$root/templates/core/AGENTS.md" "A feature request authorizes pursuit of that bounded product outcome."
require_contains "$root/templates/core/AGENTS.md" "Do not ask for approval again"
require_contains "$root/standards/engineering.md" "Split modules on reasons to change, not on size."
require_contains "$root/templates/core/AGENTS.md" "Split on reasons to change, not on size alone"
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

# 6. Overlay integrity proves add-ons cannot shadow backbone files or each other.
backbone_list_file="$root/templates/core/scripts/backbone.list"
overlay_seen="$tmp/overlay-seen"
: > "$overlay_seen"

shadow_overlay="$tmp/overlay-shadow"
mkdir -p "$shadow_overlay"
printf 'shadowed rules\n' > "$shadow_overlay/AGENTS.md"
if bash -c 'source "$1"; assert_overlay_safe "$2" "$3" "$4"' \
  _ "$root/tooling/lib.sh" "$shadow_overlay" "$backbone_list_file" "$overlay_seen" >/dev/null 2>&1; then
  fail_contract "add-on overlay replaced a backbone file"
fi

overlay_one="$tmp/overlay-one"
overlay_two="$tmp/overlay-two"
mkdir -p "$overlay_one/extra" "$overlay_two/extra"
printf 'one\n' > "$overlay_one/extra/notes.md"
printf 'two\n' > "$overlay_two/extra/notes.md"
if ! bash -c 'source "$1"; assert_overlay_safe "$2" "$3" "$4"' \
  _ "$root/tooling/lib.sh" "$overlay_one" "$backbone_list_file" "$overlay_seen" >/dev/null 2>&1; then
  fail_contract "a benign add-on file was rejected"
fi
if bash -c 'source "$1"; assert_overlay_safe "$2" "$3" "$4"' \
  _ "$root/tooling/lib.sh" "$overlay_two" "$backbone_list_file" "$overlay_seen" >/dev/null 2>&1; then
  fail_contract "two add-ons collided on a path"
fi
finish_contract "overlay integrity"

# 7. Destructive-input safety proves generation fails without overwriting data or executing config text.
nonempty_out="$tmp/nonempty-output"
mkdir -p "$nonempty_out"
printf 'keep me\n' > "$nonempty_out/existing.txt"
nonempty_config="$tmp/nonempty.conf"
write_config "$nonempty_config" "nonempty" "" "$nonempty_out"
require_rejected "$nonempty_config"
require_contains "$nonempty_out/existing.txt" "keep me"

adopt_conflict="$tmp/adopt-conflict"
mkdir -p "$adopt_conflict"
printf 'existing goal\n' > "$adopt_conflict/GOAL.md"
printf 'keep me\n' > "$adopt_conflict/application.txt"
if bash "$root/tooling/adopt.sh" "conflict-app" "$adopt_conflict" >/dev/null 2>&1; then
  fail_contract "ADOPT overwrote or accepted a conflicting operating file"
fi
require_contains "$adopt_conflict/GOAL.md" "existing goal"
require_contains "$adopt_conflict/application.txt" "keep me"
require_absent "$adopt_conflict/.engineering-manifest"
require_absent "$adopt_conflict/AGENTS.md"

adopt_merge="$tmp/adopt-merge"
mkdir -p "$adopt_merge"
printf 'existing agent rules\n' > "$adopt_merge/AGENTS.md"
printf 'existing: ;\n' > "$adopt_merge/Makefile"
if ! bash "$root/tooling/adopt.sh" "merge-app" "$adopt_merge" >/dev/null; then
  fail_contract "ADOPT failed to merge an existing AGENTS.md"
else
  require_contains "$adopt_merge/AGENTS.md" "# Agent operating rules"
  require_contains "$adopt_merge/AGENTS.md" "## Project rules"
  require_contains "$adopt_merge/AGENTS.md" "existing agent rules"
  require_contains "$adopt_merge/Makefile" "existing"
  require_file "$adopt_merge/.engineering-manifest"
  if [[ -x "$adopt_merge/scripts/verify-repo.sh" ]]; then
    bash "$adopt_merge/scripts/verify-repo.sh" >/dev/null || fail_contract "merged adopt failed repository verification"
  else
    fail_contract "merged ADOPT did not install repository verification"
  fi
fi

adopt_symlink="$tmp/adopt-symlink"
adopt_symlink_escape="$tmp/adopt-symlink-escape"
mkdir -p "$adopt_symlink" "$adopt_symlink_escape"
if ln -s "$adopt_symlink_escape" "$adopt_symlink/scripts" 2>/dev/null && [[ -L "$adopt_symlink/scripts" ]]; then
  if bash "$root/tooling/adopt.sh" "symlink-app" "$adopt_symlink" >/dev/null 2>&1; then
    fail_contract "ADOPT followed a symlinked scripts boundary"
  fi
  require_absent "$adopt_symlink_escape/verify-repo.sh"
  require_absent "$adopt_symlink/.engineering-manifest"
  require_absent "$adopt_symlink/GOAL.md"
else
  rm -f "$adopt_symlink/scripts"
fi

adopt_agents_link="$tmp/adopt-agents-symlink"
mkdir -p "$adopt_agents_link"
printf 'linked rules\n' > "$tmp/agents-link-target.md"
if ln -s "$tmp/agents-link-target.md" "$adopt_agents_link/AGENTS.md" 2>/dev/null && [[ -L "$adopt_agents_link/AGENTS.md" ]]; then
  if bash "$root/tooling/adopt.sh" "agents-symlink-app" "$adopt_agents_link" >/dev/null 2>&1; then
    fail_contract "ADOPT accepted a symlinked AGENTS.md"
  fi
  require_absent "$adopt_agents_link/.engineering-manifest"
else
  rm -f "$adopt_agents_link/AGENTS.md"
fi

new_nonempty="$tmp/new-nonempty"
mkdir -p "$new_nonempty"
printf 'keep me\n' > "$new_nonempty/existing.txt"
new_marker="$tmp/new-starter-executed"
unsafe_starter="$tmp/unsafe-starter.sh"
cat > "$unsafe_starter" <<EOF_STARTER
#!/usr/bin/env bash
touch "$new_marker"
EOF_STARTER
chmod +x "$unsafe_starter"
if bash "$root/tooling/new.sh" "nonempty-new" "$new_nonempty" -- "$unsafe_starter" >/dev/null 2>&1; then
  fail_contract "NEW accepted a non-empty target"
fi
require_contains "$new_nonempty/existing.txt" "keep me"
require_absent "$new_marker"

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

# 8. Downstream update proves UPDATE replaces only bytes it can prove the old template owns, and changes nothing when it refuses.
fae="$tmp/update-ae"
mkdir -p "$fae/templates"
cp -R "$root/tooling" "$fae/tooling"
cp -R "$root/templates/core" "$fae/templates/core"
cp "$root/TEMPLATE_VERSION" "$fae/TEMPLATE_VERSION"
fgit() { HOME="$tmp" git -C "$fae" -c user.name=contract -c user.email=contract@example.invalid -c core.autocrlf=false "$@"; }
fgit init -q
fgit config core.autocrlf false
printf 'old worker line\n' >> "$fae/templates/core/WORKER_TASK.md"
printf '# old verifier line\n' >> "$fae/templates/core/scripts/verify-repo.sh"
printf '\nOld agents line.\n' >> "$fae/templates/core/AGENTS.md"
fgit add -A
fgit commit -q -m old
old_rev="$(fgit rev-parse --short HEAD)"

snapshot() {
  (cd "$1" && find . \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r f; do
    if [[ -L "$f" ]]; then printf '%s -> %s\n' "$f" "$(readlink "$f")"; else printf '%s %s\n' "$f" "$(cksum < "$f")"; fi
  done)
}
update_adopt() {
  mkdir -p "$2"
  printf 'app\n' > "$2/app.txt"
  [[ -n "${3:-}" ]] && printf '%s' "$3" > "$2/AGENTS.md"
  bash "$fae/tooling/adopt.sh" "$1" "$2" >/dev/null || fail_contract "fixture ADOPT failed: $1"
}
set_manifest() {
  { grep -v "^$2=" "$1/.engineering-manifest"; printf '%s=%s\n' "$2" "$3"; } > "$tmp/manifest.new"
  mv "$tmp/manifest.new" "$1/.engineering-manifest"
}
to_crlf() {
  awk '{ printf "%s\r\n", $0 }' "$1" > "$1.crlf"
  mv "$1.crlf" "$1"
}
run_update() {
  bash "$fae/tooling/update.sh" "$@" >/dev/null 2>&1
}
require_refused_unchanged() {
  local label="$1"; shift
  local dir="${*: -1}" before
  before="$(snapshot "$dir")"
  if run_update "$@"; then
    fail_contract "UPDATE accepted $label"
  fi
  [[ "$(snapshot "$dir")" == "$before" ]] || fail_contract "UPDATE changed files while refusing $label"
}

u_clean="$tmp/update-clean"
update_adopt clean-app "$u_clean" $'project rule one\n  indented rule  \n'
for f in GOAL.md STATUS.md ARCHITECTURE.md SECURITY.md README.md Makefile; do
  printf 'local %s\n' "$f" >> "$u_clean/$f"
done
u_conflict="$tmp/update-conflict"
update_adopt conflict-app "$u_conflict"
printf '# local edit\n' >> "$u_conflict/scripts/run-hook.sh"
u_prefix="$tmp/update-prefix"
update_adopt prefix-app "$u_prefix"
{ printf '# Locally renamed rules\n'; tail -n +2 "$u_prefix/AGENTS.md"; } > "$tmp/prefix.new"
mv "$tmp/prefix.new" "$u_prefix/AGENTS.md"
u_link="$tmp/update-link"
update_adopt link-app "$u_link"
u_baseline="$tmp/update-baseline"
update_adopt baseline-app "$u_baseline"
u_self="$tmp/update-self"
update_adopt self-app "$u_self"
set_manifest "$u_self" TEMPLATE_REVISION self
u_inject="$tmp/update-inject"
update_adopt inject-app "$u_inject"
set_manifest "$u_inject" PROJECT_NAME "\$(touch $tmp/update-executed)"
u_crlf="$tmp/update-crlf"
update_adopt crlf-app "$u_crlf"
for f in WORKER_TASK.md AGENTS.md scripts/security-check.sh; do to_crlf "$u_crlf/$f"; done
set_manifest "$u_crlf" ADDONS open-source
set_manifest "$u_crlf" TEMPLATE_PATHS 'templates/*'
cp "$u_crlf/scripts/security-check.sh" "$tmp/update-current.crlf"
u_dirty="$tmp/update-dirty"
update_adopt dirty-app "$u_dirty"

old_agents_bytes="$(fgit show "$old_rev:templates/core/AGENTS.md" | wc -c | tr -d ' ')"
tail -c +"$((old_agents_bytes + 1))" "$u_clean/AGENTS.md" > "$tmp/update-suffix"
(cd "$u_clean" && cksum GOAL.md STATUS.md ARCHITECTURE.md SECURITY.md README.md Makefile app.txt) > "$tmp/update-owned.before"
set_manifest "$u_baseline" TEMPLATE_REVISION deadbee

cp "$root/templates/core/WORKER_TASK.md" "$fae/templates/core/WORKER_TASK.md"
cp -p "$root/templates/core/scripts/verify-repo.sh" "$fae/templates/core/scripts/verify-repo.sh"
cp "$root/templates/core/AGENTS.md" "$fae/templates/core/AGENTS.md"
printf '# Extra task\n' > "$fae/templates/core/EXTRA_TASK.md"
printf 'EXTRA_TASK.md\n' >> "$fae/templates/core/scripts/backbone.list"
fgit add -A
fgit commit -q -m new
new_rev="$(fgit rev-parse --short HEAD)"

before="$(snapshot "$u_clean")"
run_update --check "$u_clean" || fail_contract "UPDATE --check refused a cleanly updatable project"
[[ "$(snapshot "$u_clean")" == "$before" ]] || fail_contract "UPDATE --check wrote to the project"
if run_update "$u_clean"; then
  for f in WORKER_TASK.md scripts/verify-repo.sh scripts/backbone.list EXTRA_TASK.md; do
    require_same "$fae/templates/core/$f" "$u_clean/$f"
  done
  [[ -x "$u_clean/scripts/verify-repo.sh" ]] || fail_contract "UPDATE dropped the executable mode of a replaced script"
  cat "$fae/templates/core/AGENTS.md" "$tmp/update-suffix" > "$tmp/update-agents.expected"
  require_same "$tmp/update-agents.expected" "$u_clean/AGENTS.md"
  (cd "$u_clean" && cksum GOAL.md STATUS.md ARCHITECTURE.md SECURITY.md README.md Makefile app.txt) > "$tmp/update-owned.after"
  require_same "$tmp/update-owned.before" "$tmp/update-owned.after"
  require_contains "$u_clean/.engineering-manifest" "TEMPLATE_REVISION=$new_rev"
  require_contains "$u_clean/.engineering-manifest" "PROJECT_NAME=clean-app"
  bash "$u_clean/scripts/verify-repo.sh" >/dev/null || fail_contract "updated project failed its own verifier"
  before="$(snapshot "$u_clean")"
  run_update "$u_clean" || fail_contract "UPDATE was not idempotent on an up-to-date project"
  [[ "$(snapshot "$u_clean")" == "$before" ]] || fail_contract "UPDATE rewrote an up-to-date project"
else
  fail_contract "UPDATE refused a cleanly updatable project"
fi

require_refused_unchanged "a late local edit after an updatable early file" "$u_conflict"
require_refused_unchanged "a late local edit in check mode" --check "$u_conflict"
require_refused_unchanged "an edited AGENTS.md template prefix" "$u_prefix"
require_refused_unchanged "an unknown baseline revision" "$u_baseline"
require_refused_unchanged "a self-hosting baseline" "$u_self"
require_refused_unchanged "an executable manifest value" "$u_inject"
require_absent "$tmp/update-executed"

printf 'outside\n' > "$tmp/update-link-target"
mv "$u_link/scripts/run-hook.sh" "$tmp/update-link-original"
if ln -s "$tmp/update-link-target" "$u_link/scripts/run-hook.sh" 2>/dev/null && [[ -L "$u_link/scripts/run-hook.sh" ]]; then
  require_refused_unchanged "a symlinked managed file" "$u_link"
  require_contains "$tmp/update-link-target" "outside"
fi

if run_update "$u_crlf"; then
  cp "$fae/templates/core/WORKER_TASK.md" "$tmp/update-worker.crlf"
  to_crlf "$tmp/update-worker.crlf"
  require_same "$tmp/update-worker.crlf" "$u_crlf/WORKER_TASK.md"
  cp "$fae/templates/core/AGENTS.md" "$tmp/update-agents.crlf"
  to_crlf "$tmp/update-agents.crlf"
  require_same "$tmp/update-agents.crlf" "$u_crlf/AGENTS.md"
  require_same "$tmp/update-current.crlf" "$u_crlf/scripts/security-check.sh"
  require_contains "$u_crlf/.engineering-manifest" "ADDONS=open-source"
  require_contains "$u_crlf/.engineering-manifest" "TEMPLATE_PATHS=templates/*"
  require_absent "$u_crlf/LICENSE"
else
  fail_contract "UPDATE refused a project whose managed files use CRLF line endings"
fi

printf 'uncommitted template edit\n' >> "$fae/templates/core/WORKER_TASK.md"
require_refused_unchanged "an Agent Engineering checkout with uncommitted template changes" "$u_dirty"
u_adopt_dirty="$tmp/update-adopt-dirty"
mkdir -p "$u_adopt_dirty"
if bash "$fae/tooling/adopt.sh" adopt-dirty-app "$u_adopt_dirty" >/dev/null 2>&1; then
  fail_contract "ADOPT recorded a baseline revision that its copied templates do not match"
fi
require_absent "$u_adopt_dirty/.engineering-manifest"
fgit checkout -q -- templates/core/WORKER_TASK.md
run_update "$u_dirty" || fail_contract "UPDATE refused a clean project after the template checkout was restored"
finish_contract "downstream update"

printf '\n%d contracts passed; %d failed\n' "$passed" "$failed"
[[ "$failed" -eq 0 ]]
