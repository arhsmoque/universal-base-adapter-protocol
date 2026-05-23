# Review Decision Note — Universal Base/Adapter Protocol v1.3

## Verdict

Revision is warranted, but as a focused minor update rather than a rewrite. The review did not invalidate the protocol. It identified operational gaps that matter in this environment: Windows/PowerShell-first agents, local MCP/CLI tooling, repeated salvage/refactor work, and long-running multi-agent sessions where replay, budgets, idempotency, and housekeeping determine whether future agents can continue safely.

## Accepted as normative additions

| Review point | Decision | Why |
|---|---|---|
| Re-check base/adapter split after mechanical port | Accept | A port preserves behavior first, but promotion must restore clean boundaries. |
| Move risk before base contract | Accept | Risk affects idempotency, dry-run, audit, rollback, and budget fields. |
| Debugging contract | Accept | Replay, structured logs, and simulation are essential for agent handoff and recovery. |
| Resource budget | Accept | Open-world search, LLM calls, large file scans, and API loops need bounded execution. |
| Idempotency key for external mutation | Accept | Required to make retries safe and auditable. |
| Archive retention limits | Accept | Archives can pollute discovery if not owned and reviewed. |
| Conformance verification | Accept as SHOULD for Level 2+, stronger for Level 3+ | Useful guardrail, but avoid blocking early experiments. |
| Composite vs compiled workflow gate | Accept | Clarifies when a repeated chain becomes a deterministic workflow. |
| Documentation/skill adapter structure | Accept | Runtime skills need compact active guidance plus companion rationale. |

## Accepted as optional patterns

| Review point | Decision | Why |
|---|---|---|
| Event sourcing | Optional for Level 3+ stateful/audit-heavy systems | Too heavy for small stateless tools, valuable for rollback and audit. |
| Hot-reloadable config | SHOULD for daemons/workers/gateways; MAY for CLI | CLI can reread config per run; long-running services need reload/restart policy. |
| justfile/Makefile | Generalized to task-runner contract | Windows-first environments should also allow PowerShell scripts or Taskfile. |

## Deferred or softened

| Review point | Decision | Why |
|---|---|---|
| Remove all redundancy immediately | Softened | Some duplication is useful in runtime docs. v1.3 marks canonical sections and reduces drift risk rather than over-normalizing. |
| Require conformance linter for every project | Softened | Too heavy for experiments; useful before promotion. |

## Net change

v1.3 keeps the same core protocol but adds stronger operational proof:

```text
risk before base contract
post-port placement check
composite vs compiled workflow gate
budget and usage fields
mutation idempotency rule
replay/debug/simulation contract
event sourcing option
versioned rules/config reload guidance
conformance verification guidance
archive retention policy
task-runner contract
```
