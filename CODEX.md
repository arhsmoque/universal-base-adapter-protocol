# Codex Agent Bindings

This file translates `AGENTS.md` for OpenAI Codex-CLI / Codex-hosted agents.
`AGENTS.md` remains the source of doctrine. This file adds **only** Codex-specific invocation rules.

## Read order (Codex)

1. `AGENTS.md` (Codex-CLI loads this automatically — verify the load occurred)
2. `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` — sections relevant to the active surface only
3. The single adapter under `adapters/` (core surfaces) or `advanced/` (LSP/sandbox/skill) for the surface being changed
4. The single template under `templates/` when authoring a packet

Codex-CLI's project-instructions auto-loading means `AGENTS.md` is the canonical entry point — do not duplicate its content here.

## File-mutation authority

- Protocol/schema/adapter changes require a passing conformance run; leave `ESCAPE_HATCH_NOTE.md` if any rule is bypassed.
- Append-only for `JOURNAL.md`. Do not edit files under `archive/`.
- Codex's batch-edit mode must not regenerate templates from scratch — patch surgically.

## Escape-hatch authority

- Codex must emit `ESCAPE_HATCH_NOTE.md` (six conditions) before bypassing any rule.
- The `--ask-for-approval` flag does not substitute for an escape-hatch note.

## Command preferences

- Primary shell: PowerShell 7 (`pwsh`) when available. Codex-CLI runs on Linux/macOS without pwsh — use bash fallback directly:
  ```bash
  python -B scripts/check_conformance.py . --level 4 --json
  ```
  To validate a downstream component (not this repo itself), pass its directory:
  ```bash
  python -B scripts/check_conformance.py /path/to/component --level 1 --json
  ```

## Output style

- Codex-CLI's default verbosity is acceptable; trim aggressively for ARH/G4 contexts.
- JSON first, prose after, for any agent-to-agent artifact.

## Known quirks for Codex in this repo

- Codex's auto-apply mode can rewrite imports unnecessarily — disable for protocol files. Review every import change before accepting.
- File paths must be Windows-style under `D:\00_ARH\`; do not let Codex normalize to POSIX.
- Codex's "explanation" output should not be committed to repository files — keep it in chat.
- Codex may regenerate an entire file when asked to patch a single section — always prefer surgical edits. If Codex rewrites a template or adapter from scratch, reject and retry with an explicit instruction to patch only the named section.
- Codex batch-edit mode does not always preserve trailing newlines or exact indentation — run `python -B scripts/check_conformance.py` after any batch edit to verify schema files are still valid JSON.
- When Codex performs a multi-step task and runs out of context mid-way, it should emit a UBAP continuation packet before stopping rather than silently truncating output.
