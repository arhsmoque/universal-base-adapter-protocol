# Universal Base/Adapter Design and Coding Protocol v1.5

**Purpose:** A general design and coding protocol for web apps, full-stack systems, CLI tools, MCP servers, automations, workers, scripts, agent skills, and documentation systems.

**Version stance:** v1.5 is the final hardening pass from the emerging-pattern review. It keeps v1.4's core doctrine, then adds agent-era operating standards: `AGENTS.md`, LSP-first navigation, spec-first build packets, sandbox/approval adapters, supply-chain provenance, secure-by-design defaults, and structured telemetry.

**Core stance:** Build the stable mechanism once. Attach runtime-specific adapters around it. Search for ready-made battle-tested implementations before writing new code. Prefer **use → wrap → port → extract pattern → build**. Treat housekeeping, evidence, budgets, validation, continuation, governance, and cleanup as part of the design, not afterthoughts.

**Companion docs:**

- `RATIONALE_AND_ESCAPE_HATCH_GUIDE.md` — why the rules exist and how to escape safely.
- `EMERGING_PATTERN_VETTING_NOTE_v1_5.md` — what was accepted from the emerging-pattern review and why.
- `GOVERNANCE_IMPLEMENTATION_GUIDE.md` — rollout rules for multi-agent governance.
- `templates/AGENTS.template.md` — repository instruction layer for coding agents.
- `templates/SPEC_PACKET.md` — spec-first build packet.
- `templates/METADATA.yml` — compact component metadata.
- `templates/SCRIPTABLE_PATH_RECIPE.md` — replayable path recipe for repeated edits or similar tool development.
- `schemas/` — machine-readable metadata, spec, result-envelope, and linter-output schemas.
- `scripts/check_conformance.py` — dependency-free baseline conformance checker.

---

## 0. Prime Directive

```text
The user expresses intent.
The base owns invariant behavior.
The adapter translates runtime/channel/framework details.
Rules/config hold tunable policy.
The result describes observable reality.
The framework handles bookkeeping, continuation, and cleanup.
```

Do not let a delivery surface become the architecture.

A CLI command, HTTP route, React page, MCP tool, cron job, WhatsApp bot, VS Code extension, GitHub Action, queue worker, or agent skill is an adapter. The reusable capability belongs in the base.

### Dual-consumer rule

Every artifact is now read by two consumers:

1. humans who need conceptual clarity; and
2. agents that need deterministic navigation, contracts, tests, and structured outputs.

Therefore, prefer explicit contracts over tacit convention, short navigable files over clever monoliths, machine-readable metadata over prose-only explanations, and replayable commands over manual setup rituals.

---

## 1. Universal Shape

```text
[User / Agent / External Caller]
        |
        v
[Adapter: CLI | Web | API | MCP | Worker | Skill | Docs | LSP | Sandbox]
        |
        v
[Base Engine: invariant domain behavior]
        |
        +--> [Ports: storage, network, filesystem, model, queue, auth]
        |          |
        |          v
        |    [Infrastructure Adapters]
        |
        v
[Result Envelope + Evidence + Trace + Artifacts + Usage]
```

### Base owns

- domain rules that remain true across runtimes;
- state transitions and lifecycle rules;
- core algorithms and deterministic engines;
- validation of internal invariants;
- stable input/output models;
- error taxonomy;
- idempotency behavior;
- observability hooks as interfaces;
- testable pure or near-pure logic.

### Adapters own

- CLI flags, HTTP payloads, MCP schemas, UI forms, queue messages;
- auth/session extraction and channel-specific identity mapping;
- platform quirks: Windows, PowerShell, browser, shell, container, cloud;
- display formatting and response translation;
- runtime-specific compatibility shims;
- adapter-specific validation before crossing into the base.

### Rules/config own

- aliases and command vocabulary;
- defaults, TTLs, limits, thresholds;
- routing policy;
- feature flags;
- retention policy;
- approval policy;
- adapter syntax and operator-tunable behavior.

