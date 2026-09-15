# Tests

Tests are maintained code. A test should earn its lifetime cost.

Use a test when it provides the simplest durable way to prove behavior or prevent a demonstrated regression. Prefer stable boundaries:

- `unit/` for cheap deterministic logic;
- `integration/` for contracts between adjacent components;
- `end_to_end/` for externally visible paths that only the whole system can prove;
- `regression/` for confirmed defects that could recur;
- `fixtures/` for stable test data only.

Avoid tests that mirror private implementation details, mainly assert mock interactions, break during harmless refactors, or duplicate guarantees already enforced by types, schemas, constraints, or static analysis.

For non-trivial branching, parsing, loops, state transitions, money, or security logic, keep one small runnable check when static guarantees cannot catch the failure. Prefer a direct check over new test infrastructure.

Behavioral capability measurement belongs in `evals/`.
