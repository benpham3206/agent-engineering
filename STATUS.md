# Status

Keep this file current and short.

## Current goal

This repository uses its own backbone (dogfood) and downstream repositories reference it. See `GOAL.md`.

## Working

- NEW and ADOPT generate projects that pass `scripts/verify-repo.sh` (`make verify`).
- UPDATE (`tooling/update.sh`) brings a managed project to the current templates, or refuses without writing when a managed file was changed locally.
- This repository passes its own `scripts/verify-repo.sh`, and `tooling/verify-self.sh` fails on drift between its generic copies, Dependabot config, or `actions/checkout` references and the reusable sources.
- Vendored ponytail, pstack, and thermos sync daily through a reviewed PR (`tooling/sync-vendor.sh`).
- Dependabot proposes GitHub Actions updates as reviewed PRs, here and in generated projects.
- `main` is protected by a ruleset (`tooling/protect-main.sh`).

## Failing or missing

None known.

## Current bottleneck

None demonstrated. Take the next change from observed pressure.

## Security and trust risks

Vendored agent instructions come from upstream repositories; each sync is a PR for review.

## Active migration

None.

## Evidence snapshot

| Acceptance criterion or risk | Evidence | Result |
| --- | --- | --- |
| Repository structure is valid | `scripts/verify-repo.sh` | PASS |
| Generated and adopted projects | `make verify` | PASS |

## Next smallest step

Run `tooling/update.sh --check` against each downstream project.
