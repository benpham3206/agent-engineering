# Evolution standard

## Learn from defects

For every confirmed defect:

1. reproduce the failure,
2. identify the root cause,
3. choose the simplest durable recurrence defense,
4. fix the root cause,
5. ask whether the defect reveals a broader invariant,
6. encode useful invariants in types, validation, constraints, static checks, contracts, tests, permissions, or architecture,
7. upstream project-independent guardrails into the reusable template when justified.

A fix repairs one instance. A guardrail makes the class of failure harder to reintroduce.

## Capability quality

A capability may mature through:

- `absent`. No implementation.
- `works`. Succeeds on the intended path.
- `reliable`. Repeatably succeeds within defined conditions.
- `observable`. Behavior and failures can be diagnosed from evidence.
- `efficient`. Meets stated resource, cost, latency, or throughput expectations.
- `resilient`. Handles expected failure and recovery without unacceptable impact.

Not every capability must reach `resilient`. The project's goal and risk determine the required level.

## Maintenance and decay

Assume that dependencies, documentation, tests, evals, security assumptions, benchmarks, credentials, and operational procedures become stale. Maintenance work should remove obsolete material as readily as it adds new material.

## Migration

Prefer reversible migration: run old and new paths in parallel when necessary, verify the replacement, shift responsibility incrementally, then remove the old path. Avoid big-bang rewrites without evidence that incremental replacement is impossible.
