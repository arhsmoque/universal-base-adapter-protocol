# ENV — uv Environment Lifecycle

Covers: project init, venv creation, dep management, Python version pinning, workspaces, lock hygiene.

---

## New Project

```powershell
uv init my-project          # creates pyproject.toml, hello.py, .python-version, .gitignore
cd my-project
uv python pin 3.12          # write 3.12 to .python-version
uv add requests httpx rich  # add runtime deps (auto-syncs)
uv add --dev pytest ruff mypy  # add dev deps under [dependency-groups]
```

`uv init` already runs `uv sync` implicitly. After `uv add`, the venv is up to date — no extra sync needed.

## Existing Project (after clone / pull)

```powershell
uv sync              # install from uv.lock, create .venv if missing
uv sync --frozen     # CI: exact lockfile, no resolution — fails if lock is stale
```

Never run `pip install` after cloning. `uv sync` is the only correct entry point.

---

## Python Version Management

```powershell
uv python install 3.12       # download and install Python 3.12 via uv
uv python install 3.11 3.12  # multiple at once
uv python list               # list all installed versions
uv python pin 3.12           # write to .python-version (commit this file)

# Project-level declaration in pyproject.toml
# requires-python = ">=3.12"

# Per-run override
uv run --python 3.11 python script.py
```

**Rule:** Always have either `.python-version` or `requires-python` in pyproject.toml — never rely on implicit system Python resolution.

**Windows trap:** `python` may resolve to the Windows Store stub that opens the store instead of running Python. `uv run python` bypasses this — use it always.

---

## Dependency Management

### Adding deps

```powershell
uv add httpx                          # latest compatible
uv add "httpx>=0.27.0"               # minimum version
uv add "fastapi>=0.100.0,<1.0.0"     # range constraint
uv add --dev pytest pytest-cov ruff  # dev dep → [dependency-groups] dev
uv add --optional extras httpx       # optional dep group
```

### Removing deps

```powershell
uv remove httpx          # removes from pyproject.toml + updates uv.lock
```

### Updating deps

```powershell
uv lock --upgrade              # upgrade all to latest compatible
uv lock --upgrade-package httpx  # upgrade one package only
uv sync                        # apply updated lock to venv
```

### Dependency groups (modern syntax)

```toml
[dependency-groups]
dev = [
    "pytest>=8.0.0",
    "pytest-cov>=4.0.0",
    "ruff>=0.9.0",
    "mypy>=1.0.0",
]
```

**Not** `[project.optional-dependencies]` for dev tools — that's the old pattern. `uv add --dev` writes to `[dependency-groups]` automatically.

### Lock hygiene

- Commit `uv.lock` — it's the reproducibility guarantee
- Never edit `uv.lock` manually
- Run `uv lock --upgrade` periodically (weekly or before release)
- After pulling changes: `uv sync` to realign venv with new lock

---

## Virtual Environment

```powershell
# uv manages .venv automatically — you rarely need to touch it directly
uv sync             # creates .venv if missing, installs all deps

# Manual creation (rare)
uv venv                         # creates .venv with default Python
uv venv --python 3.12           # specific version
uv venv myenv                   # custom name (default is .venv)

# Activation (for interactive shell use only)
.venv\Scripts\Activate.ps1      # PowerShell (pwsh)
source .venv/bin/activate        # Git Bash

# Always prefer uv run over manual activation for scripted tasks
```

**Rule:** For scripts and CI, always `uv run <cmd>` — never activate + run. Activation is only for interactive development sessions.

---

## Workspace / Monorepo

```toml
# Root pyproject.toml
[tool.uv.workspace]
members = ["packages/*"]

[tool.uv.sources]
mylib = { workspace = true }
```

```toml
# packages/mylib/pyproject.toml
[project]
name = "mylib"
dependencies = ["another-pkg"]

[tool.uv.sources]
another-pkg = { workspace = true }
```

```powershell
uv sync           # syncs all workspace members
uv run pytest     # runs from root, tests all members
```

---

## Git / Local Sources

```toml
[tool.uv.sources]
mylib = { git = "https://github.com/user/mylib", branch = "main" }
locallib = { path = "../locallib", editable = true }
```

```powershell
uv add mylib      # resolves from source defined in [tool.uv.sources]
```

---

## Platform-Specific Dependencies

```toml
[project]
dependencies = [
    "winloop; sys_platform == 'win32'",
    "uvloop; sys_platform != 'win32'",
]
```

Useful on ARH (Windows 11) when a dep has platform-specific wheels or behavior.

---

## Nuke and Rebuild

When the env is genuinely corrupted (rare):

```powershell
Remove-Item -Recurse -Force .venv
uv sync
```

For build artifact cache issues (see DEBUGGING.md for full diagnosis):

```powershell
Remove-Item -Recurse -Force build, dist
uv cache clean
uv sync
```
