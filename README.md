# Agent Engineering

A self-generating, language-neutral repository standard for building software with humans and coding agents without letting complexity grow faster than the project.

## What it generates

```text
templates/core
      +
optional add-ons
      ↓
generated project
```

Generated projects get a compact set of goal, architecture, status, role, verification, and security files. Starter tests, evals, CI hooks, docs, and other capabilities can be removed when they stop earning their place.

Generated repositories do **not** contain this template system's `addons/`, `standards/`, or generator internals.

## Generate a project

Copy the example manifest:

```bash
cp project.example.conf project.conf
```

Set the project name, optional add-ons, and output directory:

```text
PROJECT_NAME=my-agent
ADDONS=open-source,releases,benchmarks
OUTPUT_DIR=dist/my-agent
```

Generate:

```bash
make validate CONFIG=project.conf
make generate CONFIG=project.conf
```

The generator rejects unknown add-ons, unknown or duplicate manifest keys, unsafe project names, executable manifest content, and non-empty output targets.

Shell tooling targets Linux, macOS system Bash 3.2, and Git Bash/MSYS2 on Windows. Native PowerShell and `cmd.exe` are not part of the shell contract. In Git Bash, use POSIX drive paths such as `/d/work/project`; `D:/work/project` is rejected instead of being treated as repository-relative.

The generated tree is a starting point, not a permanent folder contract. Projects may delete starter areas when they no longer earn their place, including `src/`, tests, evals, experiments, docs, config, artifacts, and CI files. Repository verification protects the operating and security backbone instead of the original scaffold.

## Add-ons

Add capabilities only when the project needs them:

- `open-source`. License, support, governance, and public contribution docs.
- `organization`. Ownership, service metadata, RFCs, runbooks, incidents, and operations.
- `deployment`. Deploy workflow and rollback guidance.
- `releases`. Versioning, changelog, release workflow.
- `observability`. Telemetry and operations guidance.
- `benchmarks`. Benchmark workspace and workflow.
- `performance`. Performance eval and budget starter files.
- `security-hardening`. Threat model, adversarial evals, stronger security guidance.

Example:

```text
PROJECT_NAME=internal-agent
ADDONS=organization,deployment,observability,performance,security-hardening
OUTPUT_DIR=dist/internal-agent
```

## Engineering model

The template encodes five restraints before automation:

```text
Question → Delete → Simplify → Accelerate → Automate
```

And one evolution loop:

```text
failure → reproduce → root cause → recurrence defense → guardrail → reusable template improvement
```

Workers stay inside bounded tasks. Architects own cross-cutting decisions. Reviewers and security reviewers return findings without modifying code. Researchers propose evidence-backed fixes for architect review and user decision. Canonical role-assignment templates live in `templates/core/`.

Verification is evidence-driven. Tests are optional tools. Keep them only when they provide the simplest durable proof or recurrence defense.

The goal is not maximum process. Start with a secure minimum. Add infrastructure only when real pressure, risk, or scale requires it.

## Repository map

```text
agent-engineering/
├── templates/core/          # canonical generated-project foundation
├── addons/                  # optional operating models and capabilities
├── standards/               # engineering doctrine
├── tooling/                 # safe validation + generation
├── schema/                  # manifest contract
├── examples/                # example manifests
└── tests/generation/        # six generator scenario contracts
```

## Standards

Start with:

- `standards/engineering.md`. Constraints first, deletion, simplicity, lifecycle, completion.
- `standards/agents.md`. Role boundaries and assignment templates.
- `standards/flow.md`. Bottlenecks, locality, backpressure, scaling.
- `standards/evolution.md`. How failures become lasting protections and template improvements.
- `standards/documentation.md`. Documentation hierarchy and comments.
- `standards/verification.md`. Simple reliable evidence and risk-scaled checks.
- `standards/testing.md` and `standards/security.md`. Tests as one evidence tool and trust boundaries.

## Template development

Run:

```bash
make test
make verify
```

Changes to generated behavior should extend the smallest relevant contract in `tests/generation/test-generate.sh`. Add a new contract only for a distinct failure class that existing contracts cannot express clearly.

See `ARCHITECTURE.md`, `AGENTS.md`, and `CONTRIBUTING.md` before changing the template system.
