# Engineering standard

## Constraints before tools

Start with the project goal and the constraints that materially narrow the solution. Identify the required capabilities before choosing implementation tools.

Consider product scope, users and experience, platform and distribution, technical limits, security and trust, economics, operations, legal/compliance requirements, and team/time limits only when they are relevant.

Language, framework, libraries, storage, UI technology, third parties, infrastructure, pricing controls, deployment, and observability are downstream choices. Prefer the smallest set of choices that satisfies the current constraints. Revisit them only when evidence shows that a constraint or bottleneck changed.

## Quality

Excellent is the default. Timeless is the goal. Minimize scope, not craftsmanship. Favor clear, durable work that fits its ecosystem over fashionable, clever, or speculative machinery. For user-facing work, visual quality and accessibility are part of correctness.

Defend against both accidental complexity and hostile behavior. Use the simplest mechanism that preserves the required boundary, correctness, and recovery properties.

## Default sequence

Before adding code or process, use this order:

1. **Question**. Verify the requirement, constraint, and success condition.
2. **Delete**. Remove unnecessary requirements, code, files, steps, dependencies, and abstractions.
3. **Simplify**. Choose the smallest understandable design that satisfies what remains.
4. **Accelerate**. Shorten build, test, eval, debug, and review feedback loops.
5. **Automate**. Automate only stable work that survived the earlier steps.

Do not automate a process merely because automation is easy.

## Code quality

Prefer, in order:

1. no code,
2. existing project code,
3. the standard library,
4. a native platform capability,
5. an existing dependency already justified by the project,
6. one direct line or the smallest direct implementation,
7. a new abstraction only after the boundary or repetition is real.

Stop at the first option that works. Do not add speculative abstractions, configuration, or starter structure for possible future needs. If an existing file can own the behavior, change that file instead of creating another one.

Every line, file, dependency, abstraction, and service must earn its existence. Prefer obvious code over clever code, local behavior over unnecessary distribution, and small diffs over broad rewrites. Keep generated starter structure only while it helps the real project. Verification protects durable invariants, not the shape of the initial scaffold.

Security, trust-boundary validation, accessibility, data-loss protection, and correctness are not optional simplifications.

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

A change is complete when the requested behavior exists, the acceptance criteria are proven with reliable evidence, known failures are explicit, and the repository still describes reality.
