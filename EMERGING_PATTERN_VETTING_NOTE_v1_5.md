# Emerging Pattern Vetting Note v1.5

## Verdict

A final hardening revision is warranted. The reviewed material and external anchors do not overturn the base/adapter doctrine. They add stronger operational requirements for agent-era work: deterministic instructions, deterministic navigation, structured outputs, security by default, supply-chain provenance, and sandboxed mutation.

## Accepted into v1.5

| Pattern | Decision | Reason |
|---|---|---|
| `AGENTS.md` | Accept | Gives agents deterministic project instructions and reduces repeated repo discovery. |
| LSP-first navigation | Accept | Replaces noisy filename/text search with symbol-aware definition/reference lookup. |
| JSON-first handoff | Accept | Makes agent-to-agent and tool-to-agent communication parseable and testable. |
| Spec-first build packet | Accept with scope | Useful as lightweight build oracle; must not become heavy paperwork. |
| Sandbox adapter | Accept | Required for open-world execution and destructive mutation. |
| Token/resource budgets | Already present, strengthened | Needed for recursive search, LLM calls, paging, and large file reads. |
| MCP least privilege and tool minimization | Accept | Aligns with secure MCP operation and agent-operability. |
| CodeDNA headers | Accept as local convention | Not a public standard; useful for low-cost agent navigation. |
| Supply-chain provenance | Accept | Ready-made-first requires dependency ownership, pinning, and provenance checks. |
| OpenTelemetry-shaped observability | Accept with scope | Use concepts and correlation structure without forcing full OTEL stack on tiny tools. |

## Rejected or constrained

| Proposal | Decision | Reason |
|---|---|---|
| Hard maximum 300-line files | Constrain | Use as review trigger, not universal law. Generated, vendored, and staged port files are exceptions. |
| Mandatory full markdown packets for every component | Reject | Use compact `METADATA.yml` for small work; markdown templates only for review depth. |
| Mandatory LSP for every repo | Constrain | Prefer LSP when available. Fall back to grep/search for config/text or when no language server is practical. |
| CodeDNA as external standard | Reclassify | Treat as local metadata convention, not a universal standard. |
| Full SLSA/SSDF compliance for every small tool | Constrain | Apply proportionally by conformance level and risk. |

## Practical effect

v1.5 makes the protocol more agent-operable without bloating the runtime path:

```text
AGENTS.md tells the agent where to start.
LSP tells the agent where symbols actually live.
Spec packet tells the agent what to build.
Result envelope tells the next agent what happened.
Sandbox and budgets keep mistakes bounded.
Provenance records keep salvage from becoming dependency chaos.
Housekeeping keeps discovery clean.
```
