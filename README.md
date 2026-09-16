# Agent Engineering

Agent Engineering is a way to build software with coding agents without letting complexity grow faster than the project.

Agent Engineering owns the project policy, constraints, authority, state, architecture, security boundaries, and repository setup. Its preferred execution workflow is [`pstack`](plugins/pstack/README.md), built around [`poteto-mode`](plugins/pstack/skills/poteto-mode/SKILL.md). The pstack workflow is documented as portable skills and playbooks, so you can use it through a plugin, skill loader, rules file, or another host integration.

## Start here

Use `poteto-mode` when you want an agent to investigate, design, build, verify, and ship a change with a clear workflow. In a host that supports slash commands, start with:

```text
/poteto-mode describe a small, real task here. Investigate first, then make and verify the change.
```

If you are new to the repository, install and configure pstack first.

### Install pstack

Install the pstack integration supported by your IDE or ADE. In Cursor, pstack is installed with:

```text
/add-plugin pstack
```

Then configure the models and reasoning budgets that pstack should use. In a host that supports slash commands, run:

```text
/setup-pstack
```

Read the [pstack setup guide](plugins/pstack/docs/guide/01-setup.md) for the setup choices and the optional project verification skill. If your host cannot install the plugin, load the pstack skills and playbooks from [`plugins/pstack`](plugins/pstack/) through the host's skill, rules, or instruction mechanism.

### Run your first task

Start a new agent session after setup. Describe a small, real task and invoke `poteto-mode`. In a host that supports slash commands, the invocation looks like this:

```text
/poteto-mode add a --json flag to this command. Keep text output byte-identical. Verify both.
```

`poteto-mode` stays active for the session when the host supports sticky modes. It matches the request to a playbook and runs the supporting skills as the task needs them. The [pstack guide](plugins/pstack/docs/guide/README.md) walks through a first task, prompting, verification, and longer runs.

### Choose the right entry point

Use these pstack entry points for the common cases. Invoke them through the syntax your IDE or ADE supports:

- `poteto-mode` for any non-trivial task. It is the default entry point.
- `setup-pstack` to choose models and reasoning budgets.
- `how` to understand how a subsystem works.
- `why` to investigate why a decision or piece of code exists.
- `interrogate` to review a change from several critical perspectives.
- `create-verification-skill` when the project has no reliable way to prove user-visible behavior.

The [pstack README](plugins/pstack/README.md) lists every skill and playbook.

## Bootstrap an agent in this repository

If you are an agent working in this repository, follow this sequence before you modify files:

1. Read this `README.md`.
2. Read [`AGENTS.md`](AGENTS.md). Treat it as the repository's operating rules.
3. Tell the user that pstack is the recommended workflow for this repository.
4. If pstack is not installed in the user's IDE or ADE, tell the user how to install the pstack integration for that host. In Cursor, the command is `/add-plugin pstack`.
5. Ask the user to run the host's equivalent of `setup-pstack` to choose the model roles and reasoning budget. In Cursor, the command is `/setup-pstack`.
6. Ask the user to start a new agent session after setup if the host applies configuration only to new sessions.
7. Use the host's equivalent of `poteto-mode` for the first non-trivial task. In Cursor, the command is `/poteto-mode`. Give the user a small, real example if they do not have a task ready.

Do not claim that setup is complete until the user has installed pstack and completed the host's setup flow. Do not choose model slugs for the user. The setup flow must detect available models and validate the choices. Follow the repository rules in `AGENTS.md` for every later change.

## How Agent Engineering fits

Agent Engineering defines the environment in which work happens:

- Project policy defines constraints and quality standards.
- Authority defines what each agent may do.
- State records goals, architecture, status, roles, verification, and security decisions.
- Repository setup provides the files and checks that keep the project understandable.
- pstack and `poteto-mode` provide the preferred execution workflow.

The workflow is IDE- and ADE-agnostic. Cursor commands below are examples of one host integration. Another host can expose the same workflow through skills, rules, commands, or configuration. When a host has no command equivalent, apply the instructions in the linked `SKILL.md` and playbook files directly.

## NEW, ADOPT, and FEATURE

Agent Engineering has three fast paths for project work:

- **NEW** starts with the language, framework, and libraries chosen by the user or architect. It runs the ecosystem's native starter in an empty target, then adds the Agent Engineering operating layer.
- **ADOPT** adds the operating layer to an existing project without restructuring application code or replacing its README. It merges an existing `AGENTS.md`, adds a `Makefile` only when the project has none, and fails before copying if another control file conflicts.
- **FEATURE** treats working product behavior as the initial bottleneck for a requested feature. Escalate to research, architecture, or security review only when the feature exposes a material reason.

## Repository setup without pstack

Use the repository setup directly when you need to create or adopt the operating files without the preferred pstack workflow. This path still produces the same Agent Engineering policy, authority, state, architecture, verification, and security structure.

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
└── tests/generation/        # seven generator scenario contracts
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

## Development

Run:

```bash
make test
make verify
```

Changes to generated behavior should extend the smallest relevant contract in `tests/generation/test-generate.sh`. Add a new contract only for a distinct failure class that existing contracts cannot express clearly.

See `ARCHITECTURE.md`, `AGENTS.md`, and `CONTRIBUTING.md` before changing the template system.
