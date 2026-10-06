# Git standard

Use short-lived branches, coherent verified commits, pull requests, required checks, and protected `main`. Avoid combining unrelated behavior changes and refactors in one commit.

Protect `main` when a repository is created on GitHub: run `bash tooling/protect-main.sh OWNER/REPO` from agent-engineering. Run it again after the first pull request CI run, so the checks it ran become required.
