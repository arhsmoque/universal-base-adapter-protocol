# Rationale and Escape Hatch Guide

**Protocol:** Universal Base/Adapter Design and Coding Protocol v1.5  
**Purpose:** Explain the reasoning behind the protocol so external reviewers can audit it and agents can apply it wisely when the normal path does not fit.

---

## 0. Why this document exists

A protocol that only says what to do is easy for agents to imitate mechanically but hard for them to apply under pressure. The missing layer is judgment: why the rule exists, what failure it prevents, and when violating the rule is safer than obeying it blindly.

This guide is the conceptual backing for the protocol. The base protocol is the runtime document. This rationale is the reviewer and training document.

Use it when:

- reviewing whether the protocol is coherent;
- onboarding an implementation agent;
- deciding whether a workaround is legitimate;
- writing an exception record;
- resolving conflict between adapter constraints and base doctrine;
- promoting an experimental design to a stable reusable component.

The goal is not rigid compliance. The goal is reliable design behavior: agents should reuse proven work, separate stable logic from volatile interfaces, return observable results, and know when to stop, wrap, quarantine, or escalate.

## 0.1 Why v1.3 tightened operational contracts

The v1.3 review found that the protocol philosophy was sound but several runtime contracts needed sharper wording: replay/debug, budgets, idempotency, conformance checking, retention limits, and the boundary after mechanical porting. These additions are not new doctrine. They are enforcement aids for the same doctrine: reduce agent guesswork, make side effects observable, and keep the workspace reusable.

---

## 1. The deeper thesis

Most design failure in agent-operated systems is not caused by lack of capability. It is caused by misplaced capability.

Common failures:

- business logic hidden inside CLI parsing;
- user-interface details leaking into storage APIs;
- tool surfaces mirroring backend internals;
- agents rewriting battle-tested code because they understand the pattern but not the edge cases;
- repeated multi-step workflows left as primitive calls;
- results returned as raw blobs, forcing the next agent to infer state;
- temporary build artifacts left in active paths, polluting future discovery.

The protocol exists to make the architecture carry more of the burden so the agent spends less reasoning on repeated, already-solved decisions.

The desired shape is:

```text
intent enters through an adapter
stable behavior lives in the base
volatile behavior lives in rules/config
execution returns evidence and state
housekeeping preserves only durable knowledge
```

This is why the protocol combines base/adapters, salvage-first implementation, composite promotion, structured results, governance, and housekeeping. They are not separate preferences; they reinforce each other.

---

## 2. Why base / adapter / rules is the root pattern

### Decision

Separate systems into:

```text
base engine  = stable mechanics and invariants
adapter      = runtime/channel/framework translation
rules/config = operator-tunable policy
```

### Why

A build target changes faster at the edge than at the core. CLI flags, HTTP payloads, MCP schemas, frontend forms, WhatsApp command syntax, queue message shapes, and provider-specific skill metadata all change often. State transitions, validation invariants, domain rules, idempotency, and result contracts should change slowly.

When these concerns are mixed, every small UX or adapter edit forces the next agent to reread the full engine and risks regression. Splitting the boundary reduces future context cost and makes behavior easier to test.

### Failure prevented

- A command alias change accidentally changes persistence behavior.
- A web form field leaks into internal storage forever.
- MCP tool schema decisions dictate the core library shape.
- A future channel cannot reuse the same capability because WhatsApp/CLI/HTTP assumptions are embedded in the base.

### Reviewer test

A good split exists when:

- the base can be tested without adapter-shaped payloads;
- a new adapter can reuse the base without copying logic;
- command vocabulary or aliases can change in rules/config or adapter tests only;
- future agents can understand behavior by reading the small rules file plus the adapter, not the whole engine.

### Valid escape hatch

Start adapter-first only when the adapter is itself the unknown being researched. For example, a short spike to learn a provider SDK or browser event model is valid. But once the adapter behavior is understood, extract the base before promotion.

