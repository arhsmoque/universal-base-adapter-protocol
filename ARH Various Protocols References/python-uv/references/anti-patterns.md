# Anti-Patterns — Python + uv on ARH

Full catalog. Every entry has: what not to do, what to do instead, why it matters.

---

## Tooling Anti-Patterns

| Anti-pattern | Correct | Why |
|---|---|---|
| `pip install X` | `uv add X` | pip bypasses uv.lock; env becomes inconsistent |
| `pip install -r requirements.txt` | `uv sync` | requirements.txt is not the source of truth |
| `python -m venv .venv` | `uv venv` | uv manages Python version automatically |
| `poetry add X` | `uv add X` | One tool only; don't mix |
| `pipenv install X` | `uv add X` | Same reason |
| `conda install X` | `uv add X` — or justify conda for scientific stack | conda env conflicts with uv env |
| `pytest` (bare) | `uv run pytest` | May hit globally installed stale version |
| `ruff check .` (bare) | `uv run ruff check .` | Same reason |
| `mypy src/` (bare) | `uv run mypy src/` | Same reason |
| `black .` | `uv run ruff format .` | ruff replaces black; one tool |
| `isort .` | `uv run ruff check --fix . --select I` | ruff replaces isort |
| `flake8 .` | `uv run ruff check .` | ruff replaces flake8 |
| Editing `uv.lock` manually | Never — only `uv lock` writes it | Manual edits produce invalid lock |

---

## Python Invocation Anti-Patterns

| Anti-pattern | Correct | Why |
|---|---|---|
| `python3 script.py` | `python script.py` | On ARH, `python3` may resolve to LibreOffice's embedded Python |
| `python3 -m pytest` | `uv run pytest` | Wrong env; wrong version |
| `#!/usr/bin/env python3` in scripts | `#!/usr/bin/env -S uv run --script` | LibreOffice trap; uv manages deps |
| Activating venv then running | `uv run <cmd>` | Activation is fragile; `uv run` is hermetic |
| `python` without `uv run` in scripts/CI | `uv run python` | Ensures project env, not system Python |
| Assuming `python` = Python 3 | Check `uv run python --version` | Windows may have both; pin explicitly |

---

## pyproject.toml Anti-Patterns

| Anti-pattern | Correct | Why |
|---|---|---|
| `[project.optional-dependencies] dev = [...]` | `[dependency-groups] dev = [...]` | optional-dependencies is for end-user extras, not dev tools |
| `requirements.txt` as primary dep spec | `pyproject.toml` + `uv.lock` | requirements.txt has no lock semantics |
| `setup.py` for packaging | `pyproject.toml` + hatchling | setup.py is legacy; PEP 517 standard |
| `setup.cfg` | `pyproject.toml` | Consolidate everything in one file |
| Pinning all deps to exact versions in pyproject.toml | Use `>=X.Y.Z`; exact pinning is `uv.lock`'s job | Over-constraining blocks dependency resolution |
| No `requires-python` field | Always declare | Prevents resolution on wrong Python silently |
| Missing `[build-system]` | Add it for any project being built/installed | Required for `uv build` and editable installs |

---

## Script (PEP 723) Anti-Patterns

| Anti-pattern | Correct | Why |
|---|---|---|
| `[tool.uv.metadata]` in script block | Use module docstring for metadata | Not in PEP 723; causes parse error |
| `#!/usr/bin/env python3` on uv scripts | `#!/usr/bin/env -S uv run --script` | Won't auto-install deps; wrong Python |
| No `requires-python` in script block | Always include it | Prevents wrong version silently |
| No version constraint on deps | `"httpx>=0.27.0"` not `"httpx"` | Unconstrained deps are not reproducible |
| 500+ line single-file script | Refactor into a `uv init` project | Unmaintainable; can't test properly |
| Hardcoded secrets in script | Use env vars or keyring | Security — scripts may be committed |
| `import requests` without dep declaration | Declare in `# dependencies = [...]` block | Script won't work on fresh run |

---

## Code Design Anti-Patterns

