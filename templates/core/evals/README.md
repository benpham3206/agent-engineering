# Evaluations

Evaluations answer one question: can the agent or system accomplish the intended capability at the required quality?

Suggested organization:

- `tasks/` contains atomic capability evaluations.
- `scenarios/` contains multi-step or environmental scenarios.
- `benchmarks/` contains fixed comparative suites and baselines.
- `results/` contains schemas or curated summaries. Raw runs usually belong under `artifacts/`.

Useful metrics include success rate, reliability, latency, cost, resource use, tool calls, retries, recovery, and failure categories.

For stochastic behavior, define sample size and acceptance thresholds. A single successful run is not evidence of reliability.

Projects using the `security-hardening` add-on also receive `evals/adversarial/` for trust, permission, and abuse-resistance scenarios.
