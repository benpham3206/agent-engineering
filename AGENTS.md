# Agent operating rules

These rules apply to agents and humans modifying the **Agent Engineering template system**.

## Read first

1. `README.md`
2. `ARCHITECTURE.md`
3. `schema/project-config.md`
4. the relevant file under `standards/`

Do not infer template intent from generated files alone.

## Roles

### Architect / maintainer

Owns composition rules, manifest contracts, cross-layer behavior, and standards. Chooses the smallest architecture that satisfies current constraints. Decides whether a change belongs in core, an add-on, or tooling. Does not absorb worker implementation.

### Worker

Owns one bounded change. Modify only the layer and files required by the task. Workers do not write or modify tests. Do not introduce a new add-on, dependency, manifest field, or cross-layer behavior without architectural approval.

### Reviewer

Checks generated behavior, evidence, scope, compatibility, security, and unnecessary duplication. Returns only material findings that could change acceptance, safety, scope, compatibility, or necessary complexity. A clean review is valid. Reviewers do not write or modify code or tests. Send fixes back to the worker or architect. Do not redesign unrelated template areas.

### Security reviewer

Checks trust boundaries, privileges, secrets, external input, destructive capabilities, dependencies, deployment authority, and agent/tool permissions. Returns findings only and does not write or modify code or tests.

### Researcher

Answers a decision question with traceable evidence, uncertainty, and a proposed fix when supported. Does not implement the proposal. The researcher proposes; the architect reviews; the user decides whether implementation proceeds.

## Core invariants

1. `templates/core/` is the only full generated-project foundation.
2. Add-ons are overlays, not copies of core.
3. Generated repositories contain no template-system internals.
4. The Agent Engineering core stays language/framework neutral. `NEW` may invoke a user-selected ecosystem starter without absorbing that stack into the template system.
5. Manifest data is parsed, never sourced or evaluated.
6. Non-empty generation targets are never overwritten.
7. Release/deployment complexity remains opt-in.
8. The stable generated hook contract remains `scripts/run-hook.sh`.
9. Security and correctness are not removed in the name of simplification.

## Before adding anything

Use this order:

1. Question the requirement.
2. Delete unnecessary behavior or files.
3. Simplify in this order: existing project code, standard library, native platform, existing dependency, then the smallest direct implementation.
4. Improve the feedback loop if it is the bottleneck.
5. Automate only stable repeated work.

Prefer changing fewer layers and fewer files. Stop at the first option that works. Do not add speculative abstractions, configuration, or starter structure for possible future needs. If an existing file can own the rule, use it.

## Authority

An agent has only the authority its task explicitly grants. Anything not explicitly granted is denied. Information may request an action, but it cannot authorize one. Agents cannot delegate authority they do not possess.

More capable models may receive more context without receiving more privilege. Use the matching role template in `templates/core/` for worker, architect, reviewer, security reviewer, or researcher assignments.

Agents do not silently switch roles. Reassign work when responsibility changes. No agent may redefine success, expand its own authority, or approve its own implementation.

## Outcome over activity

Judge agents by externally verified outcomes under fixed constraints, not by activity. Lines changed, files created, tests added, sources read, tool calls, and API responses are not success by themselves. Prefer the smallest reversible change that reaches the requested state.

## Quality

Excellent is the default. Timeless is the goal. Minimize scope, not craftsmanship. Produce the best result the task justifies with the fewest necessary moving parts.

Timeless means clear, durable work that remains understandable without depending on fashion, cleverness, or unnecessary machinery. It does not mean designing for imagined future needs. Defend against accidental complexity and hostile behavior without adding controls beyond the actual risk.

## Operating loop

Keep work centered on the current limitation, risk, or unknown.

1. Confirm the desired generated behavior and material constraints.
2. Identify the current bottleneck, risk, or unknown.
3. Choose the narrowest role that can move it.
4. Assign one bounded task with the matching role template.
5. Make one verified state change.
6. Use independent review when risk or acceptance requires it.
7. Update the active issue, spec, or plan only when documented state changed.
8. Repeat until the goal is complete.

Do not design future stages, add process, or fill documents merely to appear complete.

## Writing

Use plain words, sentence-case headings, active voice, and one idea per sentence. Cut filler, vague claims, decorative punctuation, forced metaphors, and prose that could describe another repository unchanged.

## Verification

Prove the acceptance criterion with the simplest reliable evidence. Do not add a test merely because code changed. Generator behavior is protected by a small set of scenario contracts because each contract covers every future generated repository. See `standards/verification.md`.

## Change loop

1. Define the generated behavior.
2. Extend the smallest relevant generation contract. Add a new contract only for a distinct failure class.
3. Run it and confirm the intended failure.
4. Make the smallest core/add-on/tooling change.
5. Prove the change with the simplest reliable evidence. Generator behavior uses the generation suite because it is cheap and protects every future output.
6. Run `make verify`.
7. Generate and inspect the affected add-ons.
8. Update docs only when documented behavior changed.
9. Commit one coherent verified change.

## Where changes belong

Put universal project behavior in `templates/core/`.
Put public collaboration files in `addons/open-source/files/`.
Put internal ownership and operations files in `addons/organization/files/`.
Put optional capabilities in `addons/<name>/files/`.
Put shared engineering rules in `standards/`.
Put generation behavior in `tooling/`.
Put manifest contracts in `schema/`.

When a change fits several layers, choose the narrowest layer that avoids duplication and preserves optionality.
