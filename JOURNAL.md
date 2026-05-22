# JOURNAL.md — Design History for Universal Base/Adapter Protocol v1.5

**Protocol:** Universal Base/Adapter Design and Coding Protocol  
**Baseline:** v1.5  
**Purpose:** Help reviewers reason through the choices, exclusions, tradeoffs, and evolution that shaped the v1.5 baseline from the initial tool-salvaging draft.

---

## 0. How to read this journal

This journal is not the runtime protocol. The runtime protocol tells an agent what to do. This journal explains why the protocol became that shape.

Use this document when:

- reviewing whether v1.5 is coherent;
- onboarding a builder or agent to the design philosophy;
- auditing whether a rule is justified or merely preference;
- deciding whether a future revision should change the base doctrine or only an adapter;
- deciding when an escape hatch is legitimate.

The central claim of v1.5 is:

```text
Stable behavior belongs in the base.
Runtime delivery belongs in adapters.
Tunable policy belongs in rules/config.
Evidence, metadata, and housekeeping are part of done.
Ready-made, battle-tested work should be inspected before coding begins.
```

---

## 1. Source basis and provenance note

The v1.5 baseline was formed from several streams:

1. initial tool-salvaging skill variants;
2. MCP architecture and efficient-agent-system pattern material;
3. base/adapter and agent-operable tool design material;
4. research-to-build and pattern-adoption protocols;
5. two external review passes that tested operational gaps;
6. emerging AI-era coding-practice material;
7. external standards and references used to vet whether new patterns were real, emerging, or merely local preference.

Some earlier uploaded source files expired during the working session. This journal therefore relies on the preserved generated protocol versions in the workspace, the current v1.5 pack, the available review notes, and the current additional design material. Where a decision depends on an external standard or ecosystem signal, the reference is listed in section 13.

---

## 2. Original problem: agents were redesigning solved work

The first trigger was a concrete failure mode: an agent reads an existing implementation, understands the idea, then writes a new smaller version from scratch. This is seductive but wasteful.

The initial doctrine was:

```text
Do not spend reasoning tokens recreating design decisions that another author already solved.
Copy the source.
Translate syntax.
Preserve behavior.
Fix only integration breaks.
```

This became the first core rule: **salvage before inventing**.

### Why this mattered

Agents are good at producing plausible implementations. They are weaker at preserving hidden edge cases from code they only skimmed. A “cleaner” rewrite often removes bug fixes, ordering decisions, naming conventions, and defensive branches that were paid for by real-world use.

### Early correction

The first version was too absolute. “Never rewrite” is as dangerous as “always rewrite.” A bad dependency, unsafe code path, incompatible license, or mismatched runtime can make mechanical porting the wrong choice.

That produced the first important refinement:

```text
Default to mechanical porting.
Allow constrained rewrite only after a decision gate.
```

---

## 3. From mechanical porting to the salvage ladder

The protocol evolved from a binary choice — port or rewrite — into a five-step adoption ladder:

```text
use -> wrap -> mechanical port -> extract pattern -> build from scratch
```

### Why the ladder exists

Mechanical porting preserves behavior, but it also creates local maintenance ownership. If an upstream tool can be used directly, that is cheaper. If the tool’s behavior is right but the interface is wrong, wrapping is cheaper than porting. If the dependency is too heavy but the mechanism is valuable, pattern extraction is safer than copying a whole stack.

### Decision retained in v1.5

The final baseline uses this order:

| Step | Why it is preferred |
|---|---|
| Use | Lowest ownership burden; upstream remains responsible. |
| Wrap | Keeps battle-tested behavior while adapting interface. |
| Mechanical port | Preserves behavior when runtime or language fit is wrong. |
| Extract pattern | Salvages architecture when implementation is too heavy or unsafe. |
| Build from scratch | Last resort when no candidate passes fit, safety, and ownership checks. |

### Rejected simplification

The protocol does not say “always port.” It says “inspect ready-made work first, then choose the cheapest safe adoption mode.”

---

## 4. Why base/adapters became the root architecture

The next shift was realizing that tool salvaging alone was too narrow. The same failure repeated across CLI tools, web apps, MCP servers, automation scripts, documentation packs, and agent skills: the delivery surface became the architecture.

Examples:

