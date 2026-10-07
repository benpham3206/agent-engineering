# Engineering standard

Engineer from first principles. Prefer the simplest reversible path that produces evidence. Project and harness instructions that are more specific win; this standard fills the gaps.

## Axioms

1. Reality is authoritative. Models, plans, documentations, and assumptions are approximations.
2. Engineering is achieving an intended outcome under constraints and reality. 
3. Every abstraction, dependency, and stateful component carries cost.
4. Uncertainty, consequence, and irreversibility determine required rigor.
5. Claims of correctness require evidence
6. Simpler solutions are preferred when they satisfy the same requirements.

## Principles

1. Scale rigor with consequence, uncertainty, and irreversibility.
2. Preserve traceability: intent → decisions → implementation → evidence.
3. Make assumptions, dependencies, and uncertainty explicit.
4. Prefer evidence over intuition. Measure before optimizing.
5. Minimize unnecessary complexity, state, boundaries, and dependencies.
6. Preserve reversibility. Delay irreversible decisions until justified.
7. Build fast. Fail early, locally, visibly, and recoverably.
8. Verify at every boundary and after every meaningful change.
9. Keep the system in a valid, usable state throughout.
10. Document decisions, not just outcomes.
11. Write docs anyone can follow to install, understand, and debug the system — no unstated machine paths, tools, or context. Docs point to the source instead of restating it; a fact that must be restated is generated or checked. When a decision changes, rewrite or remove the old text; history lives in git, not in the doc.

Document each phase in proportion to its rigor. Record decisions and evidence, not narration.

## Constraints before tools

Start with the project goal and the constraints that materially narrow the solution. Identify the required capabilities before choosing implementation tools.

Consider product scope, users and experience, platform and distribution, technical limits, security and trust, economics, operations, legal/compliance requirements, and team/time limits only when they are relevant.

Language, framework, libraries, storage, UI technology, third parties, infrastructure, pricing controls, deployment, and observability are downstream choices. Prefer the smallest set of choices that satisfies the current constraints. Revisit them only when evidence shows that a constraint or bottleneck changed.

## Quality

Excellent is the default. Timeless is the goal. Minimize scope, not craftsmanship. Favor clear, durable work that fits its ecosystem over fashionable, clever, or speculative machinery. For user-facing work, visual quality and accessibility are part of correctness.

Defend against both accidental complexity and hostile behavior. Use the simplest mechanism that preserves the required boundary, correctness, and recovery properties.

## Gate

Is the work low-consequence, low-uncertainty, and highly reversible — all three?

- **Yes:** fast path. Build → verify → iterate.
- **No:** Plan → Build → Refine. Refine routes back until the definition of done holds.

A clear outcome alone does not open the fast path. A clear but irreversible change (migration, publish, delete) still needs Plan steps 4 and 8.

## Plan

1. Define intent — why.
2. Define goal — what, and the definition of done.
3. Define metrics — how we know. Create tools to measure when needed.
4. Derive constraints — what cannot be violated.
5. Expose assumptions and dependencies — what depends on what, and why.
6. Reduce to first principles — what is actually necessary.
7. Derive architecture and frameworks — what the system should look like.
8. Trace consequences — 2nd, 3rd, nth-order effects. What is the worst that can happen, ×10?

## Build

