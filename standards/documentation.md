# Documentation standard

## Purpose

Documentation should answer questions the code cannot answer efficiently. Keep it close to the decision or boundary it explains, and delete it when it no longer reflects reality.

## Hierarchy

- `README.md`: front door; what this is, how to start, how to verify, and where to look next.
- `AGENTS.md`: rules governing how work moves through the project.
- `SECURITY.md`: boundaries and secure defaults that apply across the project.
- `GOAL.md`: success conditions, constraints, and non-goals.
- `ROADMAP.md`: capability dependencies and required quality levels when a roadmap is useful.
- `ARCHITECTURE.md`: current system map, boundaries, contracts, invariants, and trust boundaries.
- `STATUS.md`: current evidence, bottleneck, risks, and next step.
- `CONTRIBUTING.md`: contribution workflow and conduct.
- `docs/decisions/`: expensive-to-rediscover decisions and revisit conditions.
- `docs/interfaces/`: stable cross-component contracts.
- `docs/systems/`: subsystem explanations only when the code and architecture map are insufficient.
- `docs/operations/`: operational procedures only when the project has operational responsibility.

For project context, read `GOAL.md`, then `ROADMAP.md` when it exists, then `ARCHITECTURE.md`, then `STATUS.md`. Durable decisions and interface documents add detail only where the current boundary needs it.

Do not create a new document when an existing document is the natural home.

## Writing style

Use plain words, sentence-case headings, active voice, and one idea per sentence. Cut filler, vague claims, decorative punctuation, forced metaphors, and AI-style vocabulary when a concrete word says the same thing. If a sentence could appear unchanged in another project's docs, make it specific or delete it.

## Code and comments

Prefer clear names, small functions, explicit types/contracts, and obvious control flow. Comments explain why, invariants, hazards, compatibility constraints, or surprising trade-offs. Do not narrate syntax.

## Change rule

A code change updates documentation only when it changes a documented behavior, interface, decision, architecture boundary, operating procedure, or project status. Documentation churn is not evidence of completeness.
