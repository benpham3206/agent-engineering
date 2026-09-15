# Project hooks

This directory is the stable boundary between repository automation and the project's chosen implementation stack.

Create executable hooks only when the project has evidence or build behavior worth maintaining:

```text
scripts/project/check
scripts/project/test
scripts/project/eval
scripts/project/build
scripts/project/deploy
```

Contracts:

- `check` runs cheap static, type, schema, lint, or configuration checks suitable for normal CI.
- `test` runs deterministic tests worth paying for on normal CI. Keep expensive suites elsewhere.
- `eval <mode>` runs behavioral evaluation. Use `smoke` for cheap CI evidence and `full` for slower release, scheduled, or risk-specific evaluation.
- `build` produces the releasable artifact or proves that the project builds.
- `deploy <environment>` deploys the exact checked-out revision and fails on deployment errors.

Do not create a hook that returns success without doing its named work. If a concern does not exist yet, leave the hook absent. The wrapper reports it as not configured.

Examples:

```bash
# Python static evidence
python -m ruff check . && python -m mypy src

# Node deterministic tests that are cheap enough for normal CI
npm test

# Rust build evidence
cargo build --release
```

These are examples only. The template does not choose a stack.
