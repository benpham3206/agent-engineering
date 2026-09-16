# Security policy

## Template-system security

The generator treats manifests as untrusted data. It never sources, evaluates, or executes manifest values. It rejects unknown/duplicate keys, unsafe names, unknown add-ons, and non-empty output targets.

`NEW` is different from manifest generation: it intentionally executes the ecosystem-starter argv explicitly supplied by the caller, with the caller's privileges, inside the requested empty target. Treat starter packages and their install scripts as third-party code. Review provenance and use only the filesystem, credentials, and network authority that bootstrap step actually needs. `ADOPT` executes no project content and refuses conflicting control files or a symlinked `scripts` boundary before copying files.

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
