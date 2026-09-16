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

## Start, adopt, or extend a project

Agent Engineering has three fast paths:

- **NEW** starts with the language, framework, and libraries already chosen by the user or architect. It runs that ecosystem's native starter in an empty target, then adds the Agent Engineering operating layer. Agent Engineering does not maintain a stack registry or choose a framework by default.
- **ADOPT** adds the operating layer to an existing project without restructuring application code or replacing its README. An existing `AGENTS.md` is preserved by appending it as a "Project rules" section of the generated one; a `Makefile` is added only when the project has none. Other conflicting Agent Engineering control files fail before anything is copied.
- **FEATURE** treats working product behavior as the initial bottleneck for the requested feature. Bounded work can proceed directly; research, architecture, security review, or renewed approval are used only when the feature exposes a material reason to escalate.

NEW accepts the native starter as ordinary command arguments and runs it in the target directory. For example:

```bash
tooling/new.sh my-app ../my-app -- npm create vite@latest . -- --template react-ts
```

The starter must be configured to initialize the current directory (`.`). Agent Engineering executes the command exactly as supplied; it does not parse or `eval` a command string.

To adopt an existing project:

```bash
tooling/adopt.sh my-app ../existing-app
```

The existing manifest-based generator remains available when you want the full language-neutral starter tree rather than an ecosystem-native application scaffold.

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

## Included agent tools

The repository also carries three opt-in upstream tools. They are repository assets and do not enter generated projects unless a maintainer integrates them explicitly.

- [`skills/ponytail`](skills/ponytail/) contains the standalone Ponytail skill from [`DietrichGebert/ponytail`](https://github.com/DietrichGebert/ponytail), imported at `e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156` under the MIT license.
- [`plugins/pstack`](plugins/pstack/) contains the complete pstack Cursor plugin from [`cursor/plugins`](https://github.com/cursor/plugins/tree/main/pstack), imported at `c1c0a32802223f4be824112dd83d33ad29a8b26c` under the MIT license.
- [`plugins/thermos`](plugins/thermos/) contains the complete Thermos Cursor plugin from [`cursor/plugins`](https://github.com/cursor/plugins/tree/main/thermos), imported at the same revision under the MIT license.

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
├── skills/                  # standalone upstream agent skills
├── plugins/                 # complete upstream agent plugin packages
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
