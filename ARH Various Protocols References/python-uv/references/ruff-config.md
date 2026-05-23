# ruff-config — Standard ARH Ruff Configuration

Drop this block into `pyproject.toml`. Tune per project — don't copy blindly.

---

## Standard Block (most projects)

```toml
[tool.ruff]
line-length = 88
indent-width = 4
target-version = "py312"
exclude = [
    ".git",
    ".venv",
    "__pycache__",
    "build",
    "dist",
    "*.egg-info",
]

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # Pyflakes (undefined names, unused imports)
    "I",    # isort (import ordering)
    "B",    # flake8-bugbear (common bugs)
    "UP",   # pyupgrade (modernize syntax)
    "SIM",  # flake8-simplify
    "C4",   # flake8-comprehensions
    "RUF",  # ruff-specific rules
]
ignore = [
    "E501",  # line too long — handled by formatter
]
fixable = ["ALL"]
unfixable = []

[tool.ruff.lint.mccabe]
max-complexity = 10

[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]    # re-exports OK
"tests/*" = ["S101"]        # assert OK in tests
"scripts/*" = ["T201"]      # print() OK in scripts

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"
```

---

## Security-Aware Block (add S rules)

```toml
[tool.ruff.lint]
select = [
    "E", "W", "F", "I", "B", "UP", "SIM", "C4", "RUF",
    "S",    # bandit security checks
    "ANN",  # type annotation enforcement
]
ignore = [
    "E501",
    "ANN101",  # self doesn't need annotation
    "ANN102",  # cls doesn't need annotation
]
```

---

## Strict Block (libraries, shared packages)

```toml
[tool.ruff.lint]
select = [
    "E", "W", "F", "I", "B", "UP", "SIM", "C4", "RUF",
    "S", "ANN",
    "ARG",  # unused arguments
    "PT",   # pytest style
    "PERF", # performance anti-patterns
]
ignore = [
    "E501",
    "ANN101", "ANN102",
    "S101",  # re-enable per-file for tests
]
```

---

## Lenient Block (scripts, utilities, quick tools)

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I"]     # errors + imports only
ignore = ["E501", "T201"]    # allow long lines, allow print()
fixable = ["ALL"]
```

---

## Rule Reference (most useful)

| Code | Category | What it catches |
|---|---|---|
| `E` | pycodestyle errors | Indentation, whitespace, syntax style |
| `W` | pycodestyle warnings | Trailing whitespace, line endings |
| `F401` | Pyflakes | Unused imports |
| `F811` | Pyflakes | Redefinition of unused name |
| `F821` | Pyflakes | Undefined name |
| `I001` | isort | Import order violations |
| `B006` | bugbear | Mutable default argument |
| `B007` | bugbear | Unused loop variable |
| `B023` | bugbear | Loop variable captured by closure |
| `UP006` | pyupgrade | Use `list` instead of `List` |
| `UP007` | pyupgrade | Use `X \| Y` instead of `Union[X, Y]` |
| `SIM102` | simplify | Nested ifs → combined condition |
| `SIM118` | simplify | `key in dict` not `key in dict.keys()` |
| `C408` | comprehensions | `dict()` → `{}` |
| `C414` | comprehensions | Unnecessary list comprehension inside list() |
| `S101` | bandit | Use of `assert` (OK in tests) |
| `S105` | bandit | Hardcoded password |
| `S307` | bandit | Unsafe `eval()` |
| `S608` | bandit | SQL injection via string formatting |
| `T201` | flake8-print | `print()` calls (OK in scripts) |
| `RUF010` | ruff | Use explicit conversion flag |
| `RUF012` | ruff | Mutable class attributes should use `field()` |
| `RUF015` | ruff | Prefer `next(iter(x))` over single-element slice |
| `PERF102` | perflint | Incorrect iterator mutation |
| `ARG001` | unused-args | Unused function argument |
| `PT006` | pytest-style | Wrong pytest parametrize format |
| `C901` | mccabe | Cyclomatic complexity too high |

---

## Common Fixes

```powershell
# Autofix all safe rules
uv run ruff check --fix .

# Fix import ordering only
uv run ruff check --fix --select I .

# Fix + unsafe rules (review diff first)
uv run ruff check --fix --unsafe-fixes .

# Preview what would change
uv run ruff check --diff .

# Explain a specific rule
uvx ruff rule B006

# Show all active rules for this project
uv run ruff check --show-settings | Select-String "select"
```

---

## Inline Suppressions

```python
some_code()  # noqa: E501
some_code()  # noqa: E501, F401   # multiple

# Whole file suppression (rare — prefer per-file-ignores in config)
# ruff: noqa
```
