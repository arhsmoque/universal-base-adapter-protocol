# DESIGN — Python Script and Project Design Patterns

Covers: project structure, type hints, error handling, async patterns, code organization, validation, docstrings, and robust design decisions.

---

## Script vs Project Decision

| Signal | Use script (PEP 723) | Use project (`uv init`) |
|---|---|---|
| Size | < 300 lines | 300+ lines |
| Modules | Single file | Multiple files needed |
| Deps | Few, stable | Many, evolving |
| Distribution | Internal use | Shared / packaged |
| Entrypoints | One main() | Multiple CLI commands |
| Testing | Optional inline | pytest required |
| Config | CLI args / env vars | Config files |

Default: start as a script. Promote to project when you need more than one file.

---

## Project Structure (src layout)

```
my-project/
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── cli.py         ← typer/click entrypoint
│       ├── models.py      ← pydantic / dataclasses
│       ├── services.py    ← business logic
│       └── utils.py       ← shared helpers
├── tests/
│   ├── conftest.py
│   ├── test_models.py
│   └── test_services.py
├── scripts/               ← standalone PEP 723 utilities
│   └── check_health.py
├── pyproject.toml
├── uv.lock
└── .python-version
```

**Src layout** (`src/my_project/`) prevents accidental import of local source instead of the installed package. Use for any project with tests.

Flat layout (no `src/`) is acceptable for small utilities that won't be packaged.

---

## pyproject.toml Structure

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Short description"
requires-python = ">=3.12"
dependencies = [
    "httpx>=0.27.0",
    "rich>=13.0.0",
    "pydantic>=2.0.0",
]

[project.scripts]
my-tool = "my_project.cli:app"   # uv run my-tool

