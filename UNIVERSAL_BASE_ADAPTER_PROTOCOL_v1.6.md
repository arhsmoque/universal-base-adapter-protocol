# Universal Base/Adapter Protocol (UBAP) v1.6

**Version:** 1.6  
**Status:** Active governance baseline for agent-operated software systems

---

## 0. What UBAP Is

UBAP is a governance-grade design and coding protocol for agent-operated software systems. It is not a framework, package, or runtime. It is a compact set of architectural rules, schemas, templates, conformance checks, and operating habits that help agents build software safely across many surfaces.

UBAP exists because agents often rediscover known architecture decisions, rewrite solved work, mix runtime details into core logic, return prose instead of evidence, and leave workspaces polluted with scratch artifacts. UBAP makes the design explicit, testable, replayable, and cheap for the next agent to continue.

---

## 1. Core Mental Model: Core, Ports, Adapters, Rules

UBAP follows a ports-and-adapters style separation. The core owns invariant behavior. Ports declare the interfaces through which the core is driven or through which it depends on external systems. Adapters translate runtime-specific details into those ports.

| Layer | Owns | Must not own |
|---|---|---|
| **Core / Port layer** | Domain rules, use cases, algorithms, state transitions, invariants, declared interfaces, idempotency semantics, error taxonomy, observability hooks | CLI flags, HTTP payload shapes, MCP schemas, UI form details, platform quirks |
| **Adapter** | CLI flags, HTTP payloads, MCP schemas, auth extraction, platform shims, display formatting, serialization | Business rules, backend invariants, hidden side effects |
| **Rules / Config** | Aliases, defaults, TTLs, budgets, limits, routing policy, feature flags, approval policy | Domain logic or unreviewed behavior changes |
| **Metadata / Provenance** | Source candidates, adoption decisions, dependency ownership, schema version, conformance level, rejected options | Implementation logic |

**Boundary test**

1. Does this contain behavior that must remain true across CLI, API, MCP, UI, and worker surfaces? Put it in the Core / Port layer.
2. Does this translate between runtime formats or frameworks? Put it in an Adapter.
3. Is this a tunable value or policy? Put it in Rules / Config.
4. Is this evidence about why the component exists or how it was adopted? Put it in Metadata / Provenance.

When the boundary is unclear, start with the smallest working separation, then use `reference/PORT_ADAPTER_BOUNDARY_NOTES.md` during refactor or promotion.

---

## 2. Prime Directive

The user expresses intent. The Core / Port layer owns invariant behavior. The Adapter translates runtime, channel, and framework details. Rules / Config hold tunable policy. Metadata records provenance and proof. The result describes observable reality.

Every artifact has two consumers: humans need conceptual clarity; agents need deterministic navigation, stable contracts, tests, structured outputs, and cheap replay.

---

## 3. Surface Types

UBAP recognizes five core surface types. Detailed adapter contracts may live under `adapters/`.

| Surface | Use for | Must avoid |
|---|---|---|
| **Port library** | Reusable core logic and declared interfaces | CLI, MCP, HTTP, UI, or worker assumptions |
| **CLI adapter** | Shell, human, script, and PowerShell-friendly execution | Business logic hidden in flag parsing |
| **API / Web adapter** | Network boundary, browser interaction, service endpoint | Leaking database or internal models directly |
| **MCP adapter** | Agent-controlled action, discovery, resources, and tool calls | Raw backend mirrors, god tools, unscoped executors |
| **Worker adapter** | Async, scheduled, or batch execution | Untracked side effects and unverifiable completion |

Advanced surfaces such as LSP, sandbox, prompt/skill, telemetry exporter, and supply-chain verifier are adapters unless they become their own core component.

---

## 4. Ready-Made First: Multi-Agent Salvage Ladder

Before building new logic, inspect existing tools, libraries, CLIs, services, patterns, and prior project artifacts. Salvage is mandatory for reusable Level 1+ work and may be decomposed across agents.

### Salvage ladder

Apply in order:

1. **Use** — existing tool solves the need; install or call directly.
2. **Wrap** — behavior is good, but the interface is not agent-friendly; create a thin adapter.
3. **Mechanical port** — source is good but the runtime or language is wrong; copy and translate syntax only.
4. **Extract pattern** — dependency is too heavy, unsafe, or broad; rebuild the smallest proven mechanism.
5. **Build from scratch** — no viable source exists.

### Multi-agent salvage workflow