```text
CLI argument parsing starts owning business rules.
MCP tool schema becomes the domain model.
React component state becomes workflow state.
Cron scripts become hidden orchestration engines.
Prompt files become uncontrolled runtime policy.
```

The base/adapter split became the universal correction.

### Final rule

```text
Base = invariant behavior.
Adapter = runtime/channel/framework translation.
Rules/config = tunable policy.
Metadata = provenance and proof.
Housekeeping = part of done.
```

### Why this is universal

The runtime changes faster than the mechanism. CLI flags, HTTP payloads, MCP schemas, UI forms, and agent skill metadata are volatile. State transitions, safety rules, error taxonomy, idempotency, and core algorithms should be stable.

The protocol therefore treats CLI, webapp, MCP, worker, sandbox, documentation, and skill surfaces as adapters around the same base doctrine.

---

## 5. Why rules/config were separated from base

During the generalization phase, it became clear that some behavior is neither core logic nor adapter glue. Examples include aliases, limits, routing defaults, retention days, approval thresholds, ranking weights, and feature flags.

These are operator-tunable. Hardcoding them into the base makes the base unstable; hiding them in adapters causes inconsistent behavior across surfaces.

### Decision

Rules/config became a first-class layer.

```text
Base asks: what must always be true?
Adapter asks: how does this runtime receive and return data?
Rules ask: what policy should apply in this environment today?
```

### Escape hatch

If a rule becomes semantically required for correctness, promote it into the base contract. If a base constant becomes environment-specific, demote it into rules/config.

---

## 6. Why composite intent tools were adopted

The MCP and tool-design material repeatedly showed that exposing many primitive tools creates selection burden for agents. However, hiding all primitives behind one god-tool destroys debuggability.

The chosen middle path is:

```text
Keep primitives for escape hatches.
Promote repeated primitive chains into named composites.
Promote deterministic repeated workflows into compiled workflow artifacts.
```

### Why this matters

Agents burn context and make mistakes when the same three to five steps must be rediscovered every run. A composite tool turns repeated choreography into an intent-shaped call.

### Final distinction

| Form | Meaning | Use when |
|---|---|---|
| Primitive | One exact operation | Debugging, advanced use, escape hatch. |
| Composite | Repeated primitive chain exposed as one intent | Common agent/user goals. |
| Compiled workflow | Versioned deterministic plan | Repeated runs, fan-out, retries, paging, orchestration. |

### Guardrail

A composite result must expose step-level evidence and errors. Otherwise the composite hides primitive failure and becomes opaque.

---

## 7. Why result envelopes became mandatory

Early drafts focused on building and salvaging. Reviews showed that agent-operated systems fail later if outputs are not machine-readable.

A human can infer from prose. The next agent needs state.

### Final rule

Agent-facing surfaces return a structured result envelope with:

- status;
- summary;
- data;
- evidence;
- warnings;
- errors;
- recovery hints;
- trace ID;
- duration;
- usage/budget information;
- continuation token or artifact references when needed.

### Why this belongs in the base protocol

This is not an MCP-only rule. CLI, web, worker, automation, and documentation pipelines all benefit from output that can be parsed, replayed, summarized, and continued.

### Escape hatch

Human-readable output is allowed, but it should be secondary. For CLI adapters, machine-readable stdout is preferred; progress and human commentary should go to stderr or artifacts.

---

## 8. Why risk moved before contract design

The v1.3 review identified a serious ordering issue: if risk is classified after tool design, safety is bolted on too late.

A read-only tool, a local mutation tool, an external API mutation, and a destructive command require different contracts.

### Final rule

Classify risk before finalizing the base contract.

| Risk class | Contract impact |
|---|---|
| Read-only | Evidence, pagination, freshness, budget. |
| Local mutation | Dry-run, diff, idempotency, rollback note. |
| External mutation | Approval, audit, idempotency key, replay record. |
| Destructive | Explicit approval, staged change, recovery path. |
| Open-world execution | Sandbox, allowlist, timeout, no raw secrets. |

### Why this matters

A tool that sends email, edits files, calls an API, or runs code is not merely a different adapter. It changes proof obligations.

---

## 9. Why debugging, replay, and continuation were added

Review feedback showed that “it passed once” is not enough for an agent-operated environment. The next agent must be able to inspect what happened and continue safely.

This led to:

- command ledgers;
- event records;
- trace IDs;
- replay commands;
- continuation packets;
- artifact indexes;
- step-level records for composites and workflows.

