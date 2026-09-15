# Testing standard

Tests are one verification tool. Use them when they provide the simplest durable way to prove behavior or prevent a demonstrated regression.

## High-value tests

Prefer tests at stable boundaries:

- deterministic logic that is cheap to exercise;
- public contracts and externally visible behavior;
- integration points where failures cross components;
- regressions for real defects that could recur;
- security invariants that should never be violated.

## Low-value tests

Avoid tests that:

- mirror private implementation details;
- mainly assert mock interactions;
- break during harmless refactors;
- duplicate guarantees already enforced by types, schemas, constraints, or static analysis;
- cost more to maintain than the failure they protect against.

## Defects

When a test is the right recurrence defense, reproduce the original failure before the fix when practical. The test should fail for the original reason and pass because the root cause was corrected.

For stochastic systems, use evals with enough samples and explicit thresholds. One successful run is not reliability evidence.

See `verification.md` for the project-wide evidence hierarchy.
