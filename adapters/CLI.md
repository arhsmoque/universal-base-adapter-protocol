# CLI Adapter Contract

CLI adapters translate shell input and output into Core / Port calls. The adapter owns the runtime surface; the core owns behavior.

---

## 1. Boundary: what belongs where

| Concern | Belongs in | Reason |
|---------|-----------|--------|
| Flag and argument parsing | Adapter | Runtime format translation |
| Environment variable extraction | Adapter | Runtime/platform concern |
| Exit code mapping | Adapter | Runtime contract |
| Stdout/stderr routing | Adapter | Presentation concern |
| Input sanitisation of CLI args | Adapter boundary | Block bad input before core |
| Domain validation ("amount must be positive") | Core | Business invariant |
| Dry-run diff calculation | Core | Mutation semantics must be stable |
| Error taxonomy | Core | Must be consistent across surfaces |
| Business rules triggered by a flag value | Core | Must not live in flag-parsing code |

**Red flag:** if removing the CLI adapter would break domain logic, domain logic has leaked into the adapter.

---

## 2. Output rules

- **stdout:** exactly one JSON envelope (see `schemas/result-envelope.json`) or a JSONL/NDJSON stream for paginated output. Nothing else.
- **stderr:** human progress, warnings, spinner text, display formatting. Never machine-parseable primary output.
- **Exit codes** (must be stable and documented):

| Code | Meaning |
|------|---------|
| `0` | success |
| `1` | partial_success or warnings present |
| `2` | failure or error |
| `3` | budget_exceeded or blocked |

Never use exit code 0 for a failed operation. Never write JSON to stderr.

---

## 3. Required envelope fields for CLI surface

At minimum, every CLI response must include:

```json
{
  "status": "success | partial_success | failure | blocked | budget_exceeded",
  "data": {},
  "message": "short human summary",
  "trace_id": "stable-id",
  "duration_ms": 0,
  "errors": []
}
```

Mutation operations also require: `affected_items`, `reversible`, `dry_run`, `verification`.

---

## 4. Anti-patterns

**Business rules hidden in flag parsing**

```python
# WRONG — flag value triggers algorithm change inside argument parsing
if args.mode == "fast":
    results = fast_algorithm(args.input)   # domain logic in CLI handler
```

Fix: parse `--mode fast` into a typed input, pass to the core port unchanged. The core decides what `fast` means.

**Interactive prompts with no bypass**

```python
# WRONG — blocks agent execution
answer = input("Are you sure? (y/n): ")
```

Fix: require `--yes` flag for confirmation. Default to dry-run when `--yes` is absent on mutation commands.

---

## 5. Minimal compliant skeleton

```python
# cli_adapter.py
import json, sys, argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("target")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true", default=True)
    args = parser.parse_args()

    # Adapter: translate CLI args into port input
    port_input = {"target": args.target, "dry_run": args.dry_run}

    # Core call — no CLI knowledge inside
    result = core_port.execute(port_input)

    # Adapter: format and route output
    print(json.dumps(result))                          # stdout: machine
    sys.stderr.write(f"done in {result['duration_ms']}ms\n")  # stderr: human

    # Adapter: map status to exit code
    codes = {"success": 0, "partial_success": 1, "failure": 2, "blocked": 3}
    sys.exit(codes.get(result["status"], 2))
```

---

## 6. Dry-run rule

Any CLI command that mutates state must accept `--dry-run` and return a `data.plan` describing what would change, without applying it. The dry-run path must exercise the same core logic as the live path — only the final write is skipped.
