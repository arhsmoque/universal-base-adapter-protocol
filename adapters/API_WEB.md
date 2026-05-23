# API / Web Adapter Contract

API and web adapters handle the network boundary. The adapter validates incoming payloads, extracts auth, routes to core ports, and serialises responses. The core owns domain logic and invariants.

---

## 1. Boundary: what belongs where

| Concern | Belongs in | Reason |
|---------|-----------|--------|
| HTTP payload parsing | Adapter | Runtime format |
| Input schema validation | Adapter boundary | Block bad input before core |
| Auth token extraction and verification | Adapter | Runtime/platform concern |
| HTTP status code mapping | Adapter | Runtime contract |
| Request routing | Adapter | Surface concern |
| CORS, rate limiting, caching headers | Adapter | Infrastructure concern |
| Domain validation ("balance must be non-negative") | Core | Business invariant |
| Internal database model serialisation | Core produces, adapter translates | Adapter translates; never exposes raw ORM rows |
| Idempotency key acceptance | Adapter extracts, core enforces | Core owns duplicate-detection logic |
| State transitions | Core | Must be consistent across surfaces |

**Red flag:** if the route handler makes database calls directly without going through a port, the layer is missing.

---

## 2. Output rules

- Every response body is a valid `result-envelope.json` or conforms to a versioned schema declared in METADATA.yml.
- HTTP status codes:

| Status | Use for |
|--------|---------|
| `200` | success or partial_success |
| `400` | user_error (bad input) |
| `401` / `403` | auth failure / permission denied |
| `409` | state_conflict |
| `422` | validation failure (schema mismatch) |
| `429` | budget_exceeded or rate limited |
| `500` | internal_bug |
| `503` | external_failure (dependency down) |

Never return `200` when `status: "failure"` in the envelope. The HTTP status and envelope status must agree.

---

## 3. Payload validation rule

Validate external payloads at the adapter boundary before any core call. Reject with `400` and a structured `errors` array. The core must never receive malformed input — it is allowed to trust adapter-validated inputs.

```json
{
  "status": "failure",
  "message": "Validation failed",
  "errors": [
    { "field": "amount", "message": "must be a positive number", "received": -5 }
  ],
  "trace_id": "req_abc123"
}
```

---

## 4. Anti-patterns

**Internal model leak**

```python
# WRONG — exposes database row directly
@app.get("/users/{id}")
def get_user(id):
    return db.query(User).filter(User.id == id).first().__dict__
```

Fix: map the database model to a versioned response schema at the adapter layer. Callers get a stable contract, not a database snapshot.

**HTTP 200 for all responses**

```python
# WRONG — caller cannot detect failure without parsing body
return JSONResponse({"error": "not found"}, status_code=200)
```

Fix: return `404` with a valid envelope. Machine consumers check HTTP status first, body second.

---

## 5. Minimal compliant handler skeleton

```python
# api_adapter.py (pseudo-structure)

@app.post("/projects/{project_id}/runs")
async def create_run(project_id: str, body: CreateRunRequest, auth: Auth = Depends(extract_auth)):
    # Adapter: validate auth
    if not auth.can("run:create", project_id):
        return envelope_response(status=403, message="Forbidden")

    # Adapter: validate input (Pydantic / schema check already done by type hint)
    port_input = {
        "project_id": project_id,
        "config":     body.config,
        "dry_run":    body.dry_run,
        "idempotency_key": request.headers.get("Idempotency-Key")
    }

    # Core call
    result = core_port.create_run(port_input)

    # Adapter: map to HTTP response
    http_status = {"success": 200, "partial_success": 200, "failure": 500,
                   "blocked": 409}.get(result["status"], 500)
    return JSONResponse(result, status_code=http_status)
```

---

## 6. Mutation controls

For any endpoint that creates, updates, or deletes:
- Accept `Idempotency-Key` header; the core enforces duplicate detection.
- Support a `dry_run` body field; return `data.plan` without applying changes.
- Include `affected_items`, `reversible`, and `verification` in the response envelope.
- Log a structured audit event with `trace_id`, `actor`, `action`, and `result`.
