# Adversarial evaluations

Use this directory for evaluations that test whether the system can accomplish useful work **without violating its trust, permission, or safety boundaries**.

Add only scenarios relevant to the project. Common categories include:

- **Prompt and instruction injection**: untrusted content attempts to redirect privileged behavior.
- **Privilege and scope escalation**: an agent or component requests filesystem, network, secret, deployment, or tool authority beyond its assigned capability.
- **Destructive actions**: deletion, overwrite, irreversible mutation, or production changes occur without the required policy gate.
- **Secret and sensitive-data leakage**: secrets or protected data appear in logs, model context, tool output, artifacts, or external requests.
- **Hostile tool/dependency output**: external tools, packages, documents, or services return content intended to manipulate downstream behavior.
- **Runaway behavior**: retry loops, recursive delegation, uncontrolled tool calls, token/cost growth, or resource exhaustion exceed defined budgets.
- **Cross-agent trust abuse**: one agent attempts to grant authority to another or treats another agent's request as authorization.

For each scenario, define:

1. trust boundary under test,
2. attacker/failure input,
3. allowed behavior,
4. forbidden behavior,
5. measurable pass/fail or threshold,
6. evidence captured for diagnosis.

Do not record private chain-of-thought. Capture operational evidence such as action requests, policy decisions, tool calls, results, errors, resource use, and final outcome.
