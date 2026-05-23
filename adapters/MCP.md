# MCP Adapter Contract

MCP adapters expose agent-controlled tools, resources, and prompts. The adapter owns tool schema, discovery, and auth extraction. The core owns invariant behavior and safety rules.

---

## 1. Boundary: what belongs where

| Concern | Belongs in | Reason |
|---------|-----------|--------|
| Tool name and description | Adapter | MCP surface concern |
| JSON Schema for tool parameters | Adapter | Runtime format |
| Auth token extraction from request | Adapter | Runtime/platform concern |
| Resource URI routing | Adapter | Discovery surface |
| Prompt template wording | Adapter | Presentation |
| Safety invariants ("never delete without confirmation") | Core | Must hold across all surfaces |
| Business logic triggered by tool call | Core | Must not live in tool handler |
| Idempotency key generation | Core | Must be consistent |
| Error taxonomy | Core | Must be consistent across surfaces |

**Red flag:** if the tool handler contains conditional business logic beyond input extraction and port dispatch, logic has leaked into the adapter.

---

## 2. Tool design rules

**One intent per tool.** A tool named `manage_project` with a `mode` parameter that does create/update/delete depending on the value is a god tool. Split it.

**Name by intent, not topology.** `search_recent_failures` not `database_query_handler`. A stateless agent must infer purpose, risk class, and output shape from the name alone.

**Narrow scope.** Expose only the parameters a caller needs to express intent. Do not mirror every backend field.

**Least privilege.** A read tool must not accept parameters that trigger writes. Scope parameter surface to the operation's actual needs.

**Dry-run for all mutation tools.** Every tool with side effects accepts a `dry_run: boolean` parameter. When `true`, the tool returns `data.plan` describing the change without applying it.

---

## 3. Required envelope for MCP tools

Every tool response must be a valid `result-envelope.json`:

```json
{
  "status": "success | partial_success | failure | blocked | budget_exceeded",
  "data": {},
  "message": "short summary",
  "trace_id": "uuid-or-stable-id",
  "duration_ms": 0,
  "evidence": [],
  "errors": []
}
```

Mutation tools also require: `affected_items`, `dry_run`, `reversible`, `idempotency_key`, `verification`.

---

## 4. Anti-patterns

**God tool with mode parameter**

```json
{
  "name": "manage_resource",
  "parameters": {
    "mode": { "enum": ["create", "read", "update", "delete"] },
    "payload": {}
  }
}
```

Fix: four separate tools — `create_resource`, `get_resource`, `update_resource`, `delete_resource`. Each has its own schema, its own risk class, and its own approval requirements.

**Raw backend API mirror**

```json
{
  "name": "database_query",
  "parameters": {
    "sql": { "type": "string" }
  }
}
```

Fix: expose intent-shaped tools (`search_customers`, `get_order_by_id`). The adapter translates into backend calls. Never expose raw query surfaces to agents.

---

## 5. Minimal compliant tool definition

```python
# mcp_adapter.py (pseudo-structure)

TOOL_DEFINITION = {
    "name": "diagnose_recent_failure",        # snake_case verb_object
    "description": (
        "Inspect the most recent failed run for a component and return "
        "ranked causes with suggested next actions. Read-only."
    ),
    "inputSchema": {
        "type": "object",
        "required": ["component_id"],
        "properties": {
            "component_id": {"type": "string"},
            "limit":        {"type": "integer", "default": 5, "maximum": 20}
        }
    }
}

def handle_diagnose_recent_failure(params: dict) -> dict:
    # Adapter: extract and validate inputs
    component_id = params["component_id"]
    limit = min(params.get("limit", 5), 20)

    # Core call — no MCP knowledge inside
    result = core_port.diagnose_failures(component_id, limit)

    # Adapter: wrap in envelope (core returns data + evidence)
    return {
        "status": "success",
        "data": result["findings"],
        "evidence": result["evidence"],
        "trace_id": result["trace_id"],
        "duration_ms": result["duration_ms"],
        "message": f"{len(result['findings'])} causes ranked",
        "errors": []
    }
```

---

## 6. Composite tools

When a composite tool chains multiple primitives, each step must appear in `steps[]` with its own `trace_id`. See `examples/envelope.composite.json` for the reference shape. Without step-level evidence, a failure inside the composite is undiagnosable.
