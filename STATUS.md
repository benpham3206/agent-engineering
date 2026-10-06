# Status

Keep this file current and short.

## Current goal

This repository uses its own backbone (dogfood) and downstream repositories reference it. See `GOAL.md`.

## Working

- NEW and ADOPT generate projects that pass `scripts/verify-repo.sh` (`make verify`).
- This repository passes its own `scripts/verify-repo.sh`.
- Vendored ponytail, pstack, and thermos sync daily through a reviewed PR (`tooling/sync-vendor.sh`).
- `main` is protected by a ruleset (`tooling/protect-main.sh`).

## Failing or missing

- A project made with ADOPT gets no later template changes; there is no update command yet.
- The first automated vendor sync PR has not run since its CI dispatch was added.

## Current bottleneck

The missing update path for adopted projects.

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

Decide whether ADOPT needs an update command, with chasm as the first user.
