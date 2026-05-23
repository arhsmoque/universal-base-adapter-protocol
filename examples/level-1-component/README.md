# Level 1 Component Example: `list-project-runs`

This directory shows the minimum structure and output shape for a UBAP Level 1 (operable) component. Use it as a reference when building a new tool.

**Surface:** CLI adapter  
**Risk class:** read_only  
**Conformance:** Level 1

---

## What a Level 1 component requires

| Requirement | Where it lives in this example |
|-------------|-------------------------------|
| Intent and risk declared | `METADATA.yml` — `surface`, `risk_class` |
| Structured output envelope | `cli_adapter.py` — prints JSON to stdout |
| Test or smoke command | `METADATA.yml` — `commands.smoke` |
| Output schema reference | `METADATA.yml` — `contracts.output_schema` |
| Core / Adapter boundary clear | `core/runs.py` (logic) vs `cli_adapter.py` (translation) |

---

## File map

```
list-project-runs/
├── METADATA.yml          ← UBAP metadata (filled, not template)
├── core/
│   └── runs.py           ← Core port: pure logic, no CLI knowledge
├── cli_adapter.py        ← CLI adapter: flag parsing, stdout, exit code
└── tests/
    ├── test_core.py      ← Tests the core without CLI
    └── test_contract.py  ← Tests that output matches result-envelope shape
```

---

## core/runs.py — the core port

```python
# core/runs.py
from dataclasses import dataclass
from typing import List
import time, uuid

@dataclass
class Run:
    id: str
    project_id: str
    status: str
    started_at: str

def list_runs(project_id: str, limit: int = 10) -> dict:
    """Core logic — no CLI, MCP, or HTTP knowledge."""
    # (In a real component this queries a datastore.)
    runs = [
        Run(id="run_001", project_id=project_id, status="success", started_at="2026-05-23T10:00:00Z"),
        Run(id="run_002", project_id=project_id, status="failure", started_at="2026-05-23T11:00:00Z"),
    ][:limit]

    return {
        "runs": [vars(r) for r in runs],
        "total": len(runs),
        "trace_id": f"run_list_{uuid.uuid4().hex[:8]}",
        "duration_ms": 0,   # populated by adapter
    }
```

---

## cli_adapter.py — the adapter

```python
# cli_adapter.py
import argparse, json, sys, time
from core.runs import list_runs

def main():
    parser = argparse.ArgumentParser(description="List runs for a project.")
    parser.add_argument("--project", required=True, help="Project ID")
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--json", action="store_true", default=True)
    args = parser.parse_args()

    t0 = time.monotonic()

    # Adapter: translate flags → core call
    core_result = list_runs(project_id=args.project, limit=args.limit)

    duration_ms = int((time.monotonic() - t0) * 1000)

    # Adapter: assemble result envelope
    envelope = {
        "status": "success",
        "data": {"runs": core_result["runs"], "total": core_result["total"]},
        "message": f"{core_result['total']} runs returned",
        "trace_id": core_result["trace_id"],
        "duration_ms": duration_ms,
        "evidence": [{"type": "project_id", "value": args.project}],
        "warnings": [],
        "errors": [],
        "continuation_token": None,
    }

    # Adapter: stdout = machine, stderr = human
    print(json.dumps(envelope))
    sys.stderr.write(f"[list-project-runs] {core_result['total']} runs in {duration_ms}ms\n")

    # Adapter: exit code from status
    sys.exit(0 if envelope["status"] == "success" else 2)

if __name__ == "__main__":
    main()
```

---

## tests/test_contract.py — output contract test

```python
# tests/test_contract.py
import json, subprocess, sys

REQUIRED_FIELDS = {"status", "data", "message", "trace_id", "duration_ms", "errors"}

def test_output_is_valid_envelope():
    result = subprocess.run(
        [sys.executable, "cli_adapter.py", "--project", "test-project"],
        capture_output=True, text=True
    )
    assert result.returncode == 0
    envelope = json.loads(result.stdout)
    for field in REQUIRED_FIELDS:
        assert field in envelope, f"Missing required field: {field}"
    assert envelope["status"] in {"success", "partial_success", "failure", "blocked", "budget_exceeded"}
    assert isinstance(envelope["errors"], list)
```

---

## Verify conformance

From the UBAP repo root:

```bash
python -B scripts/check_conformance.py examples/level-1-component --level 1 --json
```

Expected: `"verified_level": 1`, `"findings": []`
