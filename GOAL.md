# Goal

## Objective

Give any repository a small, verified operating layer for coding agents: one engineering policy, role boundaries, state files, and checks. Build it with `tooling/generate.sh` (NEW) or `tooling/adopt.sh` (ADOPT), and bring it forward with `tooling/update.sh` (UPDATE).

## Success conditions

- A generated project and an adopted project each pass their own `scripts/verify-repo.sh`. Evidence: `make verify`.
- This repository passes the same `scripts/verify-repo.sh`, and its copies of the generic backbone files match `templates/core/`. Evidence: `make verify`.
- Downstream repositories read the policy from `standards/engineering.md` instead of copying it. Evidence: their `AGENTS.md` links to it, or they keep a pinned copy that a sync job updates (app-workshop).

## Inputs

A project name, an optional manifest (`schema/`), and an existing directory for ADOPT.

## Outputs

The backbone files in `templates/core/scripts/backbone.list`, a `.engineering-manifest`, and any selected add-ons.

## Constraints

Language-neutral. No runtime dependency beyond bash, git, and the tools each check names. The invariants in `ARCHITECTURE.md` hold.

## Must not break

Generation and adoption never overwrite existing files. Existing valid manifests keep generating.

## Non-goals

Language or framework starters (a downstream layer, such as app-workshop for Apple apps, owns those). Hosting agents or models.