For Level 2 components, the build agent should start from a `salvage_request` produced by a research agent or research protocol run. The request should contain candidate sources, rejected options, pattern sources, gap map, known constraints, and recommended building blocks.

If no research material exists, the build agent may perform only a Level 0 spike or must request a research pass before claiming Level 2 conformance. Rejected candidates must be recorded in `METADATA.yml` so future agents do not rediscover the same dead ends.

### Mechanical porting rule

Preserve control flow, constants, error paths, edge cases, names, and comments. Do not rewrite for taste. A rewrite is allowed only when the source is unsafe, does not solve the need, depends on an unmappable runtime, creates unacceptable maintenance ownership, or tests prove the port cannot be made correct.

After any port, re-check the Core / Port / Adapter boundary. Ported adapter logic that contains domain behavior must be extracted into the Core / Port layer, leaving only the translation shim in the adapter.

---

## 5. Risk Classification

Risk is declared before freezing any contract. Risk changes the design, not only the implementation.

| Risk class | Examples | Required design features |
|---|---|---|
| `read_only` | search, inspect, summarize | evidence, freshness, pagination, budget |
| `local_mutation` | file edit, local cache update | dry-run, diff, idempotency, rollback note |
| `external_mutation` | API write, email send, issue update | approval, idempotency key, audit, replay record |
| `destructive` | delete, revoke, overwrite, payment | staged commit, explicit approval, recovery path |
| `open_world` | shell, network, generated code execution | sandbox, allowlist, timeout, no raw secrets |

Risk modifiers stack on any class.

| Modifier | Extra controls |
|---|---|
| `secret_bearing` | redaction, no raw logs, scoped credentials |
| `regulated_data` | retention limit, access controls |
| `network_access` | allowlist, timeout, SSRF controls |
| `filesystem_broad_scope` | explicit scope, sensitive-path denylist |
| `privileged_auth` | least privilege, approval, audit event |
| `generated_code_execution` | sandbox, no inherited secrets, resource limits |
| `payment_or_cost_impact` | budget, approval, idempotency, rollback path |

Security defaults: least privilege; read and discovery before write; no generic executor unless classified `open_world`; validate external payloads at adapters before they reach the core.

---

## 6. The Art of Naming

Names are part of the interface. A name should let a stateless agent infer purpose, risk, and likely result without opening the file or schema first.

### Naming questions

- What primary action does the caller want?
- Is the name user-facing or agent-facing?
- Does it describe intent rather than backend topology?
- Can a new agent guess the risk class, side effects, and output shape with high confidence?
- Will this name still make sense after the runtime adapter changes?

### Formatting conventions

| Artifact | Convention | Example |
|---|---|---|
| Directory | kebab-case noun phrase | `known-failure-cards/` |
| File or script | kebab-case role phrase | `pre-tool-output-guard.ps1` |
| MCP tool / JSON function | snake_case verb_object[_qualifier] | `diagnose_recent_failure` |
| Python function | snake_case | `create_project_structure` |
| Constant / environment variable | SCREAMING_SNAKE_CASE | `MAX_REPLAY_EVENTS` |
| Resource path | slash-separated hierarchy | `projects/{project}/runs/{run}` |

Stable verbs: `get`, `list`, `search`, `read`, `inspect`, `create`, `update`, `delete`, `prepare`, `apply`, `replay`, `diagnose`, `summarize`, `verify`, `trace`.

Avoid vague names such as `manager`, `helper`, `util`, `runner`, `processor`, and `handler` unless qualified by a precise responsibility. Avoid hidden mutation in read-like names. Avoid provider names in core logic unless the provider is the domain.

See `reference/THE_ART_OF_NAMING.md` for deeper examples.

---

## 7. Result Envelope Standard

Every agent-facing adapter returns structured JSON first. Human prose is a field inside the envelope, not the primary contract.

```json
{
  "status": "success | partial_success | failure | blocked | budget_exceeded",
  "data": {},
  "message": "short human-readable summary",
  "trace_id": "uuid-or-stable-trace-id",
  "duration_ms": 123,
  "evidence": [],
  "warnings": [],
  "errors": [],
  "user_goal_restatement": "short restatement of the requested goal",
  "cost_vs_value": "present when the operation consumed notable budget",
  "reasoning_used": "standard | lazy | user_emulation",
  "continuation_token": null
}
```

Mutation-specific additions include `affected_items`, `user_visible_effect`, `reversible`, `undo`, `verification`, `idempotency_key`, and `approval`.

Composite tools include step records: `step_name`, `status`, `trace_id`, `duration_ms`, `evidence`, `warnings`, and `errors`.

