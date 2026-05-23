# Conformance Linter Spec

Purpose: give agents and reviewers a cheap way to check whether a component's claimed conformance level has visible proof.

## Input

```text
python scripts/check_conformance.py <component_dir> --level <0|1|2|3|4> --json
```

## Minimum checks

| Level | Checks |
|---|---|
| 0 | name/goal present; no hidden destructive side effects declared |
| 1 | typed input/output or schema; structured result; risk class; recovery hints |
| 2 | evidence support; trace ID; conditional next actions; dry-run for mutation; primitive escape hatch for composites |
| 3 | task/session/event/artifact records or adapter hooks; continuation packet; policy-block behavior |
| 4 | versioned contract; compatibility policy; deprecation/migration path; owner/review record |

The reference implementation is `scripts/check_conformance.py`. It has no third-party dependencies and is intentionally conservative: it verifies visible proof, not architectural quality. Reviewers may still require manual review for high-risk components.

Exit codes:

| Code | Meaning |
|---:|---|
| 0 | no errors |
| 1 | warnings only |
| 2 | one or more errors |

## Output shape

```json
{
  "status": "success | partial_success | error",
  "claimed_level": 2,
  "verified_level": 1,
  "findings": [
    {
      "severity": "warn | error",
      "id": "missing-trace-id",
      "message": "Level 2 requires trace ID support.",
      "agent_action": "Add trace_id to result envelope and tests."
    }
  ],
  "evidence": [],
  "trace_id": "trace_...",
  "schema_version": "1.0"
}
```

The linter is a guardrail, not the sole reviewer. Human or agent review may approve scoped exceptions using the escape-hatch process.