### Provenance/metadata own

- source candidates inspected;
- adoption decision: use/wrap/port/extract/reject/build;
- dependency ownership and lock/provenance notes;
- schema version, conformance level, risk class;
- validation and smoke-test commands.

### Boundary test

```text
Is this invariant mechanics?         -> base
Is this runtime/channel translation? -> adapter
Is this operator-tunable policy?     -> rules/config
Is this source/provenance evidence?  -> metadata/decision registry
Is this one-off scratch behavior?    -> temporary workspace, then delete or promote
```

If the answer is mixed, split the boundary before adding the feature.

---

## 2. Required Project Instruction Layer: `AGENTS.md`

Every maintained project should contain a root `AGENTS.md` or equivalent agent instruction file.

`README.md` explains the project to humans. `AGENTS.md` gives agents deterministic operating instructions:

- install/build/test/lint/type-check commands;
- known safe task-runner commands;
- code style and formatter rules;
- base/adapter/rules directory map;
- risk, mutation, and approval rules;
- result envelope and JSON/JSONL output rules;
- housekeeping and archive policy;
- links to the governing protocol and templates.

Housekeeping includes verifying that `AGENTS.md` commands still work. If the project cannot provide `AGENTS.md`, the nearest equivalent must be referenced in `METADATA.yml`.

---

## 3. Surface Classification Before Design

Classify the surface before naming or coding it.

| Surface | Use for | Must avoid |
|---|---|---|
| Base library | reusable logic | CLI/MCP/HTTP/UI assumptions |
| CLI adapter | shell/human/script execution | business logic hidden in flag parsing |
| Web/UI adapter | user interaction and presentation | backend invariants in components |
| API adapter | network boundary | leaking database/internal models directly |
| MCP adapter | agent-controlled action | raw backend mirrors and god tools |
| Worker adapter | async/batch execution | untracked side effects |
| Prompt/skill adapter | reusable agent procedure | hidden execution side effects |
| Resource/document | inspectable context | mutation/workflow execution |
| LSP adapter | deterministic code navigation | replacing semantic symbol lookup with noisy grep |
| Sandbox adapter | staged mutation and approval | committing dangerous changes directly |

Do not turn everything into a tool. Prompts guide, resources inform, tools act.

---

## 4. Risk and Security Before Contract

Declare risk before freezing the base contract. Risk changes the base shape.

| Risk class | Examples | Required design features |
|---|---|---|
| `read_only` | search, inspect, summarize | evidence, freshness, pagination, budget |
| `local_mutation` | file edit, local cache update | dry-run, diff, idempotency, rollback note |
| `external_mutation` | API write, ticket update, email send | approval, idempotency key, audit, replay record |
| `destructive` | delete, revoke, overwrite, payment | staged commit, explicit approval, recovery path |
| `open_world` | shell, network, generated code | sandbox, allowlist, timeout, no raw secrets |

Risk modifiers may be added to any class when they affect controls:

| Modifier | Use when | Extra controls |
|---|---|---|
| `secret_bearing` | credentials, tokens, private keys, or session material may be present | redaction, no raw logs, scoped credentials |
| `regulated_data` | personal, financial, health, client-confidential, or contractual data is present | retention limit, access controls, disclosure note |
| `network_access` | operation can call remote systems | allowlist, timeout, SSRF controls where relevant |
| `filesystem_broad_scope` | operation can read/write outside a narrow project scope | explicit scope, denylist for sensitive paths, dry-run for writes |
| `privileged_auth` | operation uses admin, owner, production, or high-scope credentials | least privilege, approval, audit event |
| `generated_code_execution` | model- or user-generated code may run | sandbox, no inherited secrets, resource limits |
| `payment_or_cost_impact` | operation can spend money or allocate paid resources | budget, approval, idempotency, rollback/removal path |

Security posture:

- least privilege by default;
- read/discovery scope before write scope;
- no generic executor unless explicitly classified `open_world`;
- no inherited secret environment for agent-written code;
- validate external payloads at adapters;
- do not let untrusted text become tool arguments without schema validation and allowlists;
- record audit events for mutation and approval.

