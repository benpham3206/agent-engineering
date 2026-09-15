# Verification standard

## Rule

Verification effort scales with risk. Prove the acceptance criterion with the simplest reliable evidence.

Do not add a test merely because code changed. Tests are maintained code. They need to earn their lifetime cost.

Prefer evidence that compounds across future changes:

1. compiler and type guarantees;
2. schemas, constraints, and static analysis;
3. direct execution of the changed behavior;
4. stable contract or public-interface checks;
5. regression checks for demonstrated failures;
6. integration checks where the risk is between components;
7. end-to-end checks when only the whole system can prove the behavior;
8. canary or production observation when real traffic is the useful evidence;
9. load, failure, security, or adversarial evaluation when those are the actual risks.

Stop at the first level that proves the property. Higher-cost verification is not more rigorous when a simpler invariant already proves the same thing.

For non-trivial branching, parsing, loops, state transitions, money, or security logic, leave one small runnable check when no cheaper compiler, type, schema, constraint, or static rule would catch the break. Prefer one direct check over a framework, fixture set, or per-function suite.

## Agent responsibilities

Architects own project-wide verification architecture, shared invariants, and new verification frameworks. When a new test is justified, the architect or maintainer owns that test work separately from the implementation worker.

Workers run existing evidence inside their assigned boundary. They do not write or modify tests, create a new verification framework, build a broad test harness, or add cross-cutting policy to finish a local task.

Reviewers check whether the evidence proves the acceptance criteria. They do not write or modify code or tests, and they do not reward test count.

Security reviewers require stronger evidence when a change affects authority, trust boundaries, secrets, destructive actions, or untrusted input.

## Defects

A confirmed defect should leave the simplest durable recurrence defense that fits the root cause. That may be a type rule, validation, constraint, static check, contract, regression test, permission boundary, or architectural invariant.

Reproduce the defect when practical. Fix the root cause. Prefer eliminating a class of invalid states over adding many examples of the same failure.

## CI

Keep always-on checks cheap and broadly useful. Put slower or risk-specific checks behind the project hooks or release path that needs them.

The repository contract is `make verify`. Project-specific `check`, `test`, and `eval` hooks are optional. Configure them only when they provide durable evidence worth maintaining.
