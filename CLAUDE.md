# Claude Agent Bindings

This file translates `AGENTS.md` into Claude-Code / Claude-API execution.
`AGENTS.md` remains the source of doctrine. This file adds **only** invocation rules specific to Claude-hosted agents.

## Read order (Claude)

1. `AGENTS.md` (canonical instructions, precedence rules, risk rules)
2. `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` (only the sections relevant to the active surface)
3. The single adapter under `adapters/` for the surface being changed
4. The single template under `templates/` if a packet is being authored

Do not pre-load the full corpus. Progressive disclosure applies: load on demand.

## File-mutation authority

- Mutations to `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md`, schemas, or adapters require a `DECISION_PACKET.md` and a passing `python -B scripts/check_conformance.py . --level 4 --json`.
- Mutations to templates require updating `JOURNAL.md` with the rationale.
- Never edit `JOURNAL.md` history entries; append only.
- Never edit `REVIEW_DECISION_NOTE_v1_*.md`; create a new one for new revisions.

## Escape-hatch authority

- Claude may propose escape hatches but must emit a full `ESCAPE_HATCH_NOTE.md` (Named, Scoped, Justified, Bounded, Observable, Recoverable) before any rule is bypassed.
- An escape hatch may not be invoked silently in a code edit.

## Command preferences

- Primary shell: PowerShell 7 (`pwsh`). Use `pwsh` syntax for any new scripts.
- Conformance gate before any merge or push:
  ```powershell
  python -B scripts/check_conformance.py . --level 4 --json
  ```
- JSON-schema parse spot-check:
  ```powershell
  Get-ChildItem -LiteralPath schemas -Filter '*.json' | ForEach-Object { python -m json.tool $_.FullName > $null }
  ```

## Output style

- Concise. Match the user's tone — terse by default for ARH/G4.
- When proposing edits, lead with **what changes** and **why**; do not summarize the diff back.
- Structured JSON first, prose after, for any agent-to-agent artifact.

## Known quirks for Claude in this repo

- Claude Code on Windows uses Git Bash for `Bash` tool but PowerShell-style paths for the project. Quote Windows paths in Bash.
- Do not chain `cd <repo> && git ...` — git already runs in the working tree; the chain triggers a permission prompt.
- Prefer `Edit` over full-file `Write` for any file already on disk.