---

## 5. Ready-Made First Salvage Ladder

Never start from blank design when an existing implementation or battle-tested pattern may exist.

Apply this ladder in order:

| Rank | Decision | Use when | Coding posture |
|---|---|---|---|
| 1 | **Use** | Existing tool solves the need with acceptable fit | Install/call directly; write smoke test |
| 2 | **Wrap** | Tool works but interface is not agent/runtime-friendly | Thin adapter around stable dependency |
| 3 | **Mechanical port** | Source is good but language/runtime differs | Copy whole source, translate syntax only |
| 4 | **Extract pattern** | Dependency is too heavy but mechanism is valuable | Rebuild smallest proven mechanism |
| 5 | **Build from scratch** | No viable source or pattern exists | Write minimal base, tests first |

Default bias: **use/wrap before porting, and port before inventing**.

### Port tax

Mechanical porting is a preservation technique, not a default maintenance strategy. A port creates local ownership of copied logic, tests, bug fixes, and future drift.

Prefer wrapping when the existing tool can be invoked safely, deterministically, cheaply, and with stable structured output. Choose mechanical port only when at least one is true:

- the source is small, critical, and easier to own locally than depend on externally;
- the dependency/runtime is not acceptable in the target environment;
- wrapping would hide too much state, error behavior, or evidence;
- packaging/distribution requires a native/local module;
- the source behavior must be modified only at adapter boundaries after tests prove preservation.

### Fatal filters

Reject or quarantine a candidate if it has incompatible/unclear license, inaccessible source, unverifiable behavior, unsafe execution, unsupported runtime, huge dependency surface for small behavior, ambiguous interactive interface, raw secret exposure, hidden destructive behavior, or poor fit to the user intent.

Rejected candidates still matter: record why so later agents do not rediscover the same dead end.

---

## 6. Mechanical Porting Rule

Mechanical porting is not creative rewriting. It is used only after the salvage ladder has shown that direct use or wrapping is insufficient.

```text
1. Download/read the original source.
2. Copy the entire relevant file/module into the target workspace.
3. Translate syntax only.
4. Preserve control flow, constants, error paths, edge cases, names, and comments where possible.
5. Replace imports with closest local equivalents.
6. Add wrappers outside the ported module.
7. Run original/adapted tests.
8. Fix translation mistakes, not algorithm design.
9. Delete only whole unused functions after verification.
```

Do not write a cleaner 80-line version of a 200-line source file unless the rewrite gate passes.

### Rewrite gate

Manual coding is allowed only when one of these is true:

- source is unsafe or toxic;
- source does not solve the target need;
- source depends on a runtime model that cannot be mapped cleanly;
- source is overbuilt and a smaller extracted mechanism is safer;
- license or dependency constraints block use/port;
- tests prove the port cannot be made correct without redesign.

A rewrite must preserve discovered edge cases and must include a short rewrite record.

### Post-port placement check

After a mechanical port compiles and tests run, re-check the boundary:

```text
ported invariant behavior -> base
ported CLI/HTTP/MCP/UI parsing -> adapter
ported aliases, thresholds, defaults -> rules/config
ported external calls -> port interface + infrastructure adapter
```

Mechanical porting preserves behavior first. Promotion then restores the base/adapter/rules split without redesigning the algorithm.

---

## 7. Spec-First Build Packet

Before new base logic is written, produce a compact spec. The spec is the implementation target and test oracle.

Minimum spec:

```yaml
spec:
  intent: ""
  risk_class: "read_only | local_mutation | external_mutation | destructive | open_world"
  input_contract: {}
  output_contract: {}
  error_cases: []
  example_traces:
    - input: {}
      output: {}
  invariants: []
  verification:
    smoke: ""
    failure: ""
    property_or_regression: ""
```

Specs should be machine-verifiable where possible: JSON Schema, OpenAPI, Pydantic/Zod/serde schemas, property tests, fixture traces, golden files, or behavior tables.

