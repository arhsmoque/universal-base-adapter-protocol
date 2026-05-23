# arh-python-qa

ARH Python Quality Assurance Orchestrator. One command runs the entire Python quality pipeline.

## Install

```powershell
# Install from local source (recommended for ARH)
cd D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-python-qa
uv tool install --editable .

# Or run without installing
uv run arh-python-qa --mode full --json
```

## Usage

```powershell
# Full pipeline (design + audit + maintenance)
arh-python-qa --mode full --json

# Design gate only — ruff, mypy, format check
arh-python-qa --mode design --fix

# Security audit — ruff S rules, vulture, pip-audit
arh-python-qa --mode audit --json

# Maintenance health — complexity, dead code
arh-python-qa --mode maintenance

# Target a specific project
arh-python-qa --mode full --project D:\Projects\myapp
```

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Clean — no issues |
| 1 | Warnings — style, dead code, low-severity findings |
| 2 | Errors — type failures, security issues, test failures |
| 3 | Orchestrator failure — tool missing, wrong directory |

## JSON output

With `--json`, the tool emits structured output including:
- `overall_severity`: `ok` | `warn` | `error`
- `results[]`: per-tool status, stdout, stderr, returncode
- `security_by_category`: grouped findings (SQL Injection, RCE, Path Traversal, etc.)
- `fixable`: whether `--fix` resolved any issues

## Requirements

- Python >= 3.12
- `uv` installed and on PATH
- Target project must be a uv project (pyproject.toml + uv.lock) for best results