CLI stdout must contain exactly one JSON envelope or a JSONL/NDJSON stream. Human progress, warnings, and display text go to stderr or log artifacts. Exit codes must be stable and documented.

---

## 8. Budget, Continuation, and Handoff

Any operation that can consume unbounded resources must accept a budget. This includes LLM inference, large file reads, recursive search, paginated API calls, fan-out, long-running jobs, and generated-code execution.

A component should return `partial_success` with a continuation token when useful work is complete but more remains. It should return `budget_exceeded` when the minimum safe operation exceeds the provided budget.

Continuation tokens should be compact, opaque, and safe to pass between agents. If the state cannot fit in a token, the token may point to a recorded artifact with access controls and retention policy.

### Multi-agent handoff packet

When Agent A delegates to Agent B, Agent A produces a packet under 500 tokens where possible:

```json
{
  "intent": "string",
  "completed_steps": ["string"],
  "remaining_work": "string",
  "continuation_token": "opaque-string-or-artifact-ref",
  "budget_left": 0,
  "provider_hint": "openai | anthropic | google | any",
  "attachments": ["uri"]
}
```

Agent B must not replay Agent A's full raw history before acting.

---

## 9. Token Efficiency and Cheap Edits

For operations that invoke an LLM or process large context:

- Declare an LLM token or time budget when practical.
- Prefer `edit_mode: diff` over full-file rewrites for mutations.
- Support compression strategies such as `plan_then_expand` or `semantic_truncation` for large context.
- Prefer lazy reasoning for low-risk read-only operations; elevate only when evidence is insufficient.
- Keep files small enough for agents to inspect and modify safely. Files above roughly 300–500 lines should trigger an editability review, not an automatic rewrite.
- Use deterministic navigation first for code edits: language server, symbol index, generated outline, or recorded recipe before broad manual scanning.

---

## 10. Spec Packet

A full spec packet is required for Level 2 components. Level 0 work may use only `METADATA.yml`. Level 1 reusable tools should use compact metadata plus tests.

Minimal Level 2 fields:

```yaml
name: ""
intent: ""
risk_class: ""
surface: ""
input_schema: ""
output_schema: ""
tests: []
llm_token_budget: 0
provider_hint: "any"
reasoning_mode: "standard | lazy | user_emulation"
```

A spec is useful only if it reduces ambiguity. Do not generate heavy paperwork for throwaway code.

---

## 11. Conformance Ladder

| Level | Name | Required proof |
|---|---|---|
| 0 | Experimental | Intent, risk, smoke command |
| 1 | Operable | Structured output, non-interactive path, tests, dry-run for mutation |
| 2 | Platform | Versioned schema, replay, budgets, continuation, verified conformance checklist |

Adoption profiles:

| Profile | Minimum level | Use for |
|---|---:|---|
| `minimal` | 0 | experiments, spikes, notes |
| `agent_usable` | 1 | reusable local tools and docs |
| `mutation_safe` | 1 + mutation controls | file writes and external writes |
| `runtime_integrated` | 2 | workers, MCP servers, recurring workflows |
| `platform_primitive` | 2 | shared cross-agent primitives |

Use `templates/CONFORMANCE_CHECKLIST.yml` for self-checking. Claiming conformance without proof is a protocol violation.

---

## 12. Observability and Replay

Every non-trivial component must produce enough evidence for a later agent to answer: what happened, what inputs were used, what changed, what failed, and what can be retried.

Required for Level 2:

- `events.jsonl` or equivalent structured event stream.
- Command ledger or action record.
- Replay command or documented replay path.
- Trace IDs correlated across logs and artifacts.
- Failure artifact containing input, config, environment summary, and error.
- Continuation packet for interrupted work.

Use OpenTelemetry-compatible concepts where practical: traces for request paths, logs/events for point-in-time records, metrics for aggregate behavior, and baggage/context for correlation.

---

## 13. Scriptable Path Recipes

Every successful non-trivial path is a candidate for future automation. If the same route through the codebase is likely to recur, capture it as a scriptable recipe so the next agent does not need to manually read, trace, infer, and edit from scratch.

For Level 1+ successful builds, the agent should:

1. Review the exact path taken: commands, edits, queries, files, tests, and decisions.
2. Convert recurring steps into a recipe: shell script, PowerShell script, Python script, codemod, MCP tool, or workflow.
3. Replace hardcoded values with inputs.
4. Add dry-run, diff, and verification when the recipe mutates state.
5. Store the recipe under `recipes/` and index it in `recipes/index.yml`.