Do not make spec writing a paperwork sink. For small components, place this in `METADATA.yml`. Use `templates/SPEC_PACKET.md` only when review depth is needed.

---

## 8. Deterministic Navigation and CodeDNA

Agents should navigate by structure before scanning by text.

Preferred order:

1. read `AGENTS.md`;
2. read `METADATA.yml` or component manifest;
3. use LSP/symbol index for definitions and references;
4. use file tree and known directories;
5. use grep/search only when symbol navigation is unavailable or the target is textual/configural.

### LSP adapter contract

A code-navigation adapter should expose:

```text
get_definition(file, line, column)
get_references(file, line, column | symbol)
get_symbols(file)
get_workspace_symbols(query)
```

Return the standard result envelope with file ranges, stable symbol IDs where possible, and evidence spans.

### CodeDNA header

Every promoted source file should have a tiny structured header when the language/ecosystem allows it:

```text
@role: base | adapter | rules | test | generated | vendored
@risk: read_only | local_mutation | external_mutation | destructive | open_world
@contract: input -> output shape or schema name
@adapter_for: component name, if applicable
```

This is a local convention, not an external standard. Keep it short. Do not pollute vendored or mechanically staged files; add headers during promotion.

---

## 9. Result Envelope Standard

Every agent-facing adapter should return structured output first. Human prose is allowed as a `summary` field or display rendering, not as the only machine channel.

```json
{
  "status": "success | partial_success | error | blocked | budget_exceeded",
  "changed": false,
  "summary": "",
  "data": {},
  "evidence": [],
  "warnings": [],
  "errors": [
    {
      "code": "",
      "message": "",
      "recoverable": true,
      "next_action_hint": ""
    }
  ],
  "next_actions": [],
  "trace_id": "",
  "duration_ms": 0,
  "freshness": "",
  "confidence": "",
  "usage": {
    "tokens_used": null,
    "pages_fetched": null,
    "bytes_read": null,
    "cost_usd_estimate": null
  },
  "budget": {
    "max_tokens": null,
    "max_pages": null,
    "max_bytes": null,
    "max_cost_usd": null
  },
  "continuation_token": null
}
```

For mutation, also include:

```json
{
  "affected_items": [],
  "user_visible_effect": "",
  "reversible": true,
  "undo": "",
  "verification": "",
  "idempotency_key": "",
  "approval": {
    "required": false,
    "approval_token": null,
    "staged_changes": []
  }
}
```

The canonical machine-readable schema is `schemas/result-envelope.schema.json`. Agent-facing adapters may add fields, but they must not redefine the meaning of `status`, `changed`, `errors`, `evidence`, `trace_id`, `usage`, `budget`, or mutation metadata.

### Composite step records

If a composite or workflow calls child operations, do not collapse observability. Include step records:

```json
{
  "steps": [
    {
      "name": "",
      "status": "success | partial_success | error | skipped",
      "trace_id": "",
      "duration_ms": 0,
      "evidence": [],
      "errors": []
    }
  ]
}
```

### CLI output rule

For machine mode, stdout must be exactly one JSON envelope or JSONL/NDJSON envelopes. Progress/human text goes to stderr or log artifacts. Exit codes remain stable and documented.

---

## 10. Budget and Continuation Contract

Any operation that can consume unbounded resources must accept a budget:

- LLM inference;
- large file reads;
- recursive search;
- paginated API calls;
- crawling/browsing;
- fan-out over files, repos, tickets, messages, or records.

Rules:

- respect caller budget;
- return `partial_success` with a `continuation_token` when useful work was completed but more remains;
- return `budget_exceeded` when the minimum safe operation exceeds the budget;
- include actual usage in the envelope;
- make continuation tokens opaque, scoped, and expiring.

---

## 11. Composite and Workflow Promotion

Primitives are necessary. Composites are earned.

```text
primitive functions/tools
        -> observe repeated 3-5 step chains
        -> name the user intent
        -> build composite above primitives
        -> return structured evidence and child step records
        -> keep primitive escape hatches
```

