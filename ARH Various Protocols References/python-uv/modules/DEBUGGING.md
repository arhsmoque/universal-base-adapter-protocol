# DEBUGGING — Python + uv Environment Diagnosis

Covers: stale cache, import errors, code changes not appearing, version conflicts, env corruption.

---

## Decision Tree — Start Here

```
Something is broken in a Python/uv project
│
├── "My code changes aren't showing up when I run the tool"
│   → Stale build artifacts (see: Build Cache Stale)
│
├── "ModuleNotFoundError" or "ImportError"
│   → Wrong env or missing dep (see: Import Errors)
│
├── "uv sync fails" or "Cannot resolve dependencies"
│   → Dependency conflict (see: Dependency Conflicts)
│
├── "Wrong Python version running"
│   → Version mismatch (see: Python Version Issues)
│
├── "Tool was updated but still behaves old"
│   → Stale tool install or build cache (see: Tool Not Updating)
│
└── "Everything is broken, don't know where to start"
    → Environment health check (see: Full Diagnosis)
```

---

## Build Cache Stale

**Symptoms:** You edited Python source but running the installed tool shows old behavior.

**Cause:** `uv tool install` builds a wheel. If `build/`, `dist/`, or `*.egg-info/` exist from a prior build, uv may reuse the cached wheel.

```powershell
# Quick fix (90% of cases)
Remove-Item -Recurse -Force build, dist
Get-ChildItem -Filter "*.egg-info" | Remove-Item -Recurse -Force
uv tool install --force .

# Verify the fix
uv run <tool> --version
which <tool>   # (Git Bash)
```

**Note:** `--force` alone does NOT clean the wheel cache. Must remove `build/`, `dist/`, `*.egg-info/` first.

**Prevention:** Use `uv tool install --editable .` during active development — changes appear immediately without reinstall.

| Mode | Command | Changes visible | Use when |
|---|---|---|---|
| Editable | `uv tool install --editable .` | Immediately | Active dev |
| Production | `uv tool install .` | After reinstall | Release |
| Local run | `uv run <cmd>` | Immediately | Recommended |

---

## Import Errors

**Symptom:** `ModuleNotFoundError: No module named 'X'`

**Diagnosis:**

```powershell
# 1. Which Python is running?
uv run python -c "import sys; print(sys.executable)"

# 2. Is the package installed in the project env?
uv pip show X

# 3. Is the dep in pyproject.toml?
Select-String "X" pyproject.toml

# 4. Is uv.lock fresh?
uv sync
```

**Fixes:**

```powershell
# Package missing from project
uv add X

# Package added but env not synced
uv sync

# Env corrupted — nuke and rebuild
Remove-Item -Recurse -Force .venv
uv sync

# New file added to package but wheel was cached before it existed
Remove-Item -Recurse -Force build, dist
Get-ChildItem -Filter "*.egg-info" | Remove-Item -Recurse -Force
uv tool install --force .
```

---

## Python Version Issues

**Symptom:** Wrong Python version running; syntax errors for valid 3.12+ code; `python3` resolving unexpectedly.

**ARH-specific:** Never use `python3` — on this machine it may resolve to LibreOffice's embedded Python. Always use `python` or `uv run python`.

```powershell
# What version is uv using for this project?
uv run python --version

# What's pinned in the project?
cat .python-version

# What's declared in pyproject.toml?
Select-String "requires-python" pyproject.toml

# Install the right version
uv python install 3.12
uv python pin 3.12

# Force specific version for a run
uv run --python 3.12 python script.py
```

**Windows Store trap:** `python` may open the Windows Store on a fresh machine. `uv run python` bypasses this.

---

## Tool Not Updating

**Symptom:** `uv tool install --force .` ran, but tool still shows old version or old entry point.

**Cause:** Entry points are baked into the wheel at build time. Old build artifacts prevent fresh build.

```powershell
# 1. Verify entry points in pyproject.toml
Select-String -Path pyproject.toml -Pattern "\[project.scripts\]" -A 5

# 2. Clean and reinstall
Remove-Item -Recurse -Force build, dist
Get-ChildItem -Filter "*.egg-info" | Remove-Item -Recurse -Force
uv tool install --force .

# 3. Verify install location
# (Git Bash)
ls ~/.local/share/uv/tools/<package>/
```

---

## Dependency Conflicts

**Symptom:** `uv sync` or `uv add` fails with "cannot resolve dependencies" or "version conflict".

```powershell
# See what's in the lock vs what's installed
git diff uv.lock

# See full dependency tree
uv pip tree

# Force upgrade a specific package
uv add "package>=2.0.0" --upgrade

# Backtracking resolution (slower but more thorough)
uv pip compile pyproject.toml --resolver=backtracking

# Reset lock entirely and re-resolve
Remove-Item uv.lock
uv lock
uv sync
```

---

## Full Diagnosis — Unknown State

When you don't know what's wrong:

```powershell
# Step 1: env health
uv run python --version              # Python version
uv run python -c "import sys; print(sys.prefix)"  # venv path

# Step 2: what's installed
uv pip list                          # all packages
uv pip tree                          # dependency tree

# Step 3: cache state
uv cache clean                       # clear all cached packages

# Step 4: full rebuild
Remove-Item -Recurse -Force .venv
Remove-Item -Recurse -Force build, dist
Get-ChildItem -Filter "*.egg-info" | Remove-Item -Recurse -Force
uv sync

# Step 5: verify
uv run pytest --collect-only         # can pytest find tests?
uv run python -c "import mymodule"   # can the module be imported?
```

---

## Common One-Liners

```powershell
# Clean rebuild everything
Remove-Item -Recurse -Force .venv, build, dist; uv cache clean; uv sync

# Check what version of a tool is running
uv run ruff --version
uv run pytest --version

# Verify a package is importable
uv run python -c "import httpx; print(httpx.__version__)"

# See where a package is installed
uv run python -c "import httpx; print(httpx.__file__)"

# Dependency conflict: what requires what
uv pip show httpx | Select-String "Requires"
```

---

## Stale State Checklist

When something behaves unexpectedly:

- [ ] Is `uv.lock` committed and current? (`git diff uv.lock`)
- [ ] Did `uv sync` run after the last pull?
- [ ] Are build artifacts present? (`ls build/`, `ls dist/`, `ls *.egg-info`)
- [ ] Is the tool installed editable or non-editable? (`uv pip show <pkg>` — look for `Editable`)
- [ ] Is `python` resolving to the right binary? (`uv run python --version`)
- [ ] Is `python3` being used anywhere? (Replace with `python`)
