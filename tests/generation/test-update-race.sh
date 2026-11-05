#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
baseline="$(git -C "$root" rev-parse '9116d0d^')"
run="$(mktemp -d)"
trap 'rm -rf "$run"' EXIT

target="$run/target"
archive="$run/archive"
bin="$run/bin"
mkdir -p "$target" "$archive" "$bin"
target="$(cd "$target" && pwd -P)"
git -C "$root" archive "$baseline" templates/core TEMPLATE_VERSION | tar -x -C "$archive"

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

real_cp="$(command -v cp)"
cat > "$bin/cp" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -eq 3 && "$1" == "-p" && "$2" == "$AE_RACE_TARGET" && ! -e "$AE_RACE_MARKER" ]]; then
	"$AE_REAL_CP" "$@"
	printf '\nlocal edit inserted after preflight\n' >> "$AE_RACE_TARGET"
	: > "$AE_RACE_MARKER"
	exit 0
fi
exec "$AE_REAL_CP" "$@"
EOF
chmod +x "$bin/cp"

if PATH="$bin:$PATH" \
	AE_REAL_CP="$real_cp" \
	AE_RACE_TARGET="$target/scripts/verify-repo.sh" \
	AE_RACE_MARKER="$run/race-injected" \
	bash "$root/tooling/update.sh" "$target" > "$run/update.out" 2>&1; then
	status=0
else
	status=$?
fi

[[ -f "$run/race-injected" ]] || { cat "$run/update.out"; printf 'FAIL: race injection did not run\n'; exit 1; }
if [[ "$status" -eq 0 ]]; then
	if grep -Fq 'local edit inserted after preflight' "$target/scripts/verify-repo.sh"; then
		printf 'FAIL: UPDATE accepted the late edit and replaced it\n'
	else
		printf 'FAIL: UPDATE accepted the late edit and removed it\n'
	fi
	exit 1
fi
grep -Fq 'local edit inserted after preflight' "$target/scripts/verify-repo.sh" \
	|| { printf 'FAIL: UPDATE refused but did not preserve the late edit\n'; exit 1; }
grep -Fq "TEMPLATE_REVISION=$(git -C "$root" rev-parse --short "$baseline")" "$target/.engineering-manifest" \
	|| { printf 'FAIL: UPDATE advanced the manifest after refusing the late edit\n'; exit 1; }
grep -Fq 'update stopped at scripts/verify-repo.sh' "$run/update.out" \
	|| { cat "$run/update.out"; printf 'FAIL: UPDATE did not report the managed file it refused\n'; exit 1; }
printf 'PASS: UPDATE refused and preserved the late edit; the manifest stayed at %s.\n' \
	"$(git -C "$root" rev-parse --short "$baseline")"
cat "$run/update.out"