### Composite naming technique

Name by user outcome, not backend action:

| Weak primitive chain | Better composite |
|---|---|
| `search_files` + `read_file` + `summarize` | `find_and_outline` |
| `list_tasks` + `filter_due` + `send_update` | `prepare_due_task_update` |
| `read_logs` + `find_errors` + `rank_causes` | `diagnose_recent_failure` |

### Composite vs compiled workflow

| Use composite when | Use compiled workflow when |
|---|---|
| agent should still decide before/after the call | steps are deterministic and repeated |
| flow is short and intent-level | retries, caching, paging, or fan-out dominate |
| caller needs one better tool | system needs reusable executable blueprint |

Compiled workflows must be versioned, inspectable, replayable, budgeted, and policy-checked.

---

## 12. Adapter Contracts

### CLI adapter

Required:

- non-interactive mode;
- `--json` or JSONL/NDJSON machine output;
- stable exit codes;
- `--dry-run` for mutation;
- `--replay <artifact>` where practical;
- task-runner entries: test, lint, format, dry-run, replay, housekeeping.

### Web/API adapter

Required:

- validate request payload before base;
- separate DTOs from internal models;
- return machine-readable errors;
- trace request IDs;
- avoid UI components owning base rules.

### MCP adapter

Required:

- one intent per tool;
- names and descriptions optimized for weaker agents;
- narrow schemas and safe defaults;
- read tools separate from write/destructive tools;
- no generic executor unless classified `open_world`;
- dry-run/approval for mutation;
- structured result envelope;
- progressive discovery for large catalogs;
- tool/resource/prompt boundary respected.

### Worker/automation adapter

Required:

- idempotent jobs;
- retry/backoff policy;
- dead-letter or failure artifact;
- trace/event records;
- replay/simulation mode where possible.

### Documentation/skill adapter

Required:

- short trigger/description;
- runtime-effective steps before deep rationale;
- references/templates separated from base instructions;
- no hidden side effects;
- validation/check command where possible.

### Sandbox adapter

Required for `open_world` and destructive mutation unless an equivalent transaction boundary exists:

- scoped filesystem;
- explicit network allowlist;
- timeout and resource budget;
- no raw secret inheritance;
- staged changes and approval token;
- commit only after explicit approval;
- audit generated code, inputs, outputs, and trace IDs.

---

## 13. Supply Chain and Dependency Provenance

Ready-made-first does not mean dependency-blind.

Before `use` or `wrap`, record:

- source URL and version;
- license;
- package manager and lock strategy;
- source inspectability;
- binary provenance if using a prebuilt executable;
- update policy;
- known high-risk transitive dependencies;
- smoke-test command;
- rollback/removal path.

Prefer dependencies that are source-inspectable, version-pinned, testable in Windows + PowerShell, and usable non-interactively. When provenance is weak, treat the candidate as a pattern source rather than a direct dependency.

For higher conformance levels, add SBOM/provenance checks, dependency scanning, and signed/reproducible build notes where practical.

---

## 14. Implementation Sequence

1. Read `AGENTS.md` and component metadata.
2. Define intent, surface, risk class, and budget shape.
3. Search for ready-made tools and source patterns.
4. Apply fatal filters and choose use/wrap/port/extract/build.
5. Write/update compact spec packet.
6. Define base contract and result envelope.
7. Build or integrate base logic.
8. Add adapter boundary validation.
9. Add dry-run, approval, idempotency, and audit for mutation.
10. Add CLI first when local agent operation matters; add MCP/web/worker after.
11. Add smoke, failure, contract, replay, and housekeeping tests.
12. If the path succeeded and is likely to recur, capture it as a scriptable path recipe.
13. Write/update `METADATA.yml`, `AGENTS.md`, continuation notes, and recipe index.
14. Run conformance checks and cleanup scratch artifacts.

Do not start with the adapter unless the adapter shape is the actual design problem.

---

