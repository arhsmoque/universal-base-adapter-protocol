# arh-python-qa — Agent Handbook

## What this tool does

`arh-python-qa` is the ARH Python quality pipeline orchestrator. It replaces manual chaining of `ruff`, `mypy`, `pytest`, `vulture`, and `pip-audit` with a single command that returns structured, machine-parseable results.

## When to use it

- Before committing Python code
- During code review to generate audit reports
- In CI/CD pipelines
- When an agent needs to assess Python project health without parsing raw tool output

## Installation (one-time)

```powershell
cd D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-python-qa
uv tool install --editable .
```

## Commands

```powershell
# Full quality gate
arh-python-qa --mode full --json

# Design-only (ruff + mypy + format)
arh-python-qa --mode design --fix

# Audit-only (security + dead code + dependencies)
arh-python-qa --mode audit --json

# Maintenance-only (complexity + dead code)
arh-python-qa --mode maintenance
```

## Interpreting JSON output

```json
{
  "mode": "audit",
  "overall_severity": "warn",
  "fixable": false,
  "security_by_category": {
    "SQL Injection": [{"file": "db.py", "line": 12, "code": "S608", "message": "..."}]
  },
  "results": [
    {"tool": "ruff", "passed": false, "severity": "warn", "summary": "3 issues"}
  ]
}
```

| `overall_severity` | Action |
|---|---|
| `ok` | Approve |
| `warn` | Review findings, may approve with notes |
| `error` | Block — fix before proceeding |

## Agent decision tree

```
Need to check Python code quality?
│
├─ Quick health check?
│   └─ arh-python-qa --mode maintenance --json
│
├─ Pre-commit gate?
│   └─ arh-python-qa --mode design --fix
│
├─ Security audit?
│   └─ arh-python-qa --mode audit --json
│
└─ Full assessment?
    └─ arh-python-qa --mode full --json
```

## Hard rules

- Always use `--json` when the agent needs to parse results
- Use `--fix` only in `design` mode — never auto-fix audit issues
- The tool auto-detects uv projects; pass `--project` explicitly if cwd is wrong
- Exit code 3 means the tool itself failed (missing tool, syntax error) — not a code issue