### Why this is important in ARH-style environments

The environment relies on repeated agent runs, local automation, file discovery, CLI execution, and multi-step workflows. Without replay and continuation records, every interruption becomes a new investigation.

### Escape hatch

Tiny Level 0 experiments do not need full event sourcing. But any promoted component should have at least a smoke command, result artifact, and metadata record.

---

## 10. Why housekeeping became part of done

Housekeeping began as an operational annoyance: leftover scratch files pollute filename discovery. It became a core principle because search pollution directly weakens future agents.

### Final rule

A component is not done until scratch ports, rejected candidates, temp wrappers, duplicate specs, stale logs, and abandoned generated files are either removed, archived, or indexed.

### Keep vs remove

| Keep | Remove or archive |
|---|---|
| promoted source | rejected candidate repos |
| tests and fixtures | scratch ports |
| minimal provenance record | temp wrappers |
| current smoke logs | stale logs without value |
| decision notes preventing repeated dead ends | duplicate generated files |

### Why this belongs in the protocol

In human-only projects, mess is inconvenient. In agent-operated projects, mess becomes bad input data.

---

## 11. Why AGENTS.md entered v1.5

The emerging-pattern review added `AGENTS.md` as a repo-level instruction layer. This was accepted because it directly supports the dual-consumer model: humans read README; agents need deterministic setup, style, test, and protocol instructions.

### Decision

Every serious project should include an `AGENTS.md` or equivalent instruction file containing:

- install commands;
- test commands;
- lint/type-check commands;
- code style;
- protocol location;
- adapter expectations;
- forbidden operations;
- housekeeping commands.

### Why not put everything in README?

README is human-facing and often narrative. Agents need concise operational rules and commands. Separating the surfaces reduces ambiguity.

---

## 12. Why LSP-first navigation entered v1.5

Grep and filename search are useful but brittle for code understanding. The emerging material pushed deterministic symbol navigation through LSP.

### Decision

Prefer LSP-style navigation for code symbols when available:

- go to definition;
- find references;
- symbol search;
- diagnostics;
- rename analysis.

### Constraint

This is not mandatory for every repository. Config files, docs, generated files, and unsupported languages may still require text search. The protocol says LSP-first, not LSP-only.

---

## 13. Why supply-chain provenance entered v1.5

The protocol says “ready-made first.” That creates a new risk: if agents pull in third-party code, they must know what they adopted.

### Decision

Every use/wrap/port/extract decision should record:

- source URL or local source path;
- version/commit/tag;
- license;
- adoption mode;
- files copied or wrapped;
- tests inspected or ported;
- known risks;
- update policy.

### Why this matters

Reuse without provenance becomes dependency chaos. Provenance is the cost of salvage discipline.

---

## 14. Why external standards were accepted only proportionally

v1.5 references broader standards but does not require full compliance for every small component.

Accepted as proportional guidance:

- OpenTelemetry-shaped traces/logs/metrics;
- NIST SSDF secure development practices;
- SLSA supply-chain integrity levels;
- OWASP SCVS component verification levels;
- MCP security and least-privilege principles;
- AGENTS.md and SKILL.md packaging conventions;
- LSP as a deterministic code navigation protocol.

### Why proportional adoption

A small one-off script should not carry platform-grade compliance overhead. A promoted MCP server or external mutation tool should.

The conformance ladder decides how much proof is needed.

---

## 15. Decisions that were rejected or constrained

| Proposal | Final decision | Reason |
|---|---|---|
| Always mechanically port | Rejected | Unsafe or mismatched sources need constrained rewrite or pattern extraction. |
| Build from scratch after reading source | Rejected | Loses edge cases and repeats solved work. |
| Full documentation packet for every component | Rejected | Too heavy; use compact metadata for small work. |
| Hard 300-line file limit | Constrained | Useful review trigger; not universal law. |
| LSP mandatory everywhere | Constrained | Prefer where supported; fallback allowed. |
| CodeDNA as public standard | Reclassified | Useful local convention, not external standard. |
| Full SLSA/SSDF/SCVS for every script | Constrained | Apply by risk and conformance level. |
| Generic MCP shell executor | Rejected by default | Too broad; use sandbox adapter with scoped clients and approval. |
| Composite god-tool | Rejected | Composites need sharp intent and step-level evidence. |
| Agent Client Protocol (ACP) adapter in v1.5 | Deferred to v1.6 candidate | ACP standardizes editor↔agent (JSON-RPC) the way LSP standardizes editor↔language-server; v1.5 covers agent↔tool (MCP) but not editor↔agent. Add when first ARH component exposes an agent to an editor. |
| Agent-to-Agent (A2A / UAP) adapter in v1.5 | Deferred to v1.6 candidate | Multi-agent handoff (Sentinel ↔ Codex ↔ Kimi ↔ Gemini) is currently encoded as continuation packets only. A dedicated A2A adapter is warranted once a second cross-agent interaction beyond continuation appears. |

