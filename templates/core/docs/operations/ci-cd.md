# CI/CD operating model

The generated core keeps CI language-neutral by calling repository-owned hooks instead of embedding language-specific commands in workflows.

## Base gates

- `ci.yml`: repository contract, static/project checks, tests, and smoke evals.
- `evals.yml`: scheduled/manual full behavioral evaluations.
- `security.yml`: base repository and dependency/security checks.

Release and deployment workflows are intentionally optional. Add them through the `releases` and `deployment` template add-ons when the project actually needs those capabilities.

## Hook contract

```text
scripts/run-hook.sh check
scripts/run-hook.sh test
scripts/run-hook.sh eval smoke
scripts/run-hook.sh eval full
scripts/run-hook.sh build
scripts/run-hook.sh deploy <environment>
```

Project-specific implementations belong under `scripts/project/`.

## Branch protection

Protect `main` and require the base CI checks that exist for the project. Add required release, benchmark, performance, or security-hardening checks only after those capabilities are enabled and stable.

## Deployment safety

When the deployment add-on is enabled, deployment must go through the required deploy hook. The wrapper must fail when no deploy implementation is configured. A production deployment mechanism must define how to identify and restore a previous known-good artifact.
