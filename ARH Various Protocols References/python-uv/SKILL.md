---
name: python-uv
description: >
  Multi-perspective Python + uv domain skill for ARH. Governs all Python work through
  five lenses: design (structure, types, patterns), audit (review, dead code, complexity,
  security), maintenance (sustainability, refactoring, tech debt), environment lifecycle,
  and toolchain (ruff/mypy/pytest/vulture). Triggers on any Python task — script creation,
  package management, code review, debugging, or designing new utilities. Replaces pip,
  pipenv, poetry, pyenv, and virtualenv for all ARH work.
category: python
tags: [python, uv, ruff, pytest, mypy, pep723, venv, packaging, debugging, scripts, audit, maintenance, arh]
---

# Python + uv: ARH Multi-Perspective Domain Skill

One skill to govern all Python work on this machine. Five expert perspectives:
- **Design** — structure, types, error handling, async, validation
- **Audit** — code review, dead code detection, complexity, security scanning
- **Maintenance** — sustainable path, refactoring, dependency hygiene, tech debt
- **Environment** — uv lifecycle, venv, dependency management
- **Toolchain** — ruff, mypy, pytest, vulture, pip-audit

uv is the only package manager. ruff is the only linter/formatter. All tools run via `uv run`. No exceptions.

---

## ARH Hard Rules — Read First

These override generic Python advice. Violations cause silent failures.

| Rule | Why |
|---|---|
| `python script.py` — never `python3` | LibreOffice ships its own `python3` binary; `python3` may resolve to it silently |
| `uv add <pkg>` — never `pip install` | Keeps uv.lock authoritative; pip bypasses lockfile |
| `uv run <tool>` — never bare `ruff`, `pytest`, `mypy` | Bare invocations may hit wrong env or globally installed stale version |
| New deps: `uv add` — never edit pyproject.toml manually for deps | uv must resolve and lock; manual edits leave uv.lock stale |
| Python version: always declare in `.python-version` or `requires-python` | Avoids implicit resolution picking wrong version |
| Windows `.venv` activation in pwsh: `.venv\Scripts\Activate.ps1` | Not `source .venv/bin/activate` — that's bash |
| `[dependency-groups]` — not `[project.optional-dependencies]` for dev deps | Modern uv syntax; optional-dependencies is the old pattern |
| Never `Get-ChildItem -Recurse` through `D:\ARH` junction | Use arh-search MCP (KF-17) |

---

## Mode Router

Classify the task, then load the right module.

| What you're doing | Module to load |
|---|---|
| Create/manage venv, install deps, sync, pin Python | `modules/ENV.md` |
| Run ruff, mypy, pytest, vulture, pip-audit | `modules/TOOLCHAIN.md` |
| Write a standalone utility script (PEP 723) | `modules/SCRIPTS.md` |
| Debug env issues, stale cache, import errors | `modules/DEBUGGING.md` |
| Design a script or project (structure, types, error handling) | `modules/DESIGN.md` |
| Review code, find dead code, check complexity or security | `modules/AUDIT.md` |
| Refactor, manage tech debt, plan sustainable growth | `modules/MAINTENANCE.md` |
| Need a pyproject.toml or ruff config block | `references/pyproject-template.md`, `references/ruff-config.md` |
| Identify bad patterns in existing code | `references/anti-patterns.md` |

Load one module by default. Load more only when the task clearly spans domains.

---

## Agent Orchestration — Use the CLI Tool

The `arh-python-qa` CLI tool is the preferred way to run quality pipelines. It is a first-class ARH utility (not embedded in this skill).

**Location:** `_cli-utils/arh-python-qa/`  
**Install:** `uv tool install --editable _cli-utils/arh-python-qa`

```powershell
# Full pipeline (design + audit + maintenance)
arh-python-qa --mode full --json

# Design gate only — ruff, mypy, format check
arh-python-qa --mode design --fix

# Security audit — ruff S rules, vulture, pip-audit
arh-python-qa --mode audit --json

# Maintenance health — complexity, dead code
arh-python-qa --mode maintenance
```

