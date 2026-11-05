#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
update_script="${AE_UPDATE_SCRIPT:-$root/tooling/update.sh}"
baseline="$(git -C "$root" rev-parse '9116d0d^')"
run="$(mktemp -d)"
archive="$run/archive"
bin="$run/bin"
marker="$run/race-injected"
mkdir -p "$archive" "$bin"
trap 'rm -rf "$run"' EXIT
git -C "$root" archive "$baseline" templates/core TEMPLATE_VERSION | tar -x -C "$archive"

make_target() {
	target="$run/$1"
	mkdir -p "$target"
	target="$(cd "$target" && pwd -P)"
	while IFS= read -r path || [[ -n "$path" ]]; do
		[[ -z "$path" || "${path:0:1}" == "#" ]] && continue
		case "$path" in GOAL.md|STATUS.md|ARCHITECTURE.md|SECURITY.md) continue ;; esac
		source="$archive/templates/core/$path"
		[[ -f "$source" ]] || continue
		mkdir -p "$target/$(dirname "$path")"
		cp -p "$source" "$target/$path"
	done < "$archive/templates/core/scripts/backbone.list"
	old_version="$(tr -d '\r\n' < "$archive/TEMPLATE_VERSION")"
	printf 'TEMPLATE=agent-engineering\nTEMPLATE_VERSION=%s\nTEMPLATE_REVISION=%s\nPROJECT_NAME=update-race\nADDONS=\n' \
		"$old_version" "$(git -C "$root" rev-parse --short "$baseline")" > "$target/.engineering-manifest"
}

real_cp="$(command -v cp)"
real_mv="$(command -v mv)"
cat > "$bin/cp" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$AE_RACE_MODE" == inode && "$#" -eq 3 && "$1" == "-p" && "$2" == "$AE_RACE_TARGET" && ! -e "$AE_RACE_MARKER" ]]; then
	"$AE_REAL_CP" "$@"
	printf '\nlocal edit inserted after preflight\n' >> "$AE_RACE_TARGET"
	: > "$AE_RACE_MARKER"
	exit 0
fi
exec "$AE_REAL_CP" "$@"
EOF
cat > "$bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$AE_RACE_MODE" == failure && "$#" -eq 3 && "$1" == "-n" && "$3" == "$AE_RACE_TARGET" && ! -e "$AE_RACE_MARKER" ]]; then
	: > "$AE_RACE_MARKER"
	exit 1
fi
if [[ "$AE_RACE_MODE" == backup && "$#" -eq 3 && "$1" == "-n" && "$2" == "$AE_RACE_TARGET" && "$3" == "$AE_RACE_TARGET.local-"* && ! -e "$AE_RACE_MARKER" ]]; then
	printf 'racing backup file\n' > "$3"
	: > "$AE_RACE_MARKER"
fi
if [[ "$AE_RACE_MODE" == directory && "$#" -eq 3 && "$1" == "-n" && "$3" == "$AE_RACE_TARGET" && ! -e "$AE_RACE_MARKER" ]]; then
	mkdir "$3"
	: > "$AE_RACE_MARKER"
fi
if [[ "$AE_RACE_MODE" == path && "$#" -eq 3 && ( "$1" == "-f" || "$1" == "-n" ) && "$3" == "$AE_RACE_TARGET" && ! -e "$AE_RACE_MARKER" ]]; then
	printf '\nlocal edit inserted after preflight\n' >> "$AE_RACE_TARGET"
	: > "$AE_RACE_MARKER"
fi
exec "$AE_REAL_MV" "$@"
EOF
chmod +x "$bin/cp" "$bin/mv"

run_case() {
	mode="$1"
	make_target "$mode-target"
	rm -f "$marker"
	if PATH="$bin:$PATH" \
		AE_REAL_CP="$real_cp" \
		AE_REAL_MV="$real_mv" \
		AE_RACE_MODE="$mode" \
		AE_RACE_TARGET="$target/scripts/verify-repo.sh" \
		AE_RACE_MARKER="$marker" \
		bash "$update_script" "$target" > "$run/$mode-update.out" 2>&1; then
		status=0
	else
		status=$?
	fi
	[[ -f "$marker" ]] || { cat "$run/$mode-update.out"; printf 'FAIL: %s edit injection did not run\n' "$mode"; exit 1; }
	if [[ "$status" -eq 0 ]]; then
		printf 'FAIL: UPDATE accepted the late edit and removed it in the %s case\n' "$mode"
		exit 1
	fi
	grep -Fq "TEMPLATE_REVISION=$(git -C "$root" rev-parse --short "$baseline")" "$target/.engineering-manifest" \
		|| { printf 'FAIL: UPDATE advanced the manifest after refusing the %s edit\n' "$mode"; exit 1; }
	grep -Fq 'update stopped at scripts/verify-repo.sh' "$run/$mode-update.out" \
		|| { cat "$run/$mode-update.out"; printf 'FAIL: UPDATE did not report the refused %s edit\n' "$mode"; exit 1; }
	if [[ "$mode" == path ]]; then
		grep -Fq 'local edit inserted after preflight' "$target/scripts/verify-repo.sh" \
			|| { printf 'FAIL: UPDATE refused but did not preserve the late path edit\n'; exit 1; }
	else
		preserved=''
		for candidate in "$target/scripts/verify-repo.sh.local-"*; do
			[[ -f "$candidate" ]] || continue
			if grep -Fq 'local edit inserted after preflight' "$candidate"; then preserved="$candidate"; break; fi
		done
		[[ -n "$preserved" ]] || { printf 'FAIL: UPDATE did not preserve the changed moved file\n'; exit 1; }
	fi
	printf 'PASS: UPDATE refused and preserved the late edit in the %s case; the manifest stayed at %s.\n' \
		"$mode" "$(git -C "$root" rev-parse --short "$baseline")"
	cat "$run/$mode-update.out"
}

