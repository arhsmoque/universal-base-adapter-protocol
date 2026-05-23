# TOOLCHAIN — ruff, mypy, pytest, vulture, security under uv run

All tools run via `uv run`. Never invoke bare. Never rely on globally installed versions.

**Prefer `arh-python-qa`** for multi-tool pipelines. See `_cli-utils/arh-python-qa/` and `SKILL.md`.

---

## The Golden Rule

```powershell
# ❌ wrong — may hit wrong version or wrong env
ruff check .
pytest
mypy src/

# ✅ correct — always scoped to project env
uv run ruff check .
uv run pytest
uv run mypy src/
```

Exception: `uvx <tool>` for one-off execution without adding to project (equivalent to npx).

---

## Orchestrated Pipeline (Recommended)

Instead of chaining commands manually, use the `arh-python-qa` CLI tool:

```powershell
# Install once
uv tool install --editable D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-python-qa

# Full pipeline with structured JSON output
arh-python-qa --mode full --json

# Design gate: ruff + mypy + format check
arh-python-qa --mode design --fix

# Audit: security rules + vulture + pip-audit
arh-python-qa --mode audit --json

# Maintenance: complexity + dead code
arh-python-qa --mode maintenance
```

The tool groups security findings by attack class (SQL Injection, RCE, Path Traversal, etc.) and returns exit codes: 0=clean, 1=warn, 2=error, 3=failure.

---

## Ruff — Lint + Format + Import Sort

ruff replaces: flake8, black, isort, pyupgrade, autoflake. One tool, one config block.

### Common commands

```powershell
uv run ruff check .             # lint (report only)
uv run ruff check --fix .       # lint + autofix safe rules
uv run ruff check --fix --unsafe-fixes .  # autofix including unsafe rules
uv run ruff format .            # format (like black)
uv run ruff format --check .    # check formatting without modifying
uv run ruff check --diff .      # preview fixes without applying

# Combined quality pass
uv run ruff check --fix . && uv run ruff format .
```

### Security-aware linting

```powershell
uv run ruff check --select S --output-format json .
```

This produces machine-parseable output grouped by vulnerability category (see `modules/AUDIT.md`).

### One-shot without project dep

```powershell
uvx ruff check .
uvx ruff format .
```

### Config lives in pyproject.toml

See `references/ruff-config.md` for the canonical ARH config block.

### Key rule categories

| Code | Rule | Why it matters |
|---|---|---|
| E | pycodestyle errors | PEP 8 basics |
| W | pycodestyle warnings | Style warnings |
| F | Pyflakes | Undefined names, unused imports |
| I | isort | Import ordering |
| B | flake8-bugbear | Common bugs and design issues |
| UP | pyupgrade | Modernize Python syntax |
| S | bandit security | Security issues |
| SIM | flake8-simplify | Simplify code structure |
| C4 | flake8-comprehensions | Use comprehensions idiomatically |
| C901 | mccabe | Cyclomatic complexity |
| RUF | ruff-specific | Ruff's own rules |

### Per-file ignores (common)

```toml
[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]   # re-exports are fine
"tests/*" = ["S101"]       # assert is fine in tests
"scripts/*" = ["T201"]     # print() is fine in scripts
```

---

## pytest — Testing

### Running tests

```powershell
uv run pytest                          # all tests
uv run pytest tests/test_api.py        # specific file
uv run pytest -k "test_user"           # by name pattern
uv run pytest -m "not slow"            # by marker
uv run pytest --cov                    # with coverage
uv run pytest --cov --cov-report=html  # html coverage report
uv run pytest -n auto                  # parallel (needs pytest-xdist)
uv run pytest -x                       # stop on first failure
uv run pytest -v                       # verbose output
```

### Project config for pytest

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
markers = [
    "slow: marks tests as slow",
    "integration: marks integration tests",
]
```

### Useful dev deps for testing

```powershell
uv add --dev pytest pytest-cov pytest-xdist pytest-asyncio
```

### conftest.py pattern

```python
# tests/conftest.py
import pytest

@pytest.fixture(scope="session")
def db():
    # setup
    yield session
    # teardown

@pytest.fixture(autouse=True)
def reset_state():
    yield
    # cleanup after each test
```

---

## mypy — Type Checking

```powershell
uv add --dev mypy
uv run mypy src/
uv run mypy src/ --strict           # strict mode (recommended for new projects)
uv run mypy src/ --ignore-missing-imports  # suppress missing stubs errors
```

### Config in pyproject.toml

```toml
[tool.mypy]
python_version = "3.12"
strict = true
ignore_missing_imports = true
exclude = ["tests/", "scripts/"]
```

### Type stubs for common packages

```powershell
uv add --dev types-requests types-PyYAML types-toml
```

---

## vulture — Dead Code Detection

Finds unused imports, functions, classes, and variables.

```powershell
uv add --dev vulture
uv run vulture src/ tests/
uv run vulture src/ --min-confidence 80
```

See `modules/AUDIT.md` for full vulture configuration and whitelist patterns.

---

## pip-audit — Dependency Vulnerability Scanning

```powershell
uv add --dev pip-audit
uv run pip-audit
uv run pip-audit --desc --format=json
```

Run in CI. Fail on HIGH/CRITICAL findings.

---

## pre-commit

```powershell
uv add --dev pre-commit
uv run pre-commit install                            # install git hooks
uv run pre-commit install --hook-type pre-push       # also on push
uv run pre-commit run --all-files                    # run manually on all files
uv run pre-commit autoupdate                         # update hook versions
```

### .pre-commit-config.yaml for ARH

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: local
    hooks:
      - id: mypy
        name: mypy
        entry: uv run mypy
        language: system
        types: [python]
        pass_filenames: false
        args: [src/]

  - repo: local
    hooks:
      - id: vulture
        name: vulture
        entry: uv run vulture
        language: system
        types: [python]
        pass_filenames: false
        args: [src/, tests/, --min-confidence, "80"]
```

---

## Full Quality Gate (one command)

```powershell
# Manual chain
uv run ruff check --fix . && uv run ruff format . && uv run mypy src/ && uv run vulture src/ tests/ && uv run pytest

# Or use the orchestrator
arh-python-qa --mode full
```

---

## Justfile Pattern (optional)

```just
check:
    arh-python-qa --mode full

test:
    uv run pytest {{args}}

fmt:
    uv run ruff format .
    uv run ruff check --fix .

audit:
    arh-python-qa --mode audit --json
```

Run: `just check` — no need to remember the full command chain.
