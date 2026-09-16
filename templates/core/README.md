# {{PROJECT_NAME}}

A language-neutral engineering repository generated from the Agent Engineering template.

## Start here

`README.md` is the front door. `AGENTS.md` defines how work is done. `SECURITY.md` defines the boundaries work must respect.

For project context, use this order:

1. Define success and constraints in `GOAL.md`.
2. Map capability dependencies in `ROADMAP.md` when a roadmap is useful.
3. Describe current system boundaries and invariants in `ARCHITECTURE.md`.
4. Record current evidence, the bottleneck, and the next step in `STATUS.md`.

## Operating model

When `ROADMAP.md` exists, the core read order is `GOAL.md -> ROADMAP.md + ARCHITECTURE.md -> STATUS.md`.

```text
GOAL.md
   ↓
ROADMAP.md + ARCHITECTURE.md
   ↓
STATUS.md
   ↓
current bottleneck, risk, or unknown
   ↓
RESEARCH_TASK / ARCHITECT_TASK / WORKER_TASK
   ↓
implementation or decision
   ↓
REVIEWER_TASK / SECURITY_REVIEWER_TASK when warranted
   ↓
evidence
   ↓
STATUS.md
   ↺
```

Research resolves unknowns. Architects own cross-cutting decisions. Workers implement bounded changes. Reviewers and security reviewers return findings. Evidence updates `STATUS.md`, which identifies the next useful move.

## Feature work

For a requested feature, treat the smallest missing working product behavior as the initial bottleneck unless evidence exposes a prerequisite. The request already authorizes pursuit of that bounded outcome. Do not add planning or approval steps unless the implementation introduces a material unknown, architecture change, authority increase, significant dependency or cost, or difficult-to-reverse choice. The detailed routing rule lives in `AGENTS.md`.

## Common commands

The repository exposes one stable interface regardless of language or framework:

```bash
make verify   # repository contract
make check    # optional project static/quality checks
make test     # optional deterministic tests
make eval     # optional smoke capability evaluation
make build    # project build/package
```

Project-specific implementations live under `scripts/project/`. CI calls them through `scripts/run-hook.sh`. Configure only the hooks that provide durable evidence or build behavior worth maintaining.

Generated folders are starting capabilities, not permanent requirements. Delete source, test, eval, experiment, extra documentation, artifact, configuration, CI, or convenience files when the project does not need them. Keep the operating, role, security, provenance, and verification backbone intact. Update this README when the project interface changes.

## Documentation map

| File | Question it answers |
| --- | --- |
| `GOAL.md` | What does success mean, and what constraints must hold? |
| `ROADMAP.md` | Which capabilities depend on which others? |
| `ARCHITECTURE.md` | How does the current system fit together? |
| `STATUS.md` | What is true now, what is blocked, and what happens next? |
| `AGENTS.md` | How should agents and contributors change it? |
| `CONTRIBUTING.md` | How are changes proposed, verified, and reviewed? |
| `SECURITY.md` | What are the default security expectations? |
| `docs/decisions/` | Why were durable engineering choices made? |
| `docs/interfaces/` | What stable contracts connect components? |

Create additional documentation only when these locations cannot express the needed knowledge clearly.

## Engineering sequence

Before adding complexity:

```text
Question the requirement
        ↓
Delete what is unnecessary
        ↓
Simplify what remains
        ↓
Build and verify the smallest useful capability
        ↓
Accelerate the feedback loop
        ↓
Automate stable repeated work
        ↓
Observe failures and bottlenecks
        ↓
Turn lessons into guardrails
```

Keep the system easy to understand and change. Add mature-system infrastructure only when current risk, load, or operations require it.

## Generated configuration

The exact template selection is recorded in `.engineering-manifest`.