## 15. Conformance Ladder

| Level | Name | Required proof |
|---|---|---|
| 0 | Experimental | intent, risk, smoke command |
| 1 | Agent-Usable | structured output, non-interactive path, tests |
| 2 | Agent-Operable | evidence, recovery hints, dry-run where needed, metadata |
| 3 | Runtime-Integrated | trace IDs, replay/continuation, budgets, housekeeping |
| 4 | Platform Primitive | versioned schema, deprecation, conformance linter, provenance |

Do not demand Level 4 paperwork for Level 0 spikes. Do not promote a component without the proof its level claims.

### Governance adoption profiles

Use profiles to apply the protocol across Codex, Kimi, Claude, Gemini, and other agents without making every artifact carry the same weight.

| Profile | Minimum level | Applies to | Required proof |
|---|---:|---|---|
| `minimal` | 0 | experiments, short-lived spikes | intent, risk class, smoke or review note |
| `agent_usable` | 1 | reusable scripts, docs, local tools | `AGENTS.md` or equivalent, metadata, structured output |
| `mutation_safe` | 2 | file writes, external API writes, generated code execution | dry-run, idempotency, approval/audit where needed |
| `runtime_integrated` | 3 | scheduled workers, MCP tools, shared services | trace IDs, replay/continuation, event/artifact records |
| `platform_primitive` | 4 | system-wide primitives and cross-agent services | schemas, deprecation policy, owner/review record, conformance check |

System-wide adoption rule: a component may be used below `platform_primitive`, but it may not be advertised as a shared governance primitive until the conformance checker verifies Level 4 or a named escape hatch records the gap.

### Schema authority

The protocol text explains intent. The files under `schemas/` define the machine-readable baseline for automation. If prose and schema conflict, treat it as a protocol defect and open a governance review before changing implementation behavior.

---

## 16. Observability, Replay, and Event Records

Debugging is a design feature.

Every non-trivial component should produce enough evidence for a later agent to answer:

```text
what happened?
what inputs were used?
what changed?
what failed?
what can be retried?
what should not be repeated?
```

Recommended artifacts:

- command ledger;
- JSONL event stream;
- trace IDs correlated across child steps;
- failure artifact with input, config, environment summary, and error;
- continuation packet for interrupted work;
- replay command.

Use OpenTelemetry-compatible concepts where practical: traces for request/workflow paths, logs for events, metrics for counters/latency, and baggage/correlation attributes for cross-cutting context.

---

## 17. Successful Path Capture and Scriptable Edit Recipes

Every successful non-trivial edit path should be treated as a candidate for future automation.

The goal is not to automate everything immediately. The goal is to avoid making future agents rediscover the same route through the codebase. After a successful path, capture the minimum reusable recipe that turns the path from manual investigation into a cheap command, codemod, checklist, or MCP/composite candidate.

### Capture trigger

Create or update a scriptable path recipe when at least one is true:

- the same edit shape is likely to recur;
- the path required tracing through more than two files/modules;
- the agent used LSP/symbol navigation to locate a stable route;
- a small change required expensive codebase reading;
- the edit involved adapter/base boundary placement;
- the fix added a pattern that future tools should follow;
- the work exposed a reliable smoke/replay command.

Do not capture one-off trivia. Capture paths that reduce future discovery cost.

### Recipe levels

| Level | Form | Use when |
|---|---|---|
| 0 | Note | path is useful but not stable enough to script |
| 1 | Command recipe | shell/task-runner commands reproduce navigation, checks, or edits |
| 2 | Patch recipe | scripted file edits, templates, or structured replacement |
| 3 | Codemod/AST recipe | repeated semantic code transformation across files |
| 4 | Composite/workflow | repeated multi-step tool development path becomes a reusable tool/workflow |

### Required recipe fields

A scriptable path recipe must record:

```yaml
recipe:
  name: ""
  intent: ""
  applies_when: []
  starting_points: []
  discovery_path:
    - ""
  edit_steps:
    - ""
  commands:
    dry_run: ""
    apply: ""
    verify: ""
    rollback: ""
  touched_surfaces:
    base: []
    adapters: []
    rules_config: []
    tests: []
  expected_result_envelope: {}
  safety:
    risk_class: ""
    dry_run_required: true
    idempotent: true
  promotion_candidate: "none | command | codemod | composite | workflow | MCP tool"
```

### Scriptability order

Prefer the cheapest reliable representation:

```text
AGENTS.md note / METADATA recipe index
  -> task-runner command
  -> shell/Python script
  -> LSP-assisted symbol recipe
  -> AST/codemod recipe
  -> composite tool or workflow
```

Use text replacement only for narrow, stable patterns. Use LSP or AST/codemod approaches when the change depends on symbols, imports, call sites, parameter order, or syntax structure.

### Safety rule

A recipe that mutates files must support dry-run or diff preview before apply. It must be idempotent where practical and must include a verification command.

### Promotion rule

Promote a recipe when the same successful path repeats:

- 2 times -> keep as indexed recipe;
- 3 times -> add task-runner command or script;
- 5 times -> consider composite tool, MCP tool, codemod, or compiled workflow.

### Housekeeping rule

Path recipes should reduce search pollution, not add to it. Store them under a known location such as `recipes/`, `tools/recipes/`, `.agents/recipes/`, or `docs/recipes/`, and index them from `AGENTS.md` or `METADATA.yml`. Remove obsolete recipe drafts during housekeeping.

---

## 18. Housekeeping Protocol

Housekeeping is part of done.

Remove or quarantine:

- downloaded candidate repos not promoted;
- scratch ports;
- temp wrappers;
- abandoned generated files;
- duplicate specs;
- stale logs that are not tied to a failure artifact;
- old archives beyond retention.

Keep:

- promoted source;
- minimal provenance records;
- tests and fixtures;
- smoke-test logs for current release;
- compact metadata;
- decision notes that prevent repeated failed paths.

Archive policy:

- default: compress or delete non-reference archives after 90 days or after milestone close;
- mark permanent references explicitly;
- keep archive indexes outside ordinary discovery paths when possible;
- housekeeping must check filename-search pollution.

---

## 19. Escape Hatch Doctrine

The protocol is a control system, not a prison.

An escape hatch is valid only when it is:

```text
named       -> what rule is being bypassed
scoped      -> exact files/actions affected
justified   -> why normal path fails
bounded     -> time/usage/size limit
observable  -> log/trace/metadata record
recoverable -> rollback or cleanup path
reviewable  -> future agent can inspect the decision
```

Do not silently bypass the protocol. If urgency requires a shortcut, leave a short `ESCAPE_HATCH_NOTE.md` or metadata entry.

---

## 20. Anti-Patterns

Reject or redesign when you see:

- adapter owns domain rules;
- base knows CLI/MCP/HTTP syntax;
- generic shell/eval executor without sandbox;
- raw backend API mirror exposed to agent;
- unstructured prose-only output;
- hidden destructive side effects;
- no dry-run for mutation;
- no stable IDs/evidence for follow-up;
- huge dependency for tiny behavior;
- ported code rewritten for taste;
- scratch files left in discovery paths;
- conformance level claimed without proof;
- budgetless recursive search/fan-out;
- tool names that expose topology instead of intent.

---

## 21. Done Definition

A component is done when:

- intent, risk, and surface are declared;
- ready-made search or salvage decision is recorded;
- base/adapter/rules boundary is clear;
- spec or metadata is current;
- result envelope is structured;
- tests cover smoke, failure, output contract, and mutation behavior if applicable;
- CLI/web/MCP/worker adapter is thin and validated;
- budgets, continuation, and replay exist where resource use or failure recovery matters;
- successful recurring paths are captured as scriptable recipes or explicitly marked one-off;
- provenance and dependency ownership are recorded;
- housekeeping has removed/quarantined leftovers;
- `AGENTS.md`, recipe index, and task-runner commands remain accurate.
