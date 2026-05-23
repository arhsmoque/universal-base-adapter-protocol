# SCRIPTS — PEP 723 Standalone Scripts with uv

Use for self-contained utilities: one file, inline deps, no separate project needed.
When a script exceeds ~300 lines or needs multiple modules → switch to a proper uv project.

---

## Canonical Template

```python
#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "httpx>=0.27.0",
#   "rich>=13.0.0",
# ]
# ///
"""
One-line description of what this script does.

Usage:
    python script_name.py [OPTIONS]

Examples:
    python script_name.py --help
    python script_name.py --input data.json
"""
import sys
from pathlib import Path


def main() -> None:
    ...


if __name__ == "__main__":
    main()
```

---

## Shebang Options

```python
#!/usr/bin/env -S uv run --script            # standard
#!/usr/bin/env -S uv run --script --quiet    # suppress uv's own output (production)
#!/usr/bin/env -S uv run --script --python 3.12  # force Python version
```

**ARH note:** On Windows, shebangs don't work natively. Run as: `uv run --script script.py`
On Git Bash / WSL, the shebang works. For pwsh scripts, always use `uv run --script`.

---

## Running Scripts

```powershell
# Run with inline deps (uv resolves and caches automatically)
uv run --script my_tool.py
uv run --script my_tool.py --arg value

# If shebang is set and on Unix/Bash:
./my_tool.py

# With explicit Python version
uv run --script --python 3.12 my_tool.py
```

---

## Inline Metadata Rules

### ✅ Valid `[tool.uv]` fields in script block

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx>=0.27.0"]
# [tool.uv]
# exclude-newer = "2025-01-01T00:00:00Z"  # reproducibility: ignore newer packages
# ///
```

### ❌ Never use `[tool.uv.metadata]`

```python
# /// script
# [tool.uv.metadata]    # ← DOES NOT EXIST — will cause parse error
# purpose = "testing"
# ///
```

Put metadata (purpose, author, team) in the module docstring instead:

```python
"""
Check ARH service health.

Purpose: infrastructure-monitoring
Author: smoque@gmail.com
"""
```

---

## Naming Conventions

```
check_service_health.py     ✅ descriptive, snake_case, action-oriented
validate_tender_doc.py      ✅ clear purpose
sync_board_state.py         ✅ specific
script.py                   ❌ too generic
util.py                     ❌ too generic
my_script2.py               ❌ no versioning in filename
```

---

## Common Dependency Patterns

```python
# CLI apps
"typer>=0.9.0"           # modern CLI with types
"click>=8.0.0"           # classic CLI
"rich>=13.0.0"           # beautiful terminal output
"textual>=0.47.0"        # TUI apps

# HTTP
"httpx>=0.27.0"          # async HTTP (preferred)
"requests>=2.31.0"       # sync HTTP

# Data
"polars>=0.20.0"         # fast dataframes
"pandas>=2.0.0"          # classic dataframes
"pydantic>=2.0.0"        # validation / parsing

# System
"psutil>=5.9.0"          # process / system info
"watchdog>=3.0.0"        # filesystem events

# JSON / config
"tomllib"                # stdlib 3.11+, no dep needed
"pyyaml>=6.0"            # YAML parsing
"jaq" / "jq"             # on ARH: use jaq (jq not installed)
```

---

## Script Design Patterns

### CLI with typer

```python
#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.12"
# dependencies = ["typer>=0.9.0", "rich>=13.0.0"]
# ///
import typer
from rich.console import Console

app = typer.Typer()
console = Console()

@app.command()
def main(
    name: str = typer.Argument(..., help="Target name"),
    verbose: bool = typer.Option(False, "--verbose", "-v"),
) -> None:
    """Do the thing."""
    if verbose:
        console.print(f"[dim]Processing {name}[/dim]")
    console.print(f"[green]Done: {name}[/green]")

if __name__ == "__main__":
    app()
```

### HTTP client

```python
#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx>=0.27.0"]
# ///
import httpx
import sys

def fetch(url: str) -> dict:
    with httpx.Client(timeout=30) as client:
        r = client.get(url)
        r.raise_for_status()
        return r.json()

if __name__ == "__main__":
    url = sys.argv[1] if len(sys.argv) > 1 else "https://api.github.com"
    print(fetch(url))
```

### Subprocess caller (common in ARH)

```python
import subprocess
import sys

def run(cmd: list[str]) -> str:
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"Command not found: {cmd[0]}", file=sys.stderr)
        sys.exit(1)
```

---

## When NOT to Use a Single-File Script

Switch to a proper `uv init` project when:
- Script exceeds ~300 lines
- Multiple modules needed (shared helpers, models, services)
- Needs packaging or distribution (`uv build`)
- Long-running service / daemon
- Requires complex configuration management
- Shared library code across multiple scripts

---

## Version Pinning Strategy

```python
# dependencies = [
#   "httpx>=0.27.0",      # minimum — most flexible, allows updates
#   "rich~=13.0",         # compatible release — allows 13.x, not 14.x
#   "tomllib==2.0.1",     # exact — use for reproducibility-critical tools
# ]
```

Default: `>=X.Y.Z` (minimum). Use `~=` for stable APIs you rely on. Use `==` only for scripts that must be bit-reproducible.
