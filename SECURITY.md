# Security policy

## Template-system security

The generator treats manifests as untrusted data. It never sources, evaluates, or executes manifest values. It rejects unknown/duplicate keys, unsafe names, unknown add-ons, and non-empty output targets.

## Generated-project security floor

Core projects receive:

- secret-hygiene defaults,
- least-privilege guidance,
- trust-boundary validation rules,
- a base security workflow,
- dependency-awareness checks,
- agent/tool authority guidance.

Projects that need a formal threat model and adversarial security evaluation can opt into `security-hardening`.

## Agent authority

Model capability is not authorization. Privileged behavior should be gated by identity, explicit capability, policy, validation, execution boundaries, and auditable evidence.

## Reporting

Report vulnerabilities privately to the repository owner or configured security-reporting channel. Do not publish an unpatched vulnerability that exposes users or infrastructure.
