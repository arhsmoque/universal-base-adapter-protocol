# AUDIT — Multi-Perspective Code Review & Quality Analysis

Covers: systematic code review, dead code detection, complexity analysis, security scanning, and quality scoring. Use when reviewing existing code, before merging changes, or during periodic health checks.

---

## The Five Lenses

Every code review should look through these perspectives:

| Lens | Questions | Tools |
|---|---|---|
| **Design** | Is the structure right? Boundaries clear? Types used well? | Human + mypy |
| **Correctness** | Does it handle edge cases? Errors propagated? Race conditions? | pytest, ruff (B rules) |
| **Security** | Secrets hardcoded? Injections possible? Unsafe eval? | ruff (S rules), pip-audit |
| **Performance** | String concat in loops? Uncached repeated calls? N^2 loops? | PyRefactor, ruff (PERF rules) |
| **Maintainability** | Dead code? High complexity? Missing docs? Magic numbers? | vulture, ruff (C4, SIM) |

---

## Security Taxonomy — Map Findings to Attack Classes

Ruff's `S` rules (bandit) catch these specific vulnerability classes. Map findings to categories for clearer reports.

| Attack Class | What to Look For | Ruff Rules |
|---|---|---|
| **SQL Injection** | String formatting/concatenation in SQL queries | S608 |
| **Command Injection** | `os.system()`, `subprocess` with `shell=True`, string interpolation in commands | S605, S607, S602 |
| **Remote Code Execution (RCE)** | `eval()`, `exec()`, `compile()` on untrusted input | S307, S102 |
| **Path Traversal** | User input passed to `open()` / `Path` without sanitization | S209 |
| **Hardcoded Secrets** | Passwords, API keys, tokens in source | S105, S106, S107 |
| **Unsafe Deserialization** | `pickle.load()`, `yaml.load(unsafe)` | S301, S506 |
| **Weak Cryptography** | MD5, SHA1 for security purposes | S324 |
| **Debug / Assert in Production** | `assert` statements (stripped by `-O`) | S101 |
| **Tempfile Race Condition** | Predictable temp file names | S108 |
| **Insecure Permissions** | `chmod 777`, world-writable files | S103 |

```powershell
# Run security-only scan with categorized JSON output
uv run ruff check --select S --output-format json .
```

---

## Dead Code Detection with Vulture

Vulture finds unused imports, functions, classes, and variables via static analysis. It assigns confidence values (60–100%).

```powershell
# Install and run
uv add --dev vulture
uv run vulture src/ tests/

# Only report 100% certain dead code
uv run vulture src/ --min-confidence 100

# Generate whitelist for false positives
uv run vulture src/ --make-whitelist > whitelist.py
```

### pyproject.toml config

```toml
[tool.vulture]
exclude = ["*settings.py", "*/docs/*.py", "*/test_*.py", "*/.venv/*.py"]
ignore_decorators = ["@app.route", "@require_*"]
ignore_names = ["visit_*", "do_*"]
min_confidence = 80
paths = ["src/", "tests/", "whitelist.py"]
sort_by_size = true
verbose = true
```

### Handling false positives

1. **Whitelist file** (recommended): create a `whitelist.py` that imports/uses the seemingly-dead symbols.
2. **Prefix with underscore**: `def _internal_helper():` — vulture ignores underscore-prefixed names.
3. **`del` unused vars**: explicitly mark intentionally unused variables.

```python
# whitelist.py — reference symbols that vulture cannot detect via static analysis
from mypackage import PluginBase
PluginBase.register

from mypackage.cli import app
app.commands
```

---

## Complexity Analysis

High complexity = high bug density. Keep cyclomatic complexity ≤ 10 for any function.

```toml
[tool.ruff.lint.mccabe]
max-complexity = 10
```

### Complexity reduction patterns

