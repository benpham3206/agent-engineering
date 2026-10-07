#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$root/tests/generation/test-generate.sh"
bash -n "$root"/tooling/*.sh "$root"/templates/core/scripts/*.sh "$root/tests/generation/test-generate.sh"
git -C "$root" diff --check

# Dogfood: this repository passes the check it generates, and its generic backbone files match the templates.
# GOAL, STATUS, ARCHITECTURE, AGENTS, and SECURITY hold this repository's own content.
bash "$root/scripts/verify-repo.sh"
drift=0
while IFS= read -r path; do
  case "$path" in ''|'#'*|GOAL.md|STATUS.md|ARCHITECTURE.md|AGENTS.md|SECURITY.md) continue ;; esac
  if ! cmp -s "$root/templates/core/$path" "$root/$path"; then
    printf 'dogfood drift: %s differs from templates/core/%s; copy the template over it\n' "$path" "$path" >&2
    drift=1
  fi
done < "$root/templates/core/scripts/backbone.list"
if ! cmp -s "$root/templates/core/.github/dependabot.yml" "$root/.github/dependabot.yml"; then
  printf 'dogfood drift: .github/dependabot.yml differs from templates/core/.github/dependabot.yml; copy the template over it\n' >&2
  drift=1
fi

# Dependabot proposes newer actions; this proves every tracked copy agrees with root CI before review merges it.
checkout_ref='actions/checkout@[^[:space:]"'\'']+'
canonical="$(git -C "$root" grep -h -o -E "$checkout_ref" -- .github/workflows/ci.yml | head -n 1)" \
  || { printf 'checkout drift: no actions/checkout reference in .github/workflows/ci.yml\n' >&2; exit 1; }
while IFS= read -r hit; do
  if [ "${hit#*:}" != "$canonical" ]; then
    printf 'checkout drift: %s uses %s; .github/workflows/ci.yml uses %s\n' "${hit%%:*}" "${hit#*:}" "$canonical" >&2
    drift=1
  fi
done < <(git -C "$root" grep -o -E "$checkout_ref" -- '*.yml' '*.yaml' || true)
exit "$drift"