[dependency-groups]
dev = [
    "pytest>=8.0.0",
    "pytest-cov>=4.0.0",
    "ruff>=0.9.0",
    "mypy>=1.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

See `references/pyproject-template.md` for the full canonical template.

---

## Type Hints

Always type-hint function signatures. Target Python 3.12 patterns.

```python
# Basic
def greet(name: str) -> str:
    return f"Hello, {name}"

# Optional / union (3.10+ syntax)
def find(id: int) -> User | None:
    ...

# Collections (3.9+ — use built-ins, not typing module)
def process(items: list[str]) -> dict[str, int]:
    ...

# TypedDict for structured dicts
from typing import TypedDict

class Config(TypedDict):
    host: str
    port: int
    debug: bool

# Dataclass for data containers
from dataclasses import dataclass, field

@dataclass
class Result:
    value: str
    errors: list[str] = field(default_factory=list)
    success: bool = True

# Protocol for duck typing (structural subtyping)
from typing import Protocol

class Serializer(Protocol):
    def serialize(self, data: dict) -> bytes: ...

def save(data: dict, serializer: Serializer) -> None:
    blob = serializer.serialize(data)
    ...

# Immutable value objects
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class Point:
    x: float
    y: float
```

### When to use what

| Need | Use |
|---|---|
| Structured data, validation, JSON | `pydantic.BaseModel` |
| Internal data containers, no validation | `@dataclass` |
| Immutable value objects | `@dataclass(frozen=True, slots=True)` |
| Dict with known keys (typed) | `TypedDict` |
| Callable shapes | `Protocol` |
| Simple string/int constants | `Enum` |

---

## Error Handling

### Custom exception hierarchy

```python
class AppError(Exception):
    """Base — catch-all for this app."""

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str | int):
        super().__init__(f"{resource} not found: {id}")
        self.resource = resource
        self.id = id

class ConfigError(AppError):
    """Invalid or missing configuration."""

class ValidationError(AppError):
    """Input failed domain validation."""
    def __init__(self, message: str, field: str | None = None):
        super().__init__(message)
        self.field = field
```

### Exception handling rules

```python
# ✅ catch specific first, broad last
try:
    result = do_thing()
except NotFoundError:
    return None
except ConfigError as e:
    log.warning("Config problem: %s", e)
    raise
except Exception:
    log.exception("Unexpected error in do_thing")
    raise AppError("Internal error") from None

# ✅ fail fast with clear message
def load_config(path: Path) -> Config:
    if not path.exists():
        raise ConfigError(f"Config not found: {path}")
    ...

# ✅ preserve the chain — never lose the original traceback
try:
    parsed = json.loads(raw)
except json.JSONDecodeError as e:
    raise ConfigError(f"Invalid JSON in {path}") from e

# ❌ don't swallow exceptions silently
try:
    result = risky()
except Exception:
    pass  # never do this

# ❌ don't drop context with bare raise
try:
    risky()
except ValueError:
    raise AppError("Failed")  # loses original traceback — use 'from e'
```

### subprocess error handling (common in ARH scripts)

```python
import subprocess, sys

def run_cmd(cmd: list[str]) -> str:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return r.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {' '.join(cmd)}", file=sys.stderr)
        print(e.stderr, file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"Not found: {cmd[0]}", file=sys.stderr)
        sys.exit(1)
```

---

## Input Validation with Pydantic

Validate early at boundaries. Use Pydantic for complex structured input.

```python
from pydantic import BaseModel, Field, field_validator
from enum import Enum

class OutputFormat(Enum):
    JSON = "json"
    CSV = "csv"
    PARQUET = "parquet"

class CreateUserInput(BaseModel):
    """Input model for user creation."""
    email: str = Field(..., min_length=5, max_length=255)
    name: str = Field(..., min_length=1, max_length=100)
    age: int = Field(ge=0, le=150)

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        if "@" not in v or "." not in v.split("@")[-1]:
            raise ValueError("Invalid email format")
        return v.lower()

    @field_validator("name")
    @classmethod
    def normalize_name(cls, v: str) -> str:
        return v.strip().title()

# Usage at boundary
def create_user(raw: dict) -> User:
    try:
        inp = CreateUserInput.model_validate(raw)
    except ValidationError as e:
        raise ValidationError(str(e)) from e
    return User(email=inp.email, name=inp.name, age=inp.age)
```

---

## Partial Failure Handling

In batch operations, don't let one failure abort everything. Track successes and failures separately.

```python
from dataclasses import dataclass, field

@dataclass
class BatchResult:
    succeeded: list[Item] = field(default_factory=list)
    failed: list[tuple[Item, Exception]] = field(default_factory=list)

def process_batch(items: list[Item]) -> BatchResult:
    result = BatchResult()
    for item in items:
        try:
            processed = process(item)
            result.succeeded.append(processed)
        except Exception as e:
            result.failed.append((item, e))
            log.warning("Failed to process item %s: %s", item.id, e)
    return result

# Caller decides whether to raise or continue
if result.failed:
    log.error("Batch completed with %d failures", len(result.failed))
```

---

## Guard Clauses & Early Returns

Reduce nesting. Validate preconditions and exit early.

```python
# ❌ Deep nesting
def handle(data):
    if data:
        if data.valid:
            if data.active:
                return process(data)
            else:
                return "inactive"
        else:
            return "invalid"
    else:
        return "empty"

# ✅ Guard clauses — flat and readable
def handle(data: Data | None) -> str:
    if not data:
        return "empty"
    if not data.valid:
        return "invalid"
    if not data.active:
        return "inactive"
    return process(data)
```

---

## Context Managers for Resources

Always use `with` for resources that need cleanup.

```python
# ✅ Files, network clients, DB connections, locks
with open(path, "w", encoding="utf-8") as f:
    f.write(content)

with httpx.Client(timeout=30) as client:
    r = client.get(url)

# Custom context manager
from contextlib import contextmanager

@contextmanager
def managed_resource(config: Config):
    conn = create_connection(config)
    try:
        yield conn
    finally:
        conn.close()
```

---

## Docstrings

Write docstrings for all public classes, methods, and functions. Use Google style.

```python
def process_batch(
    items: list[Item],
    max_workers: int = 4,
    on_progress: Callable[[int, int], None] | None = None,
) -> BatchResult:
    """Process items concurrently using a worker pool.

    Processes each item in the batch using the configured number of
    workers. Progress can be monitored via the optional callback.

    Args:
        items: The items to process. Must not be empty.
        max_workers: Maximum concurrent workers. Defaults to 4.
        on_progress: Optional callback receiving (completed, total) counts.

    Returns:
        BatchResult containing succeeded items and any failures with
        their associated exceptions.

    Raises:
        ValueError: If items is empty.
        ProcessingError: If the batch cannot be processed.

    Example:
        >>> result = process_batch(items, max_workers=8)
        >>> print(f"Processed {len(result.succeeded)} items")
    """
    ...
```

**Simple functions** (one line is enough):

```python
def get_user(user_id: str) -> User:
    """Retrieve a user by their unique identifier."""
    ...
```

---

## Async — When and How

Use async when: I/O-bound (HTTP, DB, file), many concurrent operations, or using an async framework.
Don't use async for: CPU-bound work, simple scripts, subprocess calls.

```python
import asyncio
import httpx

async def fetch(url: str) -> dict:
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.get(url)
        r.raise_for_status()
        return r.json()

async def fetch_many(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient(timeout=30) as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)
    return [r.json() for r in responses if not isinstance(r, Exception)]

# Entry point
if __name__ == "__main__":
    result = asyncio.run(fetch("https://api.example.com"))
```

**ARH note:** For simple HTTP scripts, `httpx` (sync) is fine. Go async only when you have multiple concurrent requests that benefit from it.

---

## Logging vs Print

```python
# Scripts: print() is fine for human-readable output
# Libraries and services: use logging

import logging

log = logging.getLogger(__name__)

# Setup (at entry point only, not in library code)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
)

log.info("Processing %d items", len(items))
log.warning("Skipping invalid record: %s", record)
log.error("Failed to connect: %s", err)
```

**Never** use `print()` in library code. Use `logging`. Use `print()` freely in CLI scripts and utility scripts.

---

## Code Organization Principles

**One module, one responsibility.** Don't stuff services, models, and CLI in one file once the project grows.

**Function size:** if a function needs a comment explaining what each block does, split it into named functions.

**Avoid globals** (except module-level constants in UPPER_CASE). Pass state through arguments or dependency injection.

**No defensive coding inside the project.** Validate at the boundary (CLI args, external API responses). Trust your own functions.

```python
# ✅ validate at boundary
def main(path: str) -> None:
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(p)
    process(p)  # no need to re-check inside process()

# ❌ defensive everywhere
def process(p: Path) -> None:
    if p is None:      # unnecessary
        return
    if not p.exists(): # unnecessary if main() already checked
        return
    ...
```

---

## Framework Selection

| Building | Use |
|---|---|
| CLI utility / script | typer (types-based) or argparse (stdlib) |
| HTTP API | FastAPI |
| Full-stack web | Django |
| Simple web / proxy | Flask or FastAPI |
| Data pipeline | polars (fast) or pandas (familiar) |
| Background workers | asyncio tasks or Celery |
| TUI app | Textual |
| Config parsing | pydantic-settings or tomllib (stdlib) |
