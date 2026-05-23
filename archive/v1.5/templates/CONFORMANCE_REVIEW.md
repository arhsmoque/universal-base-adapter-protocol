> For small components, prefer `METADATA.yml` / `component.manifest.yml`. Use this template when review depth is needed.

# Conformance Review: [Component]

## Target Level
- [ ] Level 0 Experimental
- [ ] Level 1 Agent-Usable
- [ ] Level 2 Agent-Operable
- [ ] Level 3 Runtime-Integrated
- [ ] Level 4 Platform Primitive

## Gates
- [ ] inferable name
- [ ] clear user/agent goal
- [ ] base/adapter/rules split
- [ ] typed inputs
- [ ] structured output/result envelope
- [ ] declared risk class
- [ ] read/write boundary
- [ ] evidence returned
- [ ] conditional next actions only
- [ ] recoverable errors
- [ ] dry-run/idempotency for mutation
- [ ] trace ID/artifact references
- [ ] lifecycle/continuation behavior where needed
- [ ] owner/version/deprecation path where needed
- [ ] housekeeping complete

## Required Artifact

A passing conformance run **must** be attached. Generate with:

```powershell
python -B scripts/check_conformance.py . --level <target> --json --report conformance-report.json
```

The emitted `conformance-report.json` must conform to `schemas/conformance-linter-output.schema.json` and must show `status: success` and `verified_level >= <target>`. Attach the file (or paste its contents) below before promotion.

```json
<paste conformance-report.json here, or commit it next to this review>
```

## Verdict
- Promote / hold / reject:
- Required fixes:
- Reviewer:
- Date:
