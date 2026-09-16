# Project configuration schema

The generator intentionally uses a small `KEY=value` manifest so it can validate configuration without a package manager or language-specific parser.

## Keys

| Key | Required | Values |
| --- | --- | --- |
| `PROJECT_NAME` | yes | repository-safe slug: letters, numbers, `.`, `_`, `-` |
| `ADDONS` | no | comma-separated supported add-ons |
| `OUTPUT_DIR` | no | POSIX absolute path or path relative to the template repository |

Supported add-ons: `open-source`, `organization`, `deployment`, `releases`, `observability`, `benchmarks`, `performance`, `security-hardening`.
Add-on files may not shadow backbone files (listed in `templates/core/scripts/backbone.list`), `.engineering-manifest`, or files provided by an earlier add-on in the same manifest.

Unknown keys and duplicate keys are errors. The file is parsed as data; it is never sourced or evaluated by a shell.

## Path portability

Shell tooling targets Linux, macOS system Bash 3.2, and Git Bash/MSYS2 on Windows. In Git Bash, use POSIX drive paths such as `/d/work/project`. Drive-letter forms such as `D:/work/project` are rejected so they cannot be mistaken for repository-relative paths. Native PowerShell and `cmd.exe` are not part of this shell contract.
