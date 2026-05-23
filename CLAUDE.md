# Claude Agent Bindings

This file translates `AGENTS.md` into Claude-Code / Claude-API execution.
`AGENTS.md` remains the source of doctrine. This file adds **only** invocation rules specific to Claude-hosted agents.

## Read order (Claude)

1. `AGENTS.md` (canonical instructions, precedence rules, risk rules)
2. `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` (only the sections relevant to the active surface)
3. The single adapter under `adapters/` (core surfaces) or `advanced/` (LSP/sandbox/skill) for the surface being changed
4. The single template under `templates/` if a packet is being authored

Do not pre-load the full corpus. Progressive disclosure applies: load on demand.

## File-mutation authority

- Mutations to `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md`, schemas, or adapters require a passing `python -B scripts/check_conformance.py . --level 4 --json` and an `ESCAPE_HATCH_NOTE.md` if any protocol rule is bypassed.
- Mutations to templates require updating `JOURNAL.md` with the rationale.
- Never edit `JOURNAL.md` history entries; append only.
- Do not edit files under `archive/`.

## Escape-hatch authority

- Claude may propose escape hatches but must emit a full `ESCAPE_HATCH_NOTE.md` (Named, Scoped, Justified, Bounded, Observable, Recoverable) before any rule is bypassed.
- An escape hatch may not be invoked silently in a code edit.

## Command preferences

- Primary shell: PowerShell 7 (`pwsh`). Use `pwsh` syntax for any new scripts.
- Conformance gate before any merge or push — bash and pwsh both work:
  ```bash
  python -B scripts/check_conformance.py . --level 4 --json
  ```
  To validate a downstream component (not this repo itself), pass its directory:
  ```bash
  python -B scripts/check_conformance.py /path/to/component --level 1 --json
  ```
- JSON-schema parse spot-check (bash):
  ```bash
  find schemas -name '*.json' | xargs -I{} python -m json.tool {} > /dev/null
  ```

## Output style

- Concise. Match the user's tone — terse by default for ARH/G4.
- When proposing edits, lead with **what changes** and **why**; do not summarize the diff back.
- Structured JSON first, prose after, for any agent-to-agent artifact.

## Known quirks for Claude in this repo

- Claude Code on Windows uses Git Bash for `Bash` tool but PowerShell-style paths for the project. Quote Windows paths in Bash.
- Do not chain `cd <repo> && git ...` — git already runs in the working tree; the chain triggers a permission prompt.
- Prefer `Edit` over full-file `Write` for any file already on disk.
- Long sessions risk context compaction: before approaching context limit on a multi-step task, emit a UBAP continuation packet (20b format from ATBIP) so the next session can resume without re-reading prior history.
- Claude's parallel tool calls are efficient but can produce interleaved writes to the same file — always verify file state after parallel `Edit` chains before committing.
- Do not add comments explaining WHAT code does; only add comments for hidden constraints, subtle invariants, or workarounds. Protocol files especially must not accumulate narrative comments.