Minimal recipe record:

```yaml
name: "fix-typo-in-files"
description: "Replace a string across matching files"
inputs:
  - name: old_string
    type: string
  - name: new_string
    type: string
  - name: file_glob
    type: string
execution_strategy: "shell | powershell | python | codemod | mcp | workflow"
dry_run: true
verification: "command or assertion"
```

Promotion rule: two successful uses keep an indexed recipe; three add a task-runner command; five promote to a native tool, codemod, MCP tool, or compiled workflow if the path is stable.

---

## 14. Escape Hatch Doctrine

Rules can be bypassed but never silently. A valid escape hatch is named, scoped, justified, bounded, observable, recoverable, and reviewable.

Record the exception in `ESCAPE_HATCH_NOTE.md`, metadata, or an equivalent decision note. Never bypass safety, mutation, or provenance rules in a code edit without leaving an artifact.

---

## 15. Governance Authority Layers

Precedence order:

1. Explicit user instruction in the active conversation.
2. Nearest `AGENTS.md` or `UBAP_CONFIG.yml`.
3. Protocol defaults.

If two layers conflict with no clear precedence, block or ask for review. Do not silently choose the convenient path.

Provider-specific files such as `CLAUDE.md`, `CODEX.md`, or local editor instructions may translate invocation details, but they must not fork protocol doctrine. If they contradict `AGENTS.md`, `AGENTS.md` wins unless the user explicitly says otherwise.

---

## 16. Done Definition

A component is done when:

- Intent, risk, and surface are declared in metadata or spec.
- Core / Port / Adapter / Rules boundary is clear.
- Structured output envelope exists and is tested.
- Tests cover smoke, failure, output contract, and at least one mutation behavior when applicable.
- Dry-run works for all mutation surfaces.
- A reusable recipe captures the successful path or the work is explicitly marked one-off.
- Medium and large operating workflows have a scale-appropriate Project Agent-Readiness Audit, or an escape hatch explains why it was deferred.
- Housekeeping removes or quarantines scratch artifacts, rejected candidates, temp ports, stale logs, and discovery pollution.

Level 2 additionally requires replay, budget handling, continuation, and verified conformance.

---

## 17. Anti-Patterns

Immediate reject or redesign triggers:

| Anti-pattern | Why it fails |
|---|---|
| Adapter owns domain rules | Breaks portability and testability |
| Core knows CLI, MCP, HTTP, or UI syntax | Leaks runtime into invariant logic |
| Generic shell or eval executor without sandbox | Security risk |
| Raw backend API mirror exposed to agents | Over-exposes surface and increases tool-selection errors |
| Unstructured prose-only output | Not agent-operable |
| Hidden destructive side effects | Unsafe and unreplayable |
| No dry-run for mutation | Unsafe for agent-driven changes |
| No stable IDs or evidence | Cannot continue or verify |
| Huge dependency for tiny behavior | Maintenance and supply-chain bloat |
| Ported code rewritten for taste | Destroys provenance and edge cases |
| Scratch files left in discovery paths | Pollutes future search |
| Conformance claimed without proof | Misleads downstream agents |
| Budgetless recursive search or fan-out | Resource exhaustion |
| Tool names expose topology instead of intent | Poor inferability |
| Provider-specific tool calls in core | Breaks multi-provider portability |
| Repeated deterministic edit without scripting | Burns tokens on menial loops |

---

## 18. Repository Structure

Example structure, not mandatory:

```text
.
├── UNIVERSAL_BASE_ADAPTER_PROTOCOL.md
├── AGENTS.md
├── adapters/
│   ├── CLI.md
│   ├── MCP.md
│   ├── API_WEB.md
│   └── WORKER.md
├── advanced/
│   ├── LSP.md
│   ├── SANDBOX.md
│   └── SKILL.md
├── schemas/
│   ├── result-envelope.json
│   ├── handoff-packet.json
│   └── tool-call-normalized.json
├── templates/
│   ├── METADATA.yml
│   ├── SPEC_PACKET.md
│   ├── CONFORMANCE_CHECKLIST.yml
│   └── ESCAPE_HATCH_NOTE.md
├── recipes/
│   ├── index.yml
│   └── *.ps1 / *.sh / *.py / *.json
├── reference/
│   ├── PORT_ADAPTER_BOUNDARY_NOTES.md
│   ├── THE_ART_OF_NAMING.md
│   └── ANTI_PATTERNS.md
└── JOURNAL.md
```

---

End of UBAP v1.6
