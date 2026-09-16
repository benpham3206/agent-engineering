#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$root/tests/generation/test-generate.sh"
bash -n "$root"/tooling/*.sh "$root"/templates/core/scripts/*.sh "$root/tests/generation/test-generate.sh"
git -C "$root" diff --check