1. Question requirements, boundaries, and dependencies.
2. Delete what does not need to exist. **Minimum code:** trace the real flow first, then stop at the first rung that satisfies the plan — not needed by the definition of done (skip it) → existing project code → standard library → native platform capability → an existing dependency already justified by the project → the smallest direct implementation → a new abstraction only after the boundary or repetition is real. Every line, file, dependency, abstraction, and service traces to a goal, constraint, or metric. Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility, correctness, explicit requests.
3. Integrate — remove unnecessary boundaries; preserve useful modularity (see [Modularity](#modularity)).
4. Simplify.
5. Implement:
   1. decompose — systems → subsystems → modules;
   2. define interfaces — inputs, outputs, contracts;
   3. sequence — dependency order, critical path;
   4. implement incrementally;
   5. integrate incrementally.
6. Verify — requirements, metrics, tests, edge cases, stress where failure matters. See [`verification.md`](verification.md) for the evidence hierarchy.
   - **Verify command:** each repo has one, named in the README; people, agents, and CI run the same one.
   - **Every surface:** name each place the change reaches — entry points, clients, environments and OSes you ship to, adapters, contracts and stored data at boundaries, reverse states (a way in needs a way out), docs — and say which applied. Working on the tested path but missing elsewhere is not done.
   - **Docs:** follow them from a fresh clone; every install, run, and debug step works as written.
   - **Mutation:** where tests guard non-trivial or consequential logic, mutation-test them. A surviving mutant is a missing test or dead code. Prefer the ecosystem tool (mutmut, Stryker, cargo-mutants, PIT); else hand-apply targeted mutants. Drop equivalent mutants and note why they are unobservable.
7. Optimize — **default: do not.** Optimize only when all three hold: a measured metric breaks a stated threshold; the target is the measured bottleneck (Refine 3); the code is verified and not slated for deletion. Otherwise ship the simple version and mark any known limit with a `ceiling:` comment (limit + upgrade path; `ponytail:` is an accepted alias).
8. Accelerate — shorten validated feedback loops.
9. Automate — only understood, stable processes.

## Refine

1. Measure — reproduce it; capture actual state.
2. Compare — expected vs. actual.
3. Identify the bottleneck — what currently limits the goal.
4. Diagnose — root cause. Each "why" is backed by evidence, not a guess. Stop early at a cause you can change that prevents the whole class of failure.
   - **Light** (fast-path work): ask why, up to 5 times.
   - **Heavy** (full-path work, a recurrence, or a light fix that failed): ask why, up to 10 times, then check the chain against the plan/spec — which definition of done (Plan 2), constraint (Plan 4), or assumption (Plan 5) let it through. If one did, route to Plan, not Build.
5. Refine — route back to Plan or Build.
6. Verify the correction. Where applicable, mutation-test it: the regression test must fail when the fix is reverted or mutated.
7. Clean up — dead code, obsolete components, temporary artifacts, stale docs.
8. Stress test the resulting system when warranted.
9. Repeat until the definition of done holds.

Do not optimize what should be deleted, automate what is not understood, or add process where experimentation is cheaper than analysis. [`evolution.md`](evolution.md) covers turning a fixed defect into a guardrail.

## Modularity

Split modules on reasons to change, not on size. A file, class, or function earns a split when it holds more than one responsibility or forces a reader to track unrelated concerns together. A long cohesive file is better than scattered fragments that share state.

Use metrics as tripwires for review, not as targets:

- branching complexity per function (cyclomatic or cognitive) above a project-set threshold requires simplification or a stated reason;
- file length above a project-set threshold requires a stated reason to remain whole;
- dependencies flow one direction; import cycles between modules are defects;
- in object-oriented code, inheritance deeper than two levels requires justification.

Set thresholds with the project's own tools through `scripts/project/check`. The standard does not pick a number; it requires that a number exists and is enforced.

## Outcome over activity

Judge work by externally verified outcomes under fixed constraints, not by activity. Agents may not redefine success, expand their own authority, or certify their own work.

Prefer the smallest reversible state change that reaches the goal. Creating code, files, tests, abstractions, API calls, research notes, or process does not count as progress by itself. Deletion and reversion count as progress when they leave the system closer to the requested state.

For research, answer the decision question, cite the evidence that matters, and expose material uncertainty. For external APIs and tools, verify the intended state rather than treating a successful call as success.

## Project lifecycle

Use these concerns when they become relevant; do not force every project to implement all of them on day one.

- **Bootstrap**. Manual work may exist when its purpose is to eliminate itself.
- **Build**. Create the smallest end-to-end capability.
- **Flow**. Understand inputs, outputs, locality, bottlenecks, queues, and resource pressure.
- **Verify**. Prove the acceptance criterion with the simplest reliable evidence.
- **Defend**. Constrain trust boundaries, permissions, secrets, and privileged actions.
- **Operate**. Make failure observable, bounded, recoverable, and reversible.
- **Expand**. Scale because measured pressure requires it.
- **Migrate**. Prefer incremental, reversible replacement over big-bang rewrites.
- **Maintain**. Assume dependencies, docs, tests, assumptions, and controls decay.
- **Evolve**. Convert failures into regressions, invariants, and guardrails.
- **Blueprint**. Upstream reusable lessons into templates, standards, and automation.

## Completion

A change is complete when the requested behavior exists, the acceptance criteria are proven with reliable evidence, every surface it reaches is accounted for, known failures are explicit, and the repository still describes reality.

## Related standards

Read the one that matches the task, when it applies:

- [verification.md](verification.md): choosing evidence; who may write tests.
- [testing.md](testing.md): which tests earn their cost.
- [evolution.md](evolution.md): turning a fixed defect into a guardrail.
- [documentation.md](documentation.md): which doc owns what; writing style.
- [security.md](security.md): trust boundaries, secrets, agent authority.
- [agents.md](agents.md): roles (architect, worker, reviewer, researcher).
- [flow.md](flow.md): queues, backpressure, scaling under load.
- [git.md](git.md), [ci-cd.md](ci-cd.md), [releases.md](releases.md), [evals.md](evals.md): short defaults for each area.