---

## 3. Why surface classification comes before coding

### Decision

Classify the thing before implementing it: base library, CLI, web adapter, API adapter, MCP tool/resource/prompt, worker, skill, document, or rules file.

### Why

Many systems become over-tooled because every capability is exposed as an action. But not every capability is an action. Some are reusable instructions, some are read-only context, some are background jobs, some are UI interactions, and some are core library functions.

Surface classification prevents turning documentation into hidden execution, resources into mutation channels, prompts into tools, and tools into generic backend mirrors.

### Failure prevented

- A read-only context source accidentally mutates state.
- A prompt becomes a hidden workflow with side effects.
- A tool returns a documentation blob instead of a structured result.
- A UI component becomes the source of business truth.

### Valid escape hatch

A temporary all-in-one script is acceptable for exploration if it is marked as a spike, isolated from active source paths, and not promoted until classified and split.

---

## 4. Why ready-made-first beats greenfield invention

### Decision

Before writing custom logic, search for existing battle-tested tools, source modules, libraries, and patterns. Use the salvage ladder:

```text
use -> wrap -> mechanical port -> extract pattern -> build from scratch
```

### Why

Existing implementations often contain invisible value: edge cases, failure handling, naming conventions, performance constraints, compatibility patches, and tests. Agents are prone to reading a source, grasping the broad idea, and then writing a smaller “clean” version that loses this embedded knowledge.

The ladder prevents novelty from outranking usefulness. It also gives each candidate a role: direct reference, integration component, source implementation, pattern source, negative reference, or gap signal.

### Failure prevented

- Rebuilding a weak version of an existing robust tool.
- Importing a heavy dependency when only a small pattern was needed.
- Repeating dead-end research because rejected candidates were not logged.
- Treating popularity as proof of fit.

### Valid escape hatch

Build from scratch when no source fits, when licensing blocks reuse, when the dependency is larger than the mechanism, or when the source is unsafe. The exception must preserve any discovered edge cases and record why use/wrap/port/extract was rejected.

---

## 5. Why mechanical porting is stricter than normal refactoring

### Decision

When porting a good implementation, copy the relevant source first and translate syntax only. Preserve control flow, constants, names, comments, error paths, and edge cases where possible. Put integration wrappers outside the ported module.

### Why

Mechanical porting exists to stop the agent from discarding solved design decisions. A “cleaner” rewrite may pass the obvious happy path while losing mature behavior. The original author may have already fixed bugs that are not visible from the main algorithm.

This is especially important when the source has tests, long-tail parsing behavior, compatibility logic, or non-obvious ordering.

### Failure prevented

- The agent rewrites a 200-line implementation into 80 lines and silently drops edge cases.
- Integration requirements mutate the salvaged algorithm.
- Debugging becomes impossible because the port is no longer traceable to the source.

### Valid escape hatch

Constrained rewrite is allowed when the source is toxic, mismatched, untranslatable, unsafe, or blocked by license/runtime constraints. The rewrite must carry forward the tests, edge cases, constants, and external behavior that made the source valuable.

---

## 6. Why composites are earned, not invented upfront

### Decision

Build primitives first, then promote repeated 3-5 step chains into purpose-named composites. Preserve primitive escape hatches.

### Why

Primitive tools are necessary for precision, debugging, and unusual cases. But agents waste turns when they repeatedly perform the same choreography: find, read, compare, infer, then act. A composite should collapse a real repeated workflow, not bundle features because they seem related.

The design target is not “fewer tools.” The target is fewer decisions exposed to the model while retaining enough escape hatches for surgical work.

### Failure prevented

- Tool catalogs become huge collections of near-synonyms.
- Agents repeatedly select low-level primitives and burn tokens on known choreography.
- Composites become vague god tools that accept broad instructions and hide too much.
- Next-action suggestions become noisy boilerplate.

### Valid escape hatch

