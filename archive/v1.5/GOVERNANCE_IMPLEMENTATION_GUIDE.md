# Governance Implementation Guide

Purpose: make Universal Base/Adapter Protocol v1.5 enforceable across Codex, Kimi, Claude, Gemini, and future agents without depending on one agent's private conventions.

## Authority Layers

Apply instructions in this order:

1. Platform and safety policy.
2. Explicit user instruction in the active conversation.
3. Nearest `AGENTS.md` or equivalent project instruction file.
4. Component `METADATA.yml`.
5. Universal Base/Adapter Protocol v1.5.
6. Adapter-specific contract files.
7. Local conventions and examples.

If two layers conflict and neither clearly outranks the other, record a blocked result or ask for review. Do not silently choose the convenient path.

## Adoption Profiles

| Profile | Minimum level | Use for | Required before promotion |
|---|---:|---|---|
| `minimal` | 0 | spikes, notes, prototypes | intent, risk class, smoke or review note |
| `agent_usable` | 1 | reusable local tools and docs | metadata, structured output, non-interactive path |
| `mutation_safe` | 2 | file writes, external writes, generated code | dry-run, idempotency, approval/audit as needed |
| `runtime_integrated` | 3 | workers, MCP servers, recurring workflows | trace IDs, replay, continuation, event/artifact records |
| `platform_primitive` | 4 | shared cross-agent primitives | schemas, owner, deprecation path, conformance check |

System-wide services must reach `platform_primitive` or carry a named escape hatch with owner, expiry, and mitigation.

## Agent-Specific Binding

| Agent family | Required binding |
|---|---|
| Codex | Read `AGENTS.md`, prefer deterministic tools, run relevant checks before final response. |
| Claude | Mirror `AGENTS.md` into `CLAUDE.md` only when the host does not load `AGENTS.md` directly. |
| Gemini | Configure context loading to include `AGENTS.md`; keep model-specific notes in adapter docs. |
| Kimi | Use `AGENTS.md` as the root orientation file and load adapter docs only for the task surface. |

Do not fork protocol doctrine per agent. Agent-specific files may translate invocation details, but the base protocol remains shared.

## Promotion Gate

A component is promoted when:

- `METADATA.yml` is current.
- Claimed conformance level is verified by `python scripts/check_conformance.py <component_dir> --level <n> --json`.
- Required schemas are referenced or embedded.
- Mutation paths have dry-run, approval, idempotency, and audit where risk demands.
- Housekeeping removed scratch/candidate artifacts from active discovery paths.
- Owner and review cadence are recorded for Level 4 components.

## Governance Review

Open a governance review when:

- the protocol and schemas disagree;
- an adapter needs a rule that affects multiple design domains;
- an escape hatch exceeds its expiry or becomes repeated practice;
- an agent-specific file changes doctrine rather than invocation details;
- a component claims Level 4 without schema, owner, and deprecation evidence.

## Rollout Sequence

1. Add root `AGENTS.md` from `templates/AGENTS.template.md`.
2. Add `METADATA.yml` to each promoted component.
3. Classify every component by surface, risk class, risk modifiers, and target profile.
4. Run conformance checks and record gaps.
5. Fix or escape-hatch gaps before system-wide promotion.
6. Re-run checks after toolchain, adapter, or policy changes.