run_recovery_case() {
	make_target recovery-target
	if PATH="$bin:$PATH" \
		AE_REAL_CP="$real_cp" \
		AE_REAL_MV="$real_mv" \
		AE_RACE_MODE=failure \
		AE_RACE_TARGET="$target/scripts/verify-repo.sh" \
		AE_RACE_MARKER="$marker" \
		bash "$update_script" "$target" > "$run/recovery-update.out" 2>&1; then
		status=0
	else
		status=$?
	fi
	[[ -f "$marker" ]] || { cat "$run/recovery-update.out"; printf 'FAIL: install failure injection did not run\n'; exit 1; }
	[[ "$status" -ne 0 ]] || { printf 'FAIL: UPDATE accepted an install failure\n'; exit 1; }
	cmp -s "$archive/templates/core/scripts/verify-repo.sh" "$target/scripts/verify-repo.sh" \
		|| { printf 'FAIL: UPDATE did not restore the original file after install failure\n'; exit 1; }
	grep -Fq "TEMPLATE_REVISION=$(git -C "$root" rev-parse --short "$baseline")" "$target/.engineering-manifest" \
		|| { printf 'FAIL: UPDATE advanced the manifest after an install failure\n'; exit 1; }
	printf 'PASS: UPDATE restored the original file after install failure; the manifest stayed at %s.\n' \
		"$(git -C "$root" rev-parse --short "$baseline")"
	cat "$run/recovery-update.out"
}

run_directory_case() {
	make_target directory-target
	rm -f "$marker"
	if PATH="$bin:$PATH" \
		AE_REAL_CP="$real_cp" \
		AE_REAL_MV="$real_mv" \
		AE_RACE_MODE=directory \
		AE_RACE_TARGET="$target/scripts/verify-repo.sh" \
		AE_RACE_MARKER="$marker" \
		bash "$update_script" "$target" > "$run/directory-update.out" 2>&1; then
		status=0
	else
		status=$?
	fi
	[[ -f "$marker" && "$status" -ne 0 && -d "$target/scripts/verify-repo.sh" ]] \
		|| { cat "$run/directory-update.out"; printf 'FAIL: UPDATE accepted a directory at the install path\n'; exit 1; }
	[[ -z "$(find "$target/scripts/verify-repo.sh" -mindepth 1 -maxdepth 1 -print -quit)" ]] \
		|| { printf 'FAIL: UPDATE left its staged file inside the racing directory\n'; exit 1; }
	preserved=''
	for candidate in "$target/scripts/verify-repo.sh.local-"*; do
		[[ -f "$candidate" ]] || continue
		if cmp -s "$archive/templates/core/scripts/verify-repo.sh" "$candidate"; then preserved="$candidate"; break; fi
	done
	[[ -n "$preserved" ]] || { printf 'FAIL: UPDATE did not preserve the original file after a directory race\n'; exit 1; }
	grep -Fq "TEMPLATE_REVISION=$(git -C "$root" rev-parse --short "$baseline")" "$target/.engineering-manifest" \
		|| { printf 'FAIL: UPDATE advanced the manifest after a directory race\n'; exit 1; }
	printf 'PASS: UPDATE refused the directory race, removed its staged file, and preserved the original; the manifest stayed at %s.\n' \
		"$(git -C "$root" rev-parse --short "$baseline")"
	cat "$run/directory-update.out"
}

run_backup_collision_case() {
	make_target backup-target
	rm -f "$marker"
	if PATH="$bin:$PATH" \
		AE_REAL_CP="$real_cp" \
		AE_REAL_MV="$real_mv" \
		AE_RACE_MODE=backup \
		AE_RACE_TARGET="$target/scripts/verify-repo.sh" \
		AE_RACE_MARKER="$marker" \
		bash "$update_script" "$target" > "$run/backup-update.out" 2>&1; then
		status=0
	else
		status=$?
	fi
	[[ -f "$marker" && "$status" -ne 0 ]] || { cat "$run/backup-update.out"; printf 'FAIL: UPDATE accepted a racing backup path\n'; exit 1; }
	cmp -s "$archive/templates/core/scripts/verify-repo.sh" "$target/scripts/verify-repo.sh" \
		|| { printf 'FAIL: UPDATE changed the original file after a backup collision\n'; exit 1; }
	competing=''
	for candidate in "$target/scripts/verify-repo.sh.local-"*; do
		[[ -f "$candidate" ]] || continue
		if grep -Fq 'racing backup file' "$candidate"; then competing="$candidate"; break; fi
	done
	[[ -n "$competing" ]] || { printf 'FAIL: UPDATE overwrote the racing backup file\n'; exit 1; }
	grep -Fq "TEMPLATE_REVISION=$(git -C "$root" rev-parse --short "$baseline")" "$target/.engineering-manifest" \
		|| { printf 'FAIL: UPDATE advanced the manifest after a backup collision\n'; exit 1; }
	printf 'PASS: UPDATE refused the backup collision and preserved both files; the manifest stayed at %s.\n' \
		"$(git -C "$root" rev-parse --short "$baseline")"
	cat "$run/backup-update.out"
}

run_case path
run_case inode
run_directory_case
run_backup_collision_case
rm -f "$marker"
run_recovery_case