Keep a workflow primitive when the sequence is still unstable, rare, or judgment-heavy. Promote only after repeated evidence shows the chain is common and predictable.

---

## 7. Why result envelopes matter

### Decision

Return structured results with status, summary, data, evidence, warnings, errors, recovery hints, trace ID, freshness/confidence where relevant, and mutation metadata for side-effecting operations.

### Why

Agents cannot reliably continue from raw backend output. A result envelope turns execution into observable state. It tells the next agent what happened, what changed, what evidence supports it, what failed, and what can be retried.

The result envelope is also a boundary between base and adapters. Each adapter may render differently, but the underlying result semantics remain stable.

### Failure prevented

- Success is inferred from text rather than machine-readable status.
- Partial failure is mistaken for complete success.
- Large raw blobs hide the actual decision signal.
- Recovery requires another reasoning loop because errors lack next-action hints.
- Follow-up calls fail because stable IDs were not returned.

### Valid escape hatch

A tiny internal helper can return a simple native value if it is not agent-facing and is wrapped before exposure. Once exposed through CLI/MCP/API/worker/documented automation, it needs a structured result contract.

---

## 8. Why risk classification is early, not late

### Decision

Declare risk before implementation: read-only, local mutation, external mutation, destructive, open-world, and any applicable risk modifiers such as `secret_bearing`, `regulated_data`, `filesystem_broad_scope`, `network_access`, `privileged_auth`, `generated_code_execution`, or `payment_or_cost_impact`.

### Why

Safety controls must shape architecture. If risk is discovered only after coding, dangerous behavior is already embedded in the wrong layer. Risk class determines whether dry-run, approval, redaction, idempotency, audit, allowlists, rollback notes, or policy gates are required.

### Failure prevented

- A write tool is exposed as if it were read-only.
- Secret-bearing logs leak into artifacts.
- Destructive operations lack confirmation or rollback notes.
- External network calls run without source disclosure, timeout, or allowlist.

### Valid escape hatch

For a short local experiment, risk controls may be lighter if the experiment is isolated, non-promoted, and does not touch real user data or external systems. Promotion requires full risk controls.

---

## 9. Why workflow execution is separated from agent reasoning

### Decision

When the same multi-step process recurs, compile it into a versioned recipe, workflow, or blueprint that an engine can execute deterministically.

### Why

Agents are good at exploration and judgment. They are inefficient at repeating stable, multi-step procedures exactly. Once a path is known, the runtime should own routing, retries, paging, caching, idempotency, logging, and policy gates.

This converts repeated reasoning into reusable execution architecture.

### Failure prevented

- The same agent loop is re-designed every run.
- Retry/paging/fan-out logic is handled inconsistently.
- Long workflows cannot be audited or resumed.
- Dangerous writes hide behind generic “do everything” calls.

### Valid escape hatch

Keep ambiguous or judgment-heavy flows as agent-led tasks. Use code mode or a new workflow version only after sandboxing, audit, and policy boundaries exist.

---

## 10. Why observability and continuation are design features

### Decision

Tools and adapters should capture trace IDs, task/session identity, command/event records, artifact references, verification state, policy blocks, and continuation packets when work is incomplete.

### Why

Agent work is often interrupted, handed off, or resumed after context loss. If the system does not capture state, the next agent must reconstruct it from chat transcripts or shell history. That is slow, error-prone, and dangerous.

Observability also makes external review possible: a reviewer can see what changed, why, how it was verified, and what remains uncertain.

### Failure prevented

- A shell command exits and is falsely treated as task completion.
- Generated artifacts cannot be found later.
- A resumed agent repeats old search paths or overwrites work.
- Policy blocks are invisible.

### Valid escape hatch

For trivial one-shot work, full session machinery may be unnecessary. The minimum remains: final artifact location, what changed, and whether it was verified.

---

## 11. Why governance prevents protocol drift

### Decision

Use decision records, versioning, deprecation notes, scoped exceptions, and promotion gates for material changes.

