# Kimi Agent Bindings

This file translates `AGENTS.md` for Kimi (Moonshot) agents.
`AGENTS.md` remains the source of doctrine. This file adds **only** Kimi-specific invocation rules.

## Read order (Kimi)

1. `AGENTS.md` (precedence, risk rules, output rules)
2. The single adapter for the active surface under `adapters/`
3. `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` — only the sections referenced from that adapter
4. The single template under `templates/` when authoring a packet

Kimi sessions tend to be longer-lived; refresh the read-order at the start of each task instead of relying on cached context.

## File-mutation authority

- Protocol, schema, or adapter edits require `DECISION_PACKET.md` and a passing conformance run.
- Append-only for `JOURNAL.md`. No rewrites of historical entries.

## Escape-hatch authority

- Kimi must emit a complete `ESCAPE_HATCH_NOTE.md` (six conditions) before bypassing any rule.
- Silent bypasses inside code edits are not valid.

## Command preferences

- Primary shell: PowerShell 7 (`pwsh`).
- Conformance gate before any merge or push:
  ```powershell
  python -B scripts/check_conformance.py . --level 4 --json
  ```

## Output style

- Match Kimi's natural strength in structured planning: emit a short plan, then the diff, then the conformance result.
- JSON first, prose after, for any agent-to-agent artifact.
- Avoid mixing English and Chinese in the same response unless the user does first.

## Known quirks for Kimi in this repo

- Kimi may produce over-engineered abstractions on first pass — prefer the salvage ladder (Use → Wrap → Mechanical Port → Extract → Build).
- Long-context summarization can erase nuance; cite file:line when proposing changes.
- Tool-call schemas must match `schemas/*.schema.json` exactly — do not improvise field names.
