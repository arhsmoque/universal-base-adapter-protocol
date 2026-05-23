# Multi-Agent Handoff Example: A → B

This example shows the full cycle of a UBAP mid-task handoff between two agents.

**Scenario:** Agent A (Codex) is performing a Level 1 build of a `search-project-artifacts` MCP tool. It processes steps 1-6 of the ATBIP build order, then hits its context budget. It emits a UBAP continuation packet. Agent B (Claude) cold-starts, reads the packet, and resumes at step 7.

---

## What Agent A completed (steps 1–6 of ATBIP §6)

1. Scaffolded `METADATA.yml` from RBSP decision panel fields
2. Built core logic in `core/artifacts.py`
3. Added state/config layer (none needed — stateless)
4. Built result envelope in `core/result.py`
5. Built read operations: `search_artifacts`, `get_artifact_by_id`
6. Built dry-run planner for future delete operation (not yet implemented)

---

## Agent A's continuation packet (emitted before context limit)

Agent A writes this to stdout or to an artifact before stopping. Format matches `schemas/handoff-packet.json`.

```json
{
  "intent": "Build a Level 1 MCP adapter for search-project-artifacts that exposes search and get operations with structured envelopes and dry-run for delete",
  "completed_steps": [
    "Scaffolded METADATA.yml with surface=mcp_adapter, risk_class=read_only, conformance_target=1",
    "Built core/artifacts.py: search_artifacts() and get_artifact_by_id() with result envelope",
    "Built core/result.py: assemble_envelope() helper, error taxonomy",
    "Built read operations: search passes filters, get returns single record or 404-equivalent error",
    "Dry-run planner for delete stubbed at core/artifacts.py:delete_artifact_plan()"
  ],
  "remaining_work": "Step 7: build mcp_adapter.py with TOOL_DEFINITION for search_artifacts, get_artifact_by_id, and delete_artifact (dry-run only for now). Step 8: add smoke test and contract test. Step 9: run conformance check at level 1.",
  "continuation_token": null,
  "budget_left": 0,
  "provider_hint": "anthropic",
  "attachments": [
    "search-project-artifacts/METADATA.yml",
    "search-project-artifacts/core/artifacts.py",
    "search-project-artifacts/core/result.py"
  ]
}
```

---

## What Agent B does on cold start

Agent B receives the packet (from a file, message, or handoff record). It does **not** re-read URP or RBSP. It does not repeat the completed steps.

**Agent B's read order:**
1. Read the continuation packet
2. Load `attachments` listed in the packet
3. Resume at `remaining_work`: build `mcp_adapter.py`

**Agent B must not:**
- Re-research the problem
- Redesign the architecture
- Repeat steps 1–6
- Claim a different surface or risk class than what METADATA.yml declares

---

## Agent B resumes: mcp_adapter.py skeleton

```python
# mcp_adapter.py — Agent B picks up here
from core.artifacts import search_artifacts, get_artifact_by_id, delete_artifact_plan
from core.result import assemble_envelope

TOOL_DEFINITIONS = [
    {
        "name": "search_artifacts",
        "description": "Search project artifacts by query string and optional filters. Read-only.",
        "inputSchema": {
            "type": "object",
            "required": ["project_id", "query"],
            "properties": {
                "project_id": {"type": "string"},
                "query":      {"type": "string"},
                "limit":      {"type": "integer", "default": 10, "maximum": 50}
            }
        }
    },
    {
        "name": "get_artifact_by_id",
        "description": "Retrieve a single artifact by stable ID. Read-only.",
        "inputSchema": {
            "type": "object",
            "required": ["artifact_id"],
            "properties": {
                "artifact_id": {"type": "string"}
            }
        }
    },
    {
        "name": "delete_artifact",
        "description": "Plan or apply deletion of an artifact. Dry-run is default.",
        "inputSchema": {
            "type": "object",
            "required": ["artifact_id"],
            "properties": {
                "artifact_id": {"type": "string"},
                "dry_run":     {"type": "boolean", "default": true}
            }
        }
    }
]

def handle_search_artifacts(params):
    result = search_artifacts(params["project_id"], params["query"], params.get("limit", 10))
    return assemble_envelope("success", data=result)

def handle_get_artifact_by_id(params):
    result = get_artifact_by_id(params["artifact_id"])
    if result is None:
        return assemble_envelope("failure", errors=[{"error_type": "user_error", "message": "Artifact not found"}])
    return assemble_envelope("success", data=result)

def handle_delete_artifact(params):
    plan = delete_artifact_plan(params["artifact_id"])
    if params.get("dry_run", True):
        return assemble_envelope("success", data={"plan": plan, "dry_run": True})
    # live delete: not yet implemented — return blocked
    return assemble_envelope("blocked", message="Live delete not yet implemented; use dry_run=true")
```

---

## Agent B's completion summary (§20a)

```markdown
# ATBIP Completion Summary: search-project-artifacts

## Built artifacts
- Files: core/artifacts.py, core/result.py, mcp_adapter.py, tests/test_contract.py
- Commands: python -m pytest tests/ -q
- METADATA.yml: search-project-artifacts/METADATA.yml
- UBAP conformance: verified_level=1, target=1, gate=pass

## Verification
- Smoke test: python -c "from mcp_adapter import handle_search_artifacts; print(handle_search_artifacts({'project_id':'x','query':'y'}))"
- Probe result: pass — returns valid result envelope
- All required tests passed: yes

## Deviations from RBSP
| Deviation | Reason | Risk | Reopen if | ESCAPE_HATCH_NOTE? |
|-----------|--------|------|-----------|---------------------|
| delete_artifact returns blocked instead of live delete | Not in scope for Level 1 | Low | User requests live delete | No — RBSP did not require live delete at Level 1 |

## Recipe captured
- recipes/index.yml entry: no — one-off build; path not recurrent enough to index

## Known limitations
- delete_artifact dry-run only; live path not implemented

## Next actions for maintainer
- Implement live delete path when ready; add approval gate before applying
- Promote to Level 2 when replay and continuation are added
```

---

## Key rules demonstrated

1. Agent B did not re-read URP or RBSP — continuation packet was sufficient.
2. The handoff packet is under 500 tokens (§8 of UBAP).
3. `attachments` pointed to the exact files B needed; B loaded only those.
4. Agent B's completion summary (20a) is separate from the continuation packet (20b).
5. The deviation was recorded with a clear "Reopen if" condition, and no ESCAPE_HATCH_NOTE was required because no UBAP protocol rule was bypassed.