### Why

A protocol becomes unreliable when every agent silently edits doctrine to fit the current task. Governance is not bureaucracy for its own sake; it keeps the protocol stable enough that agents, reviewers, and tools can depend on it.

The protocol must evolve, but changes should be visible, scoped, and reversible.

### Failure prevented

- Breaking changes appear as “minor wording.”
- Exceptions become permanent undocumented forks.
- Deprecated patterns remain in active use without migration.
- Reviewers cannot tell which document has authority.

### Valid escape hatch

A local exception can override the protocol for a specific scope and timeframe. It must name the reason, owner, risk, expiry/review date, and replacement path.

---

## 12. Why conformance levels are better than one giant standard

### Decision

Use levels: Experimental, Agent-Usable, Agent-Operable, Runtime-Integrated, Platform Primitive.

### Why

Not every idea deserves platform-grade ceremony on day one. But without promotion levels, experiments leak into production without the contracts needed for safe reuse.

The ladder allows cheap exploration while making it clear what proof is required before a tool becomes dependable infrastructure.

### Failure prevented

- A prototype is treated as stable because it worked once.
- A small experiment is overburdened with platform requirements too early.
- Promotion happens by enthusiasm rather than evidence.

### Valid escape hatch

Keep a component at a lower conformance level if its scope is narrow and risks are declared. Do not market it as a platform primitive until it satisfies the higher gates.

---

## 13. Why housekeeping is part of done

### Decision

Archive useful provenance, delete scratch leftovers, quarantine rejected candidates, and ensure active source paths contain only canonical files.

### Why

Agent environments rely heavily on filename discovery, semantic search, and artifact recall. Temporary files, duplicate modules, stale wrappers, failed ports, downloaded sources, and candidate notes pollute future search results. The cost appears later when agents inspect the wrong file or resurrect an abandoned approach.

Housekeeping preserves learning without leaving debris in the active workspace.

### Failure prevented

- Future agents discover `candidate_final_v3_old.py` instead of the promoted module.
- Rejected dependencies are reconsidered repeatedly.
- Source snapshots are mistaken for active code.
- Temporary artifacts inflate context and confuse search tools.

### Valid escape hatch

Do not delete provenance required for licensing, audit, or future review. Move it into `.salvage/archive/`, `docs/decisions/`, or a pattern registry. The active source tree should stay clean.

---

## 14. Why validation is separate from implementation

### Decision

Every component needs proof: smoke, constraint, failure, dry-run, idempotency, output contract, adapter, and platform tests as applicable.

### Why

A design can look correct while failing under adapter translation, side effects, partial failure, platform quirks, or repeated runs. Validation makes the contract observable.

Testing both base and adapter prevents the common mistake where core logic works but the exposed surface fails.

### Failure prevented

- The base works but CLI flags map incorrectly.
- The MCP schema is valid but returns unparseable output.
- A write operation succeeds once but duplicates on retry.
- Windows/PowerShell behavior breaks an otherwise portable script.

### Valid escape hatch

For research-only artifacts, validation may be a design check instead of executable tests. The artifact still needs an explicit “how this would be validated before build” section.

---

## 15. Escape hatch doctrine

Escape hatches are not loopholes. They are controlled deviations that keep the system practical without losing trust.

A valid escape hatch must satisfy all six conditions:

```text
1. Named: what rule is being bypassed?
2. Scoped: where does the bypass apply?
3. Justified: why is the normal path worse here?
4. Bounded: when does the bypass expire or get reviewed?
5. Observable: what evidence proves the bypass worked or failed?
6. Recoverable: how do we return to the normal protocol later?
```

### Common escape hatches

