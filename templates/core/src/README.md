# Source

Use the source layout that fits the project's constraints and chosen ecosystem.

Prefer native project conventions over this directory. Delete `src/` when the project uses another source root.

Create boundaries only when real responsibilities require them. Keep code with its owner until multiple consumers justify a shared boundary.

Do not create directories, abstractions, or layers for possible future needs.

Describe stable cross-component boundaries in `ARCHITECTURE.md`.
