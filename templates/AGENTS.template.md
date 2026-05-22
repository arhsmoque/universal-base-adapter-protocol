# AGENTS.md

## Scope & Precedence

- This file governs agent behavior for this repository or subtree.
- Explicit user instructions in the active conversation override this file.
- A nested `AGENTS.md` closer to the edited file overrides this file for that subtree.
- Tool/platform safety policy overrides project instructions.
- If instructions conflict and no precedence rule resolves it, stop and ask.
- Keep this file short; link to deeper docs instead of embedding long process manuals.
- Owner:
- Review cadence:
- Last verified:

## Build & Test

- Install:
- Test:
- Lint:
- Format:
- Type check:
- Smoke test:

## Task Runner

- `test`:
- `lint`:
- `format`:
- `dry-run`:
- `replay`:
- `housekeeping`:

## Architecture Map

- Base logic:
- Adapters:
- Rules/config:
- Tests:
- Decision/metadata:
- Generated/scratch:

## Protocol

This project follows Universal Base/Adapter Design and Coding Protocol v1.5.

Required invariants:

- keep base free of CLI/MCP/HTTP/UI syntax;
- validate adapter inputs before base;
- return structured result envelopes for agent-facing outputs;
- use ready-made-first salvage ladder before new implementation;
- prefer LSP/symbol navigation before broad grep for code;
- use dry-run/approval/idempotency for mutation;
- clean scratch and candidate files before done.
- record escape hatches when a protocol rule is bypassed.
- follow the project naming convention so agents can discover artifacts by name without opening them;

## Risk Rules

- Read-only operations:
- Local mutation:
- External mutation:
- Destructive/open-world operations:
- Risk modifiers: `secret_bearing`, `regulated_data`, `network_access`, `filesystem_broad_scope`, `privileged_auth`, `generated_code_execution`, `payment_or_cost_impact`.

## Output Rules

- Machine stdout:
- Human/progress output:
- Logs/artifacts:

## Housekeeping

- Archive retention:
- Scratch paths:
- Candidate/source cache paths:
- Files excluded from ordinary discovery:
- Conformance check: `python scripts/check_conformance.py . --level <0|1|2|3|4> --json`

## Scriptable Path Recipes

- Recipe index:
- Successful-path capture location:
- When to add a recipe:
- Dry-run command convention:
- Apply command convention:
- Verify command convention:
- Deprecated recipe cleanup path:
