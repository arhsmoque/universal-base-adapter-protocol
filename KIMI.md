# Kimi Agent Bindings

This file translates `AGENTS.md` for Kimi (Moonshot) agents.
`AGENTS.md` remains the source of doctrine. This file adds **only** Kimi-specific invocation rules.

## Read order (Kimi)

1. `AGENTS.md` (precedence, risk rules, output rules)
2. The single adapter under `adapters/` (core surfaces) or `advanced/` (LSP/sandbox/skill)
3. `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` — only the sections referenced from that adapter
4. The single template under `templates/` when authoring a packet

Kimi sessions tend to be longer-lived; refresh the read-order at the start of each task instead of relying on cached context.

## File-mutation authority

- Protocol, schema, or adapter edits require a passing conformance run; leave `ESCAPE_HATCH_NOTE.md` if any rule is bypassed.
- Append-only for `JOURNAL.md`. No rewrites of historical entries. Do not edit files under `archive/`.

## Escape-hatch authority

- Kimi must emit a complete `ESCAPE_HATCH_NOTE.md` (six conditions) before bypassing any rule.
- Silent bypasses inside code edits are not valid.

## Command preferences

- Primary shell: PowerShell 7 (`pwsh`) when available. Kimi runs on Linux — use bash fallback directly:
  ```bash
  python -B scripts/check_conformance.py . --level 4 --json
  ```
  To validate a downstream component (not this repo itself), pass its directory:
  ```bash
  python -B scripts/check_conformance.py /path/to/component --level 1 --json
  ```

## Output style

- Match Kimi's natural strength in structured planning: emit a short plan, then the diff, then the conformance result.
- JSON first, prose after, for any agent-to-agent artifact.
- Avoid mixing English and Chinese in the same response unless the user does first.

## Known quirks for Kimi in this repo

- Kimi may produce over-engineered abstractions on first pass — prefer the salvage ladder (Use → Wrap → Mechanical Port → Extract → Build). If a design has more than three new components, re-examine whether existing tools cover the need.
- Long-context summarization can erase nuance; cite file:line when proposing changes to any protocol file.
- Tool-call schemas must match `schemas/result-envelope.json` and `schemas/handoff-packet.json` exactly — do not improvise field names.
- Kimi's planning output can grow very long; keep the RBSP decision panel under 250 lines and the ATBIP handoff under 150 lines. Depth belongs in referenced artifacts, not in the primary document.
- Kimi sessions are often long-lived but the agent is stateless between calls — refresh the read order at the start of each task. Do not assume prior context is available.
- When Kimi deviates from RBSP design during implementation, it must record a deviation entry immediately rather than deferring to the handoff. Silent in-flight deviations cannot be recovered at review time.
