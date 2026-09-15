# Contributing

## Before changing code

Read `GOAL.md`, then `ROADMAP.md` when it exists, then `ARCHITECTURE.md`, then `STATUS.md`. Read applicable decision or interface docs before changing a stable boundary.

Ask:

1. Is the requirement correct?
2. Can unnecessary work be deleted?
3. Can the remaining change be simpler?
4. What is the smallest observable increment?
5. What is the simplest reliable evidence that proves it works?

## Scope

Use short-lived branches from `main`. Keep each change small enough that a reviewer can understand the behavior, evidence, and risk without reconstructing unrelated work.

Do not mix feature work with unrelated refactors, dependency upgrades, architecture changes, or formatting sweeps.

## Evidence

Verification effort scales with risk. Tests are one option, not the default ritual.

Prefer evidence that compounds across future changes: compiler and type guarantees, schemas and constraints, static analysis, stable contracts, public-interface checks, security invariants, and regressions for demonstrated defects.

Do not add a test merely because code changed. Use a test when it is the simplest durable proof or recurrence defense.

The stable commands are:

```bash
make verify
make check
make test
make eval
```

`make verify` checks the repository contract. Project-specific implementations live under `scripts/project/`. Run the other hooks when they are relevant to the changed boundary and configured by the project.

## Documentation updates

Update documentation when the change makes documented reality false:

- interface change -> `docs/interfaces/`
- architecture or invariant change -> `ARCHITECTURE.md` and possibly an ADR
- durable engineering decision -> `docs/decisions/`
- operating procedure change -> `docs/operations/`
- project state, bottleneck, or risk change -> `STATUS.md`

Do not create documentation churn as proof of completeness.

## Commits

Prefer coherent verified commits. A useful format is:

```text
<type>(<area>): <imperative summary>
```

Common types include `feat`, `fix`, `test`, `eval`, `docs`, `refactor`, `build`, `ci`, and `security`.

## Pull requests

Use `.github/pull_request_template.md`. State the goal, scope, acceptance criteria, evidence, risk, security impact, documentation impact, and rollback when relevant.

## Community conduct

Treat contributors, reviewers, users, and maintainers with professional respect. Harassment, discrimination, threats, targeted abuse, or repeated personal attacks are not acceptable. Keep technical disagreement focused on the work, trade-offs, and evidence. Report serious conduct or security-sensitive concerns through the project's private reporting path.
