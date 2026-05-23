# MAINTENANCE — Sustainable Path & Long-Term Health

Covers: keeping codebases healthy over time, refactoring triggers, dependency hygiene, deprecation, technical debt, and migration patterns.

---

## Sustainable Codebase Principles

1. **Small surface area** — Fewer public APIs = fewer breaking changes to manage.
2. **Minimal dependencies** — Each dep is a liability. Prefer stdlib. Audit deps quarterly.
3. **Clear module boundaries** — One module, one responsibility. Circular imports are a smell.
4. **Automated gates** — CI blocks on ruff, mypy, pytest. No manual discipline required.
5. **Incremental improvement** — Small refactors continuously. No big-bang rewrites.

---

## Refactoring Triggers

Refactor when you see these signals — not before, not long after:

| Signal | Action |
|---|---|
| Function > 50 lines or complexity > 10 | Extract helpers; use dispatch tables |
| Same logic in 3+ places | Extract shared function or class |
| Test requires heavy mocking | Suggests tight coupling; inject dependencies instead |
| Changing one thing breaks unrelated tests | Violated boundaries; restructure modules |
| Name no longer matches behavior | Rename immediately (ruff-safe) |
| `TODO` or `FIXME` > 30 days old | Schedule fix or remove |
| Dependency has 2+ major versions behind | Plan upgrade (check changelog for breaking changes) |
| Type checker flags growing `Any` usage | Revisit design; add Protocols or generics |

---

## Dependency Hygiene

### Adding a new dependency — justification checklist

- [ ] Can stdlib do this? (tomllib, asyncio, pathlib, dataclasses)
- [ ] Is the package actively maintained? (last release < 12 months)
- [ ] Is the license compatible? (MIT/Apache-2.0/BSD preferred)
- [ ] Does it pull in a heavy transitive tree? (`uv pip tree` to inspect)
- [ ] Is there a lighter alternative? (httpx vs requests+urllib3, polars vs pandas)

### Lockfile maintenance

```powershell
# Weekly: upgrade patch releases
uv lock --upgrade

# Monthly: review major/minor upgrades
uv lock --upgrade-package fastapi
# Run full test suite after

# Before release: ensure lock is committed and frozen install works
uv sync --frozen
uv run pytest
```

### Removing unused dependencies

```powershell
# Vulture catches dead code; check if deps are still imported
rg "import (package_name)" src/ tests/ scripts/
# If no hits, uv remove package_name
```

---

## Deprecation Patterns

Never break consumers without warning. Use a three-phase deprecation:

```python
import warnings
from typing import deprecated  # Python 3.13+; use @warnings.deprecated before

def old_function(x: int) -> int:
    """Deprecated: use new_function instead."""
    warnings.warn(
        "old_function is deprecated and will be removed in v2.0. Use new_function.",
        DeprecationWarning,
        stacklevel=2,
    )
    return new_function(x)


def new_function(x: int) -> int:
    """The improved replacement."""
    return x * 2
```

**Timeline:**
- v1.x: Introduce new function. Old function emits `DeprecationWarning`.
- v1.(x+2): Upgrade to `FutureWarning` (visible by default).
- v2.0: Remove old function.

---

## Technical Debt Tracking

Use structured TODOs that are greppable and accountable:

```python
# Format: TODO(<category>): <what> — <who> <deadline or issue-ref>
# Categories: REFACTOR, PERF, SECURITY, DEPS, BUG, DESIGN

# TODO(REFACTOR): Extract retry logic into shared client — @smoqu 2026-06
# TODO(PERF): Replace nested loop with set intersection — issue #42
# TODO(SECURITY): Rotate API key before 2026-07-01 — issue #55
```

```powershell
# Monthly debt review
rg "TODO\((\w+)\)" src/ --output-mode=content | sort
```

---

## Migration Patterns

### Modernizing syntax (automated)

```powershell
# ruff's UP rules auto-modernize Python syntax
uv run ruff check --select UP --fix .
```

| From | To | UP rule |
|---|---|---|
| `List[str]` | `list[str]` | UP006 |
| `Union[X, Y]` | `X \| Y` | UP007 |
| `Optional[T]` | `T \| None` | UP007 |
| `dict()` | `{}` | UP018 |
| `.format()` / `%` | f-strings | UP031, UP032 |
| `typing.Dict` | `dict` | UP006 |

### Upgrading dependencies safely

```powershell
# 1. Upgrade one at a time
uv lock --upgrade-package pydantic

# 2. Check changelog for breaking changes
# 3. Run type checker (upgrades often reveal new type issues)
uv run mypy src/

# 4. Run full test suite
uv run pytest

# 5. Commit lockfile change separately for easy rollback
```

### Moving from flat to src layout

If a project outgrew flat layout:

```
# Before
my_project/
  __init__.py
  core.py
tests/

# After
src/
  my_project/
    __init__.py
    core.py
tests/
```

Update `pyproject.toml`:

```toml
[tool.hatch.build.targets.wheel]
packages = ["src/my_project"]
```

Update imports in tests to use absolute imports (`from my_project.core import ...`).

---

## Code Health Monitoring

Add to CI or run weekly:

```powershell
# Dead code check
uv run vulture src/ tests/ --min-confidence 80

# Complexity check
uv run ruff check --select C901 .

# Security check
uv run ruff check --select S . && uv run pip-audit

# Type coverage (strict mypy)
uv run mypy src/ --strict

# Full test + coverage
uv run pytest --cov --cov-fail-under=80
```

---

## The Boy Scout Rule

> Leave the codebase cleaner than you found it.

Every PR that touches a file should:
- Remove one unused import if found.
- Fix one ruff warning if nearby.
- Add one missing type hint if the function is being modified.
- Update one outdated docstring if the behavior changed.

Small, continuous improvements compound into a maintainable codebase.
