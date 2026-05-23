> For small components, prefer `METADATA.yml` / `component.manifest.yml`. Use this template when review depth is needed.

# Base/Adapter Design Decision: [Name]

## Goal
-

## Target Surfaces
- Base:
- Adapters:
- Rules/config:

## Surface Classification
- Tool/resource/prompt/CLI/web/worker/doc:
- Risk class:
- Conformance level target:

## Candidate Search
| Candidate | Role | Decision | Why |
|---|---|---|---|

## Selected Approach
- Use:
- Wrap:
- Mechanical port:
- Extract pattern:
- Reject:
- Build from scratch:

## Architecture
```text
[adapter] -> [base] -> [ports] -> [infrastructure]
```

## Contracts
- Input:
- Output:
- Errors:
- State:
- Evidence:
- Trace/artifacts:

## Tests
- Base invariant tests:
- Adapter tests:
- Failure tests:
- Dry-run/idempotency tests:
- Output contract tests:

## Governance
- Owner:
- Version:
- Decision record required? yes/no
- Exception required? yes/no

## Housekeeping
- Keep:
- Archive:
- Delete:

## First Implementation Step
-