| Anti-pattern | Correct | Why |
|---|---|---|
| `except Exception: pass` | Catch specific, log, re-raise or handle | Silent swallow hides bugs |
| `except Exception as e: print(e)` | `log.exception(...)` or `sys.exit(1)` | Print doesn't give traceback; no structured log |
| Global mutable state | Pass via arguments / dependency injection | Untestable; causes subtle bugs |
| Defensive checks inside the same module | Validate at boundaries only | Internal functions can trust internal callers |
| `type(x) == str` | `isinstance(x, str)` | isinstance handles subclasses |
| `from module import *` | Explicit imports | Pollutes namespace; unclear what's used |
| Mutable default argument: `def f(lst=[])` | `def f(lst=None): lst = lst or []` | Classic Python footgun; shared state |
| No type hints on public functions | Type hint all public API | Enables mypy, better IDE support |
| `time.sleep()` in async code | `await asyncio.sleep()` | Blocks the event loop |
| `requests` in async code | `httpx.AsyncClient` | requests is sync; blocks event loop |
| String concatenation in a loop | `str.join()` or list + join | O(n²) performance |
| `d.keys()` in `for k in d.keys()` | `for k in d` | Redundant; less readable |
| `if key in d: d[key]` | `d.get(key, default)` | Cleaner; single lookup |
| Unnecessary `else` after `return`/`raise`/`break`/`continue` | Flatten with early return | Reduces nesting |
| Missing `with` for file/connection/lock | Use context managers | Resource leaks |
| Overcomplicated boolean expressions | Decompose into named vars or functions | Cognitive load |
| `eval()` or `exec()` on untrusted input | Use `ast.literal_eval()` or parsers | Remote code execution |
| Chained `if/elif` for enum dispatch | `dict` dispatch table | Extensible; lower complexity |
| `len(x) == 0` / `len(x) > 0` | `if x:` / `if not x:` | Pythonic; works for all collections |
| `list.append` in loop when `list comprehension` fits | Comprehension or generator | Faster; more declarative |
| Not using `@dataclass(frozen=True)` for value objects | Immutable by default | Prevents accidental mutation |
| `raise NewError("msg")` without `from e` | `raise NewError("msg") from e` | Preserves traceback chain |
| `Any` as escape hatch | Use `object`, `Protocol`, or generics | `Any` disables type safety |

---

## ARH Environment Anti-Patterns

| Anti-pattern | Correct | Why |
|---|---|---|
| `Get-ChildItem -Recurse` through `D:\ARH` | `arh-search` MCP | KF-17: junction traversal hangs |
| Building in `D:\00_ARH\` | Build in `C:\Projects\<project>` | KF-19: `#` in path breaks Vite and some build tools |
| `python3` anywhere | `python` | LibreOffice trap |
| `npm` in Git Bash | `npm.cmd` | Resolves wrong binary |
| Bare `pwsh path\to\script.ps1` in bash | Quoted: `pwsh "D:\path\to\script.ps1"` | Backslashes stripped |
| Starting GPU task without `CUDA_VISIBLE_DEVICES=""` | `$env:CUDA_VISIBLE_DEVICES = ""` before GPU task | Preserve GTX 1650 for SVP4/mpv |
| `curl` for HTTP in scripts | `xh` (CLI) or `httpx` (Python) | curl not standardized; xh is installed |
| `jq` for JSON in shell | `jaq` | jq not installed on this machine |

---

## Testing Anti-Patterns

| Anti-pattern | Correct | Why |
|---|---|---|
| Testing implementation details | Test behavior / contracts | Implementation changes break tests unnecessarily |
| No fixture cleanup | Use `yield` fixtures with teardown | Leaking state causes false positives |
| `assert` with no message on complex conditions | `assert condition, "human-readable message"` | Failures are undebuggable |
| Mocking everything | Mock only external I/O boundaries | Over-mocking hides real integration bugs |
| Tests in the same file as code | Separate `tests/` directory | Keeps package clean; test discovery works |
| Importing test utilities from test files | Use `conftest.py` | Conftest is auto-discovered by pytest |
| No coverage for error branches | Test failure paths explicitly | Uncaught regressions in error handling |
