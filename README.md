# Agent Engineering

Agent Engineering is a way to build software with coding agents without letting complexity grow faster than the project.

Agent Engineering owns the project policy, constraints, authority, state, architecture, security boundaries, and repository setup. It works with any agent host: the operating files are plain Markdown and shell, and an agent follows them directly.

## Start here

If you are an agent working in this repository, follow this sequence before you modify files:

1. Read this `README.md`.
2. Read [`AGENTS.md`](AGENTS.md). Treat it as the repository's operating rules.
3. Pick the path below (NEW, ADOPT, UPDATE, or FEATURE) that matches the task.
4. Run `make verify` before calling the work done.

## How Agent Engineering fits

Agent Engineering defines the environment in which work happens:

- Project policy defines constraints and quality standards.
- Authority defines what each agent may do.
- State records goals, architecture, status, roles, verification, and security decisions.
- Repository setup provides the files and checks that keep the project understandable.

## NEW, ADOPT, UPDATE, and FEATURE

Agent Engineering has four paths for project work:

- **NEW** starts with the language, framework, and libraries chosen by the user or architect. It runs the ecosystem's native starter in an empty target, then adds the Agent Engineering operating layer.
- **ADOPT** adds the operating layer to an existing project without restructuring application code or replacing its README. It merges an existing `AGENTS.md`, adds a `Makefile` only when the project has none, and fails before copying if another control file conflicts.
- **UPDATE** reconciles an already managed project with a newer operating layer. It is not a re-run of ADOPT.
- **FEATURE** treats working product behavior as the initial bottleneck for a requested feature. Escalate to research, architecture, or security review only when the feature exposes a material reason.

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

NEW accepts the native starter as ordinary command arguments and runs it in the target directory. For example:

```bash
tooling/new.sh my-app ../my-app -- npm create vite@latest . -- --template react-ts
```

The starter must initialize the current directory (`.`). Agent Engineering executes the command exactly as supplied. It does not parse or `eval` a command string.

To adopt an existing project:

```bash
tooling/adopt.sh my-app ../existing-app
```

To update a managed project to this checkout's committed templates (check first; `--check` writes nothing):

```bash
tooling/update.sh --check ../existing-project
tooling/update.sh ../existing-project
```

UPDATE owns the files in `templates/core/scripts/backbone.list` except `GOAL.md`, `STATUS.md`, `ARCHITECTURE.md`, and `SECURITY.md`, and only the template prefix of `AGENTS.md`; project rules after that prefix are kept byte for byte. It never touches the project-owned files, `README.md`, `Makefile`, or anything else. It compares each file with the template at the manifest's `TEMPLATE_REVISION`, accepting LF or CRLF line endings. It replaces a file only when the file still matches that template, and refuses the whole update without writing when any file was changed locally. It refuses rather than merges. Add-on files and removals of files dropped from the template are out of scope.

The existing manifest-based generator remains available when you want the full language-neutral starter tree rather than an ecosystem-native application scaffold.

## Generate directly

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

The repository also carries one opt-in upstream tool. It is a repository asset and does not enter generated projects unless a maintainer integrates it explicitly.

- [`plugins/thermos`](plugins/thermos/): the complete Thermos Cursor plugin from [`cursor/plugins`](https://github.com/cursor/plugins/tree/main/thermos) (MIT), tracked at `main`.

[`tooling/vendor.lock`](tooling/vendor.lock) records its exact upstream commit. Every day, [`.github/workflows/sync-vendor.yml`](.github/workflows/sync-vendor.yml) runs [`tooling/sync-vendor.sh`](tooling/sync-vendor.sh) and `make verify`, then opens or updates one PR when upstream changed and starts CI on it (the required checks need a CI run). These files are agent instructions, so review the upstream diff before merging. To sync by hand, run `bash tooling/sync-vendor.sh`.

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
├── plugins/                 # complete upstream agent plugin packages
├── standards/               # engineering doctrine
├── tooling/                 # safe validation + generation
├── schema/                  # manifest contract
├── examples/                # example manifests
└── tests/generation/        # eight generator scenario contracts
```

The repository uses its own backbone: `GOAL.md`, `STATUS.md`, the `*_TASK.md` role files, and `scripts/` at the root. `make verify` runs `scripts/verify-repo.sh` here and fails when a root copy of a generic backbone file differs from `templates/core/`.

## Standards

Start with:

- `standards/engineering.md`. Constraints first, deletion, simplicity, lifecycle, completion.
- `standards/agents.md`. Role boundaries and assignment templates.
- `standards/flow.md`. Bottlenecks, locality, backpressure, scaling.
- `standards/evolution.md`. How failures become lasting protections and template improvements.
- `standards/documentation.md`. Documentation hierarchy and comments.
- `standards/verification.md`. Simple reliable evidence and risk-scaled checks.
- `standards/testing.md` and `standards/security.md`. Tests as one evidence tool and trust boundaries.

## Development

Run:

```bash
make test
make verify
```

Changes to generated behavior should extend the smallest relevant contract in `tests/generation/test-generate.sh`. Add a new contract only for a distinct failure class that existing contracts cannot express clearly.

See `ARCHITECTURE.md`, `AGENTS.md`, and `CONTRIBUTING.md` before changing the template system.
