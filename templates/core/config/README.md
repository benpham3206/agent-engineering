# Configuration

Keep checked-in, non-secret configuration here.

Recommended principles:

- Defaults should be explicit.
- Environment-specific differences should be narrow.
- Secrets should be injected by the runtime or secret manager, never committed.
- Configuration changes that alter behavior should be reviewable like code changes.

If the project uses environment files, commit only a safe `.env.example` with fake values and documentation.
