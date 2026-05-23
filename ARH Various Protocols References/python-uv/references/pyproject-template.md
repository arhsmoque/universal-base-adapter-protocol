# pyproject.toml — Canonical ARH Template

Copy the relevant sections. Don't copy everything — keep it lean.

---

## Standard Project (src layout)

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Short description of what this does"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "httpx>=0.27.0",
    "rich>=13.0.0",
    "pydantic>=2.0.0",
]

[project.scripts]
# CLI entrypoints — run via: uv run my-tool
my-tool = "my_project.cli:app"

[dependency-groups]
dev = [
    "pytest>=8.0.0",
    "pytest-cov>=4.0.0",
    "ruff>=0.9.0",
    "mypy>=1.0.0",
    "vulture>=2.3.0",
    "pip-audit>=2.7.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/my_project"]

# --- ruff ---
[tool.ruff]
line-length = 88
indent-width = 4
target-version = "py312"
exclude = [".git", ".venv", "__pycache__", "build", "dist"]

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "UP", "SIM", "C4", "RUF"]
ignore = ["E501"]
fixable = ["ALL"]

[tool.ruff.lint.mccabe]
max-complexity = 10

[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]
"tests/*" = ["S101"]
"scripts/*" = ["T201"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"

# --- mypy ---
[tool.mypy]
python_version = "3.12"
strict = true
ignore_missing_imports = true
exclude = ["tests/", "scripts/"]

# --- pytest ---
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
markers = [
    "slow: marks tests as slow",
    "integration: marks integration tests",
]

# --- coverage ---
[tool.coverage.run]
source = ["src"]
omit = ["tests/*", "scripts/*"]

[tool.coverage.report]
show_missing = true
skip_covered = false

# --- vulture ---
[tool.vulture]
exclude = ["*settings.py", "*/docs/*.py", "*/test_*.py", "*/.venv/*.py"]
ignore_decorators = ["@app.route", "@require_*"]
ignore_names = ["visit_*", "do_*"]
min_confidence = 80
paths = ["src/", "tests/"]
sort_by_size = true
```

---

## Minimal Script Project (no src layout, no packaging)

```toml
[project]
name = "my-scripts"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "httpx>=0.27.0",
    "rich>=13.0.0",
]

[dependency-groups]
dev = [
    "pytest>=8.0.0",
    "ruff>=0.9.0",
]

[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "UP"]
ignore = ["E501", "T201"]  # allow print() in scripts

[tool.pytest.ini_options]
testpaths = ["tests"]
```

---

## Workspace / Monorepo Root

```toml
[tool.uv.workspace]
members = ["packages/*"]

[tool.uv.sources]
# reference internal workspace packages
my-lib = { workspace = true }
my-api = { workspace = true }
```

---

## Git / Local Sources

```toml
[tool.uv.sources]
# git dep
some-lib = { git = "https://github.com/user/some-lib", branch = "main" }
# local editable
local-lib = { path = "../local-lib", editable = true }
```

---

## Platform-Specific Deps (Windows ARH)

```toml
[project]
dependencies = [
    "winloop>=0.1.0; sys_platform == 'win32'",
    "uvloop>=0.19.0; sys_platform != 'win32'",
    "pywin32>=306; sys_platform == 'win32'",
]
```

---

## Common Optional Groups

```toml
[project.optional-dependencies]
# use for end-user optional features, not dev tools
extras = ["pillow>=10.0.0", "cairosvg>=2.7.0"]

# dev tools go in dependency-groups, not optional-dependencies
```

```toml
[dependency-groups]
dev = ["pytest>=8.0.0", "ruff>=0.9.0", "mypy>=1.0.0", "vulture>=2.3.0"]
docs = ["mkdocs>=1.5.0", "mkdocs-material>=9.0.0"]
profiling = ["py-spy>=0.3.0", "memray>=1.0.0"]
```
