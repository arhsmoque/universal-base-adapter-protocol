# Review Decision Note — Universal Base/Adapter Protocol v1.4

## Verdict

The second review adds useful operational refinements. Most are consistent with v1.3 rather than contradictory.

This is a minor hardening update: it reduces maintenance burden, makes CLI output more chainable, prevents composite result opacity, and lowers documentation token cost.

## Accepted changes

| Review point | Decision | Protocol change |
|---|---|---|
| Prefer wrapping over mechanical porting | Accept with nuance | Salvage ladder now says use/wrap before port; port carries local ownership cost. |
| Composite envelope may hide primitive failures | Accept | Result envelope now includes optional `steps` child records with child trace/evidence/errors. |
| Paperwork overload | Accept | Small components may use `component.manifest.yml/json` as the canonical lightweight record. Markdown templates remain for larger reviews/promotions. |
| Strict schema validation at adapter boundary | Accept | Added boundary validation rule and adapter contract language. |
| JSONL/NDJSON CLI stdout | Accept with nuance | Machine stdout must be one JSON envelope or JSONL/NDJSON; prose/progress goes to stderr/logs. |
| 300-line file constraint | Accept as soft review trigger | Added agent-editability file budget with exceptions for generated/vendor/snapshot/staging files. |
| Dry-run by default for mutation | Already covered, strengthened | Risk table now says local/external mutation uses dry-run/diff preview by default. |
| Duplicated anti-patterns | Partially accept | Main protocol remains canonical; standalone anti-pattern reference becomes a quick pointer/summary, not a second authority. |

## Not accepted as absolute

- Mandatory JSONL for every CLI output: a one-shot command may return one JSON envelope. Streaming/batch commands should use JSONL/NDJSON.
- Hard 300-line limit: useful as an agent-cost heuristic, but ports, generated files, tests, fixtures, and snapshots need exceptions.
- Deleting all Markdown templates: templates are still useful for external review and promotion; lightweight manifest is the default for small work.

## Impact

v1.4 improves agent runtime adherence because it gives agents cheaper compliance paths:
- one manifest for small work;
- parseable CLI output;
- explicit boundary validation;
- step-level composite traceability;
- clearer decision pressure toward wrapping before owning a port.
