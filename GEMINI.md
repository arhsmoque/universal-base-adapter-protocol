# Gemini Agent Bindings

This file translates `AGENTS.md` for Gemini-CLI / Gemini-API agents.
`AGENTS.md` remains the source of doctrine. This file adds **only** Gemini-specific invocation rules.

## Read order (Gemini)

1. `AGENTS.md` (precedence, risk rules, output rules)
2. `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` — sections relevant to the active surface only
3. The single adapter under `adapters/` (core surfaces) or `advanced/` (LSP/sandbox/skill)
4. The single template under `templates/` when authoring a packet

Gemini-CLI's large context window encourages loading the full corpus. Do not. Use progressive disclosure.

## File-mutation authority

- Schema, protocol, or adapter changes: require a passing conformance run; leave `ESCAPE_HATCH_NOTE.md` if any rule is bypassed.
- Gemini may not regenerate `JOURNAL.md` from scratch — append-only. Do not edit files under `archive/`.

## Escape-hatch authority

- Gemini may suggest escape hatches but must emit `ESCAPE_HATCH_NOTE.md` with all six conditions (Named/Scoped/Justified/Bounded/Observable/Recoverable).

## Command preferences

- Primary shell: PowerShell 7 (`pwsh`) when available. Gemini-CLI runs on Linux — use bash fallback directly:
  ```bash
  python -B scripts/check_conformance.py . --level 4 --json
  ```
  To validate a downstream component (not this repo itself), pass its directory:
  ```bash
  python -B scripts/check_conformance.py /path/to/component --level 1 --json
  ```
- Gemini-CLI default-yolo mode is allowed for this repo; risky operations still require an escape hatch note.

## Output style

- Avoid Gemini's default tendency to produce long narrative summaries — prefer terse machine-first output.
- For agent-to-agent artifacts, emit JSON first, prose after.
- Do not duplicate text already in `AGENTS.md`.

## Known quirks for Gemini in this repo

- Gemini's tool-use planning may invent tool names not in the protocol or schema — only call commands listed in METADATA.yml or declared in adapter contracts. If a required tool does not exist, build it rather than fabricating a call.
- Gemini's "search-then-write" pattern can over-rewrite — prefer surgical edits. When asked to update a section, edit only that section; do not regenerate the whole file.
- File paths must be Windows-style under `D:\00_ARH\`; do not normalize to POSIX silently.
- Gemini's large context window makes it tempting to load the full corpus at session start — do not. Progressive disclosure applies: load `AGENTS.md`, then the one relevant adapter, then the one relevant template. Loading everything at once dilutes attention and burns budget.
- Gemini may produce over-confident confidence scores or rankings without evidence — for any UBAP research or design output, all assertions must reference a `verification_probe` or a concrete source. Scores without evidence violate the quality bar.
