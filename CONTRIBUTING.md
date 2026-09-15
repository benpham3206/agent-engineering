# Contributing

## Before implementation

Read `ARCHITECTURE.md`, the relevant `standards/` files, and the generation tests. Decide whether the behavior belongs in core, one add-on, tooling, or the manifest contract.

Use the smallest layer that can express the behavior without duplication.

## Development flow

1. Create a short-lived branch from `main`.
2. For generated behavior, extend the smallest relevant scenario contract. Add a new contract only when the failure class is genuinely distinct.
3. Confirm the contract fails for the intended missing behavior.
4. Implement the smallest change.
5. Prove the change with the simplest reliable evidence, then `make verify`.
6. Generate the affected example and inspect the output.
7. Update docs when documented behavior changed.
8. Commit a coherent verified unit.

## Local evidence

Prove the change with the simplest reliable evidence. Generated behavior uses the generation suite because it is cheap and compounding. Finish with:

```bash
make verify
```

To inspect an add-on combination manually, copy an example manifest, set `OUTPUT_DIR` to an empty temporary path, and run `bash tooling/generate.sh <config>`.

## Layering rules

- Never copy the full core into an add-on.
- Keep public-only files out of the organization add-on.
- Keep internal ownership/operations out of the open-source add-on.
- Keep deployment, releases, observability, benchmarks, performance, and hardening optional unless they become true universal requirements.
- Generated repos must not contain `templates/`, `addons/`, `standards/`, or `tooling/`.

## Pull requests

Use `.github/pull_request_template.md`. Explain the generated behavior, affected layer, verification, compatibility, risk, and whether the change could have been smaller or simpler.

## Community conduct

Treat contributors, reviewers, users, and maintainers with professional respect. Harassment, discrimination, threats, targeted abuse, or repeated personal attacks are not acceptable. Keep technical disagreement focused on the work and evidence. Report serious conduct or security-sensitive concerns through the repository's private reporting path.