---

## 16. Version evolution summary

| Version | Main movement | Why it happened |
|---|---|---|
| Initial skill | Mechanical porting doctrine | Stop agents from rewriting solved code. |
| Generic skill | Discovery/evaluation/salvage/integration/logging | Make salvage reusable beyond one project. |
| Universal protocol v1.0 | Base/adapter generalization | Apply the same discipline to CLI, web, MCP, workers, docs. |
| v1.1 | Governance, conformance, prompt/resource/tool boundary | Prevent protocol drift and surface confusion. |
| v1.2 | Rationale and escape-hatch guide | Help reviewers and agents understand why, not just what. |
| v1.3 | Operational hardening | Add replay, budgets, idempotency, conformance checks, retention. |
| v1.4 | Lightweight paperwork and CLI machine-output rules | Prevent protocol overload; improve ARH/pwsh ergonomics. |
| v1.5 | Agent-era hardening | Add AGENTS.md, LSP, spec packets, sandbox, provenance, security/observability posture. |

---

## 17. Final baseline thesis

v1.5 should be treated as stable because it is no longer just a set of preferences. It is a coherent operating model:

```text
Agents start from explicit project instructions.
They inspect before coding.
They adopt proven tools before inventing.
They keep stable behavior away from volatile adapters.
They classify risk before contract design.
They return structured evidence.
They make work replayable.
They clean up the workspace.
They promote components only when proof matches risk.
```

The baseline should now change slowly. Future revisions should usually be adapter-specific unless a new pattern affects every build surface.

---

## 18. Reviewer questions

A reviewer should judge future revisions with these questions:

1. Does this change apply across multiple surfaces, or only one adapter?
2. Does it reduce future agent reasoning, or add ritual?
3. Does it make behavior more observable, replayable, or safer?
4. Does it preserve the salvage ladder?
5. Does it keep the base/adapters/rules boundary clean?
6. Does it improve machine readability without harming human clarity?
7. Does it include housekeeping and provenance obligations?
8. Is the requirement proportional to conformance level and risk?
9. Does it provide an escape hatch with proof, or a silent loophole?
10. Would a weaker agent follow it correctly under task pressure?

---

## 19. Reference anchors used during v1.5 vetting

These references were used as external anchors for the v1.5 hardening pass. They informed the direction but were adopted proportionally rather than copied wholesale.

| Area | Anchor | Why it mattered |
|---|---|---|
| Agent repo instructions | AGENTS.md | Supports deterministic project instructions for coding agents. |
| OpenAI skill packaging | OpenAI Codex Skills | Confirms skill-as-directory-with-SKILL.md pattern. |
| Agent instruction layering | OpenAI Codex AGENTS.md guide | Supports repo-level agent instruction layering. |
| Code navigation | Language Server Protocol | Supports deterministic definition/reference/symbol navigation. |
| MCP security | MCP security best practices | Supports least privilege, scoped permissions, and approval for risky operations. |
| Observability | OpenTelemetry | Supports traces, metrics, logs, correlation, and vendor-neutral telemetry concepts. |
| Secure development | NIST SSDF | Supports secure-by-design development practices and artifact evidence. |
| Supply-chain integrity | SLSA | Supports provenance and artifact integrity thinking. |
| Component verification | OWASP SCVS | Supports proportional verification levels for third-party components. |

---

## 20. What should not be forgotten

The protocol began with a practical frustration: agents were wasting time rewriting solved tools.

Everything added later — base/adapters, result envelopes, conformance, AGENTS.md, LSP, sandboxing, provenance, observability, housekeeping — exists to preserve the same underlying goal:

```text
Stop paying repeated reasoning cost for decisions that can be encoded once.
```

That is the heart of v1.5.
