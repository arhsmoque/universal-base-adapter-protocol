# Universal Base/Adapter Protocol

Governance-grade design and coding protocol for agent-operated software systems.

This repository defines a shared architecture and review baseline for Codex, Kimi, Claude, Gemini, and other cloud or local agents working across design domains: CLI tools, MCP servers, web/full-stack systems, workers, scripts, documentation systems, and agent skills.

## Core Model

```text
Base = invariant behavior
Adapter = runtime/channel/framework translation
Rules = tunable policy
Metadata = provenance and proof
Housekeeping = part of done
```

The protocol exists to stop agents from repeatedly rediscovering architecture decisions, rewriting solved work, leaking runtime details into core logic, and leaving future agents without evidence.

## Start Here

| Audience | Read first |
|---|---|
| Any coding agent | `AGENTS.md` |
| Protocol reviewer | `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` |
| Governance rollout owner | `GOVERNANCE_IMPLEMENTATION_GUIDE.md` |
| Builder creating a component | `templates/METADATA.yml` and `templates/SPEC_PACKET.md` |
| MCP/tooling author | `adapters/MCP_ADAPTER.md` |
| CLI/tooling author | `adapters/CLI_ADAPTER.md` |
| Documentation/skill author | `adapters/DOCUMENTATION_SKILL_ADAPTER.md` |

## What Is Included

- `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md` - canonical protocol.
- `GOVERNANCE_IMPLEMENTATION_GUIDE.md` - rollout rules for multi-agent governance.
- `METADATA.yml` - repository-level conformance metadata.
- `schemas/` - JSON Schemas for metadata, result envelope, spec packet, and linter output.
- `scripts/check_conformance.py` - dependency-free baseline conformance checker.
- `templates/` - AGENTS, metadata, spec, decision, review, salvage, and housekeeping templates.
- `adapters/` - contracts for CLI, MCP, LSP, sandbox, supply chain, web/full-stack, worker, and documentation/skill surfaces.
- `reference/ANTI_PATTERNS.md` - quick review checklist.

## Conformance Check

Requires Python 3.10+ and no third-party dependencies.

```powershell
python -B scripts/check_conformance.py . --level 4 --json
```

Expected repository baseline:

```json
{
  "status": "success",
  "verified_level": 4,
  "findings": []
}
```

## Adoption Profiles

| Profile | Minimum level | Use for |
|---|---:|---|
| `minimal` | 0 | experiments, notes, prototypes |
| `agent_usable` | 1 | reusable local tools and docs |
| `mutation_safe` | 2 | file writes, external writes, generated code |
| `runtime_integrated` | 3 | workers, MCP servers, recurring workflows |
| `platform_primitive` | 4 | shared cross-agent primitives |

## Agent Entry Points

- `AGENTS.md` is the canonical cross-agent instruction file.
- `CLAUDE.md`, `GEMINI.md`, `KIMI.md`, and `.github/copilot-instructions.md` are thin pointers back to `AGENTS.md`.
- Agent-specific files may translate invocation details, but must not fork protocol doctrine.

## Status

Current package metadata claims Level 4 conformance and is validated by `scripts/check_conformance.py`.

License is intentionally not declared here. Treat this repository as private/internal governance material until an explicit license is added.
