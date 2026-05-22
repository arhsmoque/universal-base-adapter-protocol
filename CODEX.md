# Codex Agent Bindings

This file translates `AGENTS.md` for OpenAI Codex-CLI / Codex-hosted agents.
`AGENTS.md` remains the source of doctrine. This file adds **only** Codex-specific invocation rules.

## Read order (Codex)

1. `AGENTS.md` (Codex-CLI loads this automatically — verify the load occurred)
2. `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` — sections relevant to the active surface only
3. The single adapter under `adapters/` for the surface being changed
4. The single template under `templates/` when authoring a packet

Codex-CLI's project-instructions auto-loading means `AGENTS.md` is the canonical entry point — do not duplicate its content here.

## File-mutation authority

- Protocol/schema/adapter changes require a `DECISION_PACKET.md` and a passing conformance run.
- Append-only for `JOURNAL.md` and `REVIEW_DECISION_NOTE_*.md`.
- Codex's batch-edit mode must not regenerate templates from scratch — patch surgically.

## Escape-hatch authority

- Codex must emit `ESCAPE_HATCH_NOTE.md` (six conditions) before bypassing any rule.
- The `--ask-for-approval` flag does not substitute for an escape-hatch note.

## Command preferences

- Primary shell: PowerShell 7 (`pwsh`). Codex-CLI defaults to bash on macOS/Linux — for this repo, prefer `pwsh` invocations even from bash.
- Conformance gate:
  ```powershell
  python -B scripts/check_conformance.py . --level 4 --json
  ```

## Output style

- Codex-CLI's default verbosity is acceptable; trim aggressively for ARH/G4 contexts.
- JSON first, prose after, for any agent-to-agent artifact.

## Known quirks for Codex in this repo

- Codex's auto-apply mode can rewrite imports unnecessarily — disable for protocol files.
- File paths must be Windows-style under `D:\00_ARH\`; do not let Codex normalize to POSIX.
- Codex's "explanation" output should not be committed to repository files — keep it in chat.
