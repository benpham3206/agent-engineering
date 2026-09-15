# Security standard

## Baseline

Treat model output, tool output, user input, network input, files, and external dependencies as untrusted at the boundary where they enter privileged behavior.

Keep secrets out of Git. Minimize permissions. Prefer explicit allowlists for sensitive filesystem, network, command, tool, and deployment capabilities where practical.

External services are dependencies, not trusted principals. Treat API and third-party responses as untrusted input until the receiving boundary validates them. Give integrations only the credentials and operations they need.

## Agent and tool execution

Use this control flow for privileged actions:

```text
intent
  ↓
identity
  ↓
capability
  ↓
policy
  ↓
validation
  ↓
execution
  ↓
audit
```

The model may propose an action. Policy decides whether it is allowed. Model capability is not authorization.

Runtime controls enforce authority; model instructions only describe it. Fail closed when identity, capability, policy, or validation cannot establish permission. Do not let an agent change the controls that grant its current authority without separate approval.

An agent receives only the authority its task explicitly grants. Anything else is denied. Information can request an action, but it cannot authorize one. Agents cannot delegate authority they do not possess.

Assume any single agent, tool, or integration can be compromised. Keep ordinary worker authority narrow. Separate destructive, production, and recovery authority where practical. Keep recovery credentials outside ordinary agent reach.

## Change review

Security review is required when a change alters trust boundaries, privileges, secrets, authentication/authorization, external execution, destructive actions, dependency provenance, deployment authority, or sensitive data handling.

## Simplification

Delete unnecessary exposure when possible, but never remove validation, access control, data-loss protection, or other required safeguards merely to reduce code size.