The tool returns **structured JSON** with severity per tool, fixability flags, security findings grouped by attack class (SQL Injection, RCE, Path Traversal, etc.), and an overall status. No manual log parsing required.

**Exit codes:** 0=clean, 1=warn, 2=error, 3=failure

See the tool's `AGENT_HANDBOOK.md` for full agent-oriented documentation.

---

## Quick Command Reference

```powershell
# --- Environment ---
uv init my-project           # new project with pyproject.toml
uv sync                      # install all deps from uv.lock
uv sync --frozen             # CI: install exactly from lock, no updates
uv add requests httpx        # add runtime deps
uv add --dev pytest ruff     # add dev deps
uv remove requests           # remove dep
uv lock --upgrade            # upgrade all deps and regenerate lock
uv python install 3.12       # install a Python version
uv python pin 3.12           # pin version in .python-version

# --- Running ---
uv run python script.py      # run script in project env
uv run pytest                # run tests
uv run ruff check --fix .    # lint + autofix
uv run ruff format .         # format
uv run mypy src/             # type check
uvx ruff check .             # one-off: run tool without adding to project

# --- Quality Pipeline (use arh-python-qa CLI) ---
arh-python-qa --mode full --json
arh-python-qa --mode audit --json
arh-python-qa --mode design --fix

# --- Troubleshooting ---
uv cache clean               # clear package cache
rm -rf .venv && uv sync      # nuke and recreate venv
uv pip tree                  # dependency tree
```

---

## Trigger Signals

Load this skill when you see any of:
- `*.py` files, `pyproject.toml`, `uv.lock`, `.python-version`
- User asks to "write a script", "add a dependency", "fix the import error"
- User mentions pip, venv, poetry, conda — redirect to uv equivalents
- Any `python` or `uv` shell command in the task
- Ruff, mypy, pytest, vulture mentioned
- "Why isn't my code change appearing?" → load DEBUGGING.md
- "Review this code" or "find dead code" → load AUDIT.md
- "Refactor" or "technical debt" → load MAINTENANCE.md

---

## Anti-Pattern Quick Hits

| What you see | What to do instead |
|---|---|
| `pip install X` | `uv add X` |
| `python3 script.py` | `python script.py` or `uv run python script.py` |
| `pytest` (bare) | `uv run pytest` |
| `ruff check .` (bare) | `uv run ruff check .` |
| `python -m venv .venv` | `uv venv` |
| `poetry add X` | `uv add X` |
| `[project.optional-dependencies] dev = [...]` | `[dependency-groups] dev = [...]` |
| `# [tool.uv.metadata]` in script block | Use docstring for metadata instead |
| Editing `uv.lock` by hand | Never — only uv writes lockfiles |
| `requirements.txt` as source of truth | `pyproject.toml` + `uv.lock` |

Full anti-patterns catalog: `references/anti-patterns.md`

---

## Modules (load on demand)

- [ENV.md](modules/ENV.md) — environment lifecycle: init, sync, Python versions, venv, workspaces
- [TOOLCHAIN.md](modules/TOOLCHAIN.md) — ruff, mypy, pytest, vulture, pip-audit — all under `uv run`
- [SCRIPTS.md](modules/SCRIPTS.md) — PEP 723 standalone scripts: shebangs, inline deps, templates
- [DEBUGGING.md](modules/DEBUGGING.md) — stale cache, import errors, version conflicts, env diagnosis
- [DESIGN.md](modules/DESIGN.md) — script/project design: structure, types, error handling, validation, async
- [AUDIT.md](modules/AUDIT.md) — code review, dead code, complexity, security scanning, quality scoring
- [MAINTENANCE.md](modules/MAINTENANCE.md) — sustainable path, refactoring, dependency hygiene, tech debt

## References

- [pyproject-template.md](references/pyproject-template.md) — canonical pyproject.toml for ARH projects
- [ruff-config.md](references/ruff-config.md) — standard ruff config block for pyproject.toml
- [anti-patterns.md](references/anti-patterns.md) — full catalog of bad patterns and corrections

## External Tools

- `arh-python-qa` — quality pipeline orchestrator CLI (`_cli-utils/arh-python-qa/`)
