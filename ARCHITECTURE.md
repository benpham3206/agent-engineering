# Template system architecture

## Purpose

This repository composes one canonical, language-neutral project core with optional add-ons.

## Entry flows

```text
NEW
user-selected ecosystem starter
    ↓
runnable application
    ↓
ADOPT operating layer

ADOPT
existing application
    ↓
preflight conflicts
    ↓
Agent Engineering operating layer

FEATURE
requested product behavior
    ↓
current bottleneck or prerequisite
    ↓
narrowest role and change
    ↓
evidence
```

`NEW` does not encode a stack catalog. It executes the explicitly supplied ecosystem starter in an empty target and then delegates to the same adoption path as `ADOPT`. `FEATURE` is project behavior encoded in generated operating rules, not another generator command.

## Manifest generation flow

```text
project.conf
    ↓
validate as data
    ↓
templates/core
    +
add-ons (0..n)
    ↓
replace safe template tokens
    ↓
record .engineering-manifest
    ↓
verify generated repository
```

## Layers

### `templates/core/`

Owns the generated project's durable operating rules plus useful starter structure. Goal, architecture, current status, agent authority, security, role contracts, provenance, and verification form the permanent backbone. Starter source, test, eval, experiment, documentation, artifact, configuration, CI, roadmap, contribution, and Makefile structure may be removed when it no longer helps the project.

### `addons/`

Owns optional operating models and capabilities such as open-source collaboration, organization operations, deployment, observability, releases, performance, or security hardening.

### `standards/`

Owns template-maintainer doctrine. Generated repos receive the essential rules in their own project files rather than a copy of this standards directory.

### `tooling/`

Owns validation, composition, NEW, and ADOPT. Manifest content is treated as untrusted data and never executed. NEW executes only the starter argv explicitly supplied by the caller; ADOPT stages and preflights the operating layer before copying it into an existing project.

## Design rules

- One source of truth for the full core.
- Optional complexity stays optional.
- Verification protects durable invariants, not the original starter tree.
- Generated output looks like a normal project, not a template engine.
- The secure/correctness floor is universal; heavy hardening is opt-in.
- Verification scales with risk. Generated behavior is protected by six scenario contracts that cover distinct failure classes rather than many per-detail assertions.
- Worker-agent scope is narrow; cross-cutting changes escalate to architecture-aware agents.
- Project-independent lessons can move upstream into core or standards after they prove broadly useful.

## Invariants

1. Core generation succeeds with no add-on.
2. Add-ons do not leak their implementation directories into output.
3. Manifest values cannot execute shell code.
4. Generation never overwrites a non-empty target.
5. Release and deployment workflows remain opt-in.
6. Existing valid manifests continue to generate unless a deliberate contract change is documented and tested.
7. The same template revision plus manifest produces the same structure aside from intentional recorded metadata.