| Situation | Allowed workaround | Required record |
|---|---|---|
| Need to learn an unknown adapter quickly | Build a throwaway adapter spike | Spike note + cleanup |
| Battle-tested source is too large | Extract smallest proven mechanism | Pattern extraction record |
| Mechanical port becomes unreadable | Constrained rewrite preserving tests | Rewrite record |
| Full result envelope is too heavy internally | Native return inside base only | Wrapper must envelope before exposure |
| Workflow needs complex branching | Keep as agent-led or sandboxed code mode | Risk + sandbox note |
| Urgent production fix | Patch narrowly | Follow-up decision record + test |
| Candidate seems promising but unsafe | Quarantine, do not import | Rejection/quarantine note |
| Adapter violates base contract | Add adapter shim | Contract mismatch note |

### Invalid escape hatches

- “I rewrote it because it looked cleaner.”
- “I skipped tests because it probably works.”
- “I put rules in the base because it was faster.”
- “I exposed raw backend output because the agent can parse it.”
- “I left candidate files because they might be useful.”
- “I made a generic run command because specific tools take longer.”

### Minimal exception note

```markdown
# Exception / Escape Hatch Note

- Rule bypassed:
- Scope:
- Reason normal path is unsuitable:
- Risk introduced:
- Mitigation:
- Expiry or review trigger:
- Evidence / verification:
- Cleanup or migration path:
- Owner:
```

---

## 16. Reviewer checklist

Use this checklist to review a design without rereading the whole protocol.

```text
1. Does the design separate base, adapter, and rules?
2. Did it search for ready-made tools/patterns before custom coding?
3. Are candidate decisions recorded: use/wrap/port/extract/reject/build?
4. If code was ported, was it mechanical rather than creative?
5. If code was rewritten, is the rewrite gate documented?
6. Is the surface correctly classified: tool/resource/prompt/CLI/web/API/worker/doc?
7. Is the name intent-shaped and inferable?
8. Are primitives preserved under composites?
9. Does the result envelope expose status, evidence, warnings, errors, recovery hints, and traceability?
10. Are risk class and side effects declared?
11. Are dry-run, approval, redaction, and idempotency present where required?
12. Can the base be tested without adapter-shaped payloads?
13. Can the adapter be tested without real destructive side effects?
14. Are observability and continuation records sufficient for handoff?
15. Are governance, versioning, and exception records present for material changes?
16. Is housekeeping complete: active paths clean, provenance archived, rejected candidates logged?
17. Can a weaker agent understand what to do next without reading raw transcripts?
```

---

## 17. Agent runtime mental model

When under task pressure, follow this compressed reasoning loop:

```text
Intent -> classify surface -> search existing -> decide use/wrap/port/extract/build
       -> split base/adapter/rules -> declare risk -> define result envelope
       -> implement smallest verified unit -> add adapter -> test -> clean up
       -> record rationale / exception if anything deviated
```

Default instincts:

- Prefer proven behavior over elegant new design.
- Prefer one stable base with many thin adapters over duplicated logic.
- Prefer structured evidence over persuasive prose.
- Prefer deterministic execution over repeated reasoning.
- Prefer archived provenance over active clutter.
- Prefer scoped exceptions over silent drift.

The protocol is not trying to make every project look the same. It is trying to make every project safe to understand, adapt, resume, and promote.


---

## v1.5 Rationale Addendum: Agent-Era Hardening

The protocol now treats repository instructions, navigation, sandboxing, and provenance as first-class because modern agents fail less from lack of code-writing ability than from hidden context, ambiguous entry points, unsafe execution surfaces, and unverifiable dependencies.

- `AGENTS.md` reduces repeated discovery and gives every agent the same starting map.
- LSP-first navigation lets agents ask the codebase about symbols instead of guessing with regex.
- Spec-first packets turn implementation into verification against a contract, not vibes.
- Sandbox adapters keep open-world actions reversible and auditable.
- Supply-chain/provenance records prevent the ready-made-first ladder from importing opaque risk.
- OpenTelemetry-shaped traces/events/logs make failures understandable across adapters and workflows.

Escape hatches remain allowed, but only if named, scoped, observable, and recoverable.
