# Documentation / Skill Adapter Contract

Use when the capability is packaged as instructions, protocols, playbooks, prompts, or agent skills.

## Required Split

```text
BASE_PROTOCOL.md        invariant doctrine and gates
ADAPTER_<target>.md     CLI/web/MCP/provider/runtime rules
RULES_SCHEMA.md/json    tunable aliases, limits, routing, defaults
PATTERN_REGISTRY.md     source patterns, adoptions, rejections
HOUSEKEEPING.md         cleanup and retention rules
```

## Must Define

- trigger/scope
- what the agent should do first
- boundaries and non-goals
- decision ladder
- output contract
- examples and anti-patterns
- source/provenance expectations
- housekeeping expectations
- when to stop and ask for review

## Guardrails

- Keep runtime instructions compact.
- Put long examples in reference files.
- Keep provider-specific syntax out of the base.
- Record rejected sources to prevent repeat research.
- Do not let a skill become a broad essay that agents skip under pressure.