```python
# ❌ Complex: nested conditionals + multiple responsibilities
def process(data, mode, flag):
    if mode == "a":
        if flag:
            return _handle_a_special(data)
        else:
            return _handle_a_normal(data)
    elif mode == "b":
        ...
    else:
        raise ValueError("bad mode")

# ✅ Simple: dispatch table + early validation
def process(data: Data, mode: Mode, flag: bool) -> Result:
    if mode not in _HANDLERS:
        raise ValueError(f"Unknown mode: {mode}")
    return _HANDLERS[mode](data, flag)

_HANDLERS: dict[Mode, Callable[[Data, bool], Result]] = {
    Mode.A: _handle_a,
    Mode.B: _handle_b,
}
```

---

## Security Scanning

### In-code security (ruff bandit rules)

Enable `S` rules in ruff to catch common security issues:

```toml
[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "UP", "RUF", "S"]
```

| Rule | Catches |
|---|---|
| S101 | `assert` in non-test code (removed by `-O`) |
| S105 | Hardcoded password strings |
| S307 | Unsafe `eval()` / `exec()` |
| S608 | SQL injection via string formatting |
| S603 | `subprocess` without `shell=False` sanity |
| S605 | `os.system()` or `popen()` usage |
| S607 | `subprocess` with shell=True and list args |

### Dependency security (pip-audit)

```powershell
uv add --dev pip-audit
uv run pip-audit --desc --format=json
```

Run in CI before every deploy. Fail the build on HIGH/CRITICAL.

### GitHub Actions security (zizmor)

For repos with CI workflows:

```powershell
# One-off scan
uvx zizmor .github/workflows/
```

Checks for template injection, insecure defaults, credential leakage in workflows.

---

## Quality Scoring Mindset

Don't chase a perfect score. Chase **improving trends**.

| Metric | Good | Warning | Critical |
|---|---|---|---|
| ruff issues per 1K lines | < 5 | 5–20 | > 20 |
| vulture dead code (confidence ≥80) | 0 | 1–3 | > 3 |
| max function complexity | ≤ 8 | 9–12 | > 12 |
| test coverage | > 80% | 60–80% | < 60% |
| pip-audit findings | 0 | LOW only | MEDIUM+ |
| security (S rules) violations | 0 | 0 | any |

---

## Code Review Checklist

Before approving code:

- [ ] **Types**: All public functions have type hints. No `Any` without justification.
- [ ] **Errors**: Specific exception types. No bare `except:`. No silent swallowing.
- [ ] **Boundaries**: Input validated at API/cli boundaries. Internal code trusts internal callers.
- [ ] **Dead code**: Run `vulture --min-confidence 80`. No unused imports.
- [ ] **Complexity**: No function over 10 cyclomatic complexity.
- [ ] **Security**: No hardcoded secrets. No `eval()`. Subprocesses use list args. No SQL string concat.
- [ ] **Tests**: New behavior has tests. Edge cases covered.
- [ ] **Docs**: Public APIs have docstrings. Complex logic has comments explaining *why*, not *what*.
- [ ] **Naming**: Names explain intent. No abbreviations. No `data`, `temp`, `value` without context.
- [ ] **Dependencies**: New deps justified. Prefer stdlib. Check license compatibility.

---

## One-Shot Audit Commands

### Manual (individual tools)

```powershell
# Full quality sweep
uv run ruff check . && uv run ruff format --check . && uv run mypy src/ && uv run vulture src/ tests/ && uv run pytest --cov

# Security-only sweep
uv run ruff check --select S --output-format json . && uv run pip-audit

# Dead code only
uv run vulture src/ tests/ --min-confidence 80

# Complexity report
uv run ruff check --select C901 .   # mccabe complexity
```

### Orchestrated (preferred for agents)

```powershell
# Run the arh-python-qa CLI for structured JSON output
arh-python-qa --mode audit --json
```

The CLI returns structured JSON with severity per tool, fixability flags, security findings grouped by attack class, and overall status — no manual log parsing required.
