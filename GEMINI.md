# Gemini Agent Bindings

This file translates `AGENTS.md` for Gemini-CLI / Gemini-API agents.
`AGENTS.md` remains the source of doctrine. This file adds **only** Gemini-specific invocation rules.

## Read order (Gemini)

1. `AGENTS.md` (precedence, risk rules, output rules)
2. `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` — sections relevant to the active surface only
3. The single adapter for the active surface under `adapters/`
4. The single template under `templates/` when authoring a packet

Gemini-CLI's large context window encourages loading the full corpus. Do not. Use progressive disclosure.

## File-mutation authority

- Schema, protocol, or adapter changes: require a `DECISION_PACKET.md` and a passing conformance run.
- Gemini may not regenerate `JOURNAL.md` or `REVIEW_DECISION_NOTE_*.md` from scratch — append-only.

## Escape-hatch authority

- Gemini may suggest escape hatches but must emit `ESCAPE_HATCH_NOTE.md` with all six conditions (Named/Scoped/Justified/Bounded/Observable/Recoverable).

## Command preferences

- Primary shell: PowerShell 7 (`pwsh`). Gemini-CLI default-yolo mode is allowed for this repo; risky operations still require an escape hatch note.
- Conformance gate:
  ```powershell
  python -B scripts/check_conformance.py . --level 4 --json
  ```

## Output style

- Avoid Gemini's default tendency to produce long narrative summaries — prefer terse machine-first output.
- For agent-to-agent artifacts, emit JSON first, prose after.
- Do not duplicate text already in `AGENTS.md`.

## Known quirks for Gemini in this repo

- Gemini's tool-use planning may invent tool names — only call protocol-declared commands.
- Gemini's "search-then-write" pattern can over-rewrite — prefer surgical edits.
- File paths must be Windows-style under `D:\00_ARH\`; do not normalize to POSIX silently.
