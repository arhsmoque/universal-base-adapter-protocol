# JOURNAL.md — Design History for Universal Base/Adapter Protocol

**Protocol:** Universal Base/Adapter Protocol  
**Current baseline:** v1.6 (see entry dated 2026-05-23)
**Purpose:** Help reviewers reason through the choices, exclusions, tradeoffs, and evolution that shaped each baseline. Append only — never edit historical entries.

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
7. successful-path/codemod automation practice;
8. external standards and references used to vet whether new patterns were real, emerging, or merely local preference.

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

## 17. Why successful path capture was added

After v1.5, a new operational insight was added: every successful non-trivial edit path is a reusable asset.

The original protocol already required replay, continuation, metadata, and housekeeping. But it did not explicitly say what to do with a successful route through the codebase after the work was complete. Without capture, the next agent still has to manually read files, trace references, infer boundaries, and rediscover commands before making a similar small edit.

The added rule is:

```text
When a successful path is likely to recur, distill it into a scriptable path recipe.
```

### Why this belongs in the baseline

This extends the same doctrine that produced composites and workflows:

```text
Do not pay repeated reasoning cost for a path that can be encoded once.
```

It also matches established codemod practice. Mature refactoring ecosystems use recipes, runners, AST transforms, and testable transformations to make repeated edits cheap, reviewable, and consistent. The protocol does not require every path to become a codemod; it creates levels from note -> command -> patch recipe -> codemod -> composite/workflow.

### Why it is not just documentation

A recipe is operational memory. It records:

- where the agent started;
- how it navigated;
- which files/symbols mattered;
- what edits were safe;
- which command verifies the result;
- when to promote the path into a script, codemod, composite, or workflow.

### Constraint

Do not generate recipes for one-off trivia. Recipes must reduce future discovery cost. If a recipe becomes stale, housekeeping must remove, archive, or mark it deprecated so it does not pollute future search.

---

## 18. Why naming convention belongs in the baseline

Naming was originally treated as a style concern — a matter of taste left to linters or team preference. That changed when it became clear that agents discover files, tools, and functions by name before they open them.

Names are routing signals. A poorly named file or function forces an agent to open, read, and infer intent before it can decide whether to use, wrap, or ignore the artifact. In a repository with dozens of scripts, skills, adapters, and composites, this discovery tax is paid repeatedly.

The naming convention was elevated to protocol level because:

- **Search quality:** agents use name-based discovery (glob, tool catalog, directory listing) before content search;
- **Tool selection:** an MCP tool or CLI command named by user intent is chosen correctly more often than one named by backend topology;
- **Adapter boundaries:** names that include phase or risk words (`dry-run`, `sandboxed`, `pre-`) help agents classify operations without reading code;
- **Scriptable recipes:** recipe files must be discoverable by future agents; a name like `SCRIPTABLE_PATH_RECIPE.md` is self-selecting.

The convention does not demand uniformity for uniformity's sake. It demands that a name answer the agent hesitation test: *If an agent sees this name in a listing, will it know whether to open or use it?*

If the answer is no, the name is a bug.

---

## 19. Final baseline thesis

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

## 20. Reviewer questions

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

## 21. Reference anchors used during v1.5 vetting

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
| Automated refactoring | OpenRewrite / jscodeshift / codemod practice | Supports capturing successful repeated edit paths as recipes, commands, scripts, or AST-aware codemods. |

---

## 22. What should not be forgotten

The protocol began with a practical frustration: agents were wasting time rewriting solved tools.

Everything added later — base/adapters, result envelopes, conformance, AGENTS.md, LSP, sandboxing, provenance, observability, housekeeping — exists to preserve the same underlying goal:

```text
Stop paying repeated reasoning cost for decisions that can be encoded once.
```

That is the heart of v1.5.

---

## 2026-05-23: v1.6 — Grounding the protocol in field practice

This entry records why v1.6 exists and how the protocol was tightened for real agent-operated work.

### Terminology moved toward ports and adapters

The earlier wording used "base" as the main architectural noun because it was easy to explain. In practice, external reviewers and stateless agents recognise "ports and adapters" more quickly. v1.6 therefore aligns the main model with that vocabulary while preserving the original intent: isolate invariant behavior from delivery surfaces.

The important refinement is that the core owns business behavior while ports declare the interfaces. Adapters translate runtime details into those interfaces. This keeps the protocol accurate for reviewers familiar with hexagonal architecture and still practical for agents.

### Boundary ambiguity was moved out of the core protocol

The port/adapter boundary can blur in real projects. A CLI may contain validation. An MCP tool may need safety checks. A web handler may contain auth extraction. Embedding every nuance in the main protocol would make it too heavy for runtime use.

The protocol now keeps a small boundary test in the main file and moves examples to `reference/PORT_ADAPTER_BOUNDARY_NOTES.md`. This gives agents a fast default path and reviewers a deeper guide when needed.

### Surface types were reduced to the core five

The earlier baseline carried many surface types. That was accurate but heavy. v1.6 keeps five core surfaces: port library, CLI adapter, API/Web adapter, MCP adapter, and worker adapter.

LSP, sandbox, prompt/skill, telemetry exporter, and supply-chain verification remain important, but they are treated as advanced adapters or separate components under `advanced/`. This keeps the main protocol teachable while leaving room for expansion.

### Salvage became explicitly multi-agent

The user's environment separates upstream research from local building. A research agent or URP run finds candidates, pattern sources, gaps, and rejected paths. A local build agent consumes that packet instead of repeating the whole search.

v1.6 keeps "ready-made first" mandatory for reusable work, but it no longer pretends one agent must do every step. For Level 2 work, the build agent needs a `salvage_request` or must stay at Level 0 until research exists.

### Naming became semantic before stylistic

Earlier naming rules covered formatting, but the deeper problem is inferability. Agents do not merely read names; they route on names. A weak name makes the agent hesitate, choose a primitive, or open multiple files unnecessarily.

v1.6 moves intent, user-facing vs agent-facing distinction, world-view clarity, and risk inference before formatting. `reference/THE_ART_OF_NAMING.md` carries the longer guide.

### Conformance was compressed

The five-level ladder was useful during design, but too heavy for daily use. v1.6 reduces it to three levels: Experimental, Operable, and Platform. This preserves promotion pressure without making every small tool feel like enterprise governance.

The conformance gate is now a machine-readable checklist (`templates/CONFORMANCE_CHECKLIST.yml`) rather than a large review ceremony. This is cheaper for agents and easier to automate.

### Done definition became smaller but sharper

The done definition was reduced to the essentials: intent/risk/surface, boundary clarity, structured output, tests, dry-run for mutation, successful path recipe, and housekeeping.

The new recipe requirement is important. When an agent discovers a successful edit path, that path becomes an asset. Capturing it prevents future agents from spending expensive context to rediscover the same route.

### Budgets, continuation, and handoff were promoted

Field practice showed that long sessions fail when agents lose context, repeat research, or cannot resume partial work. v1.6 adds compact handoff packets (`schemas/handoff-packet.json`), budgets, continuation tokens, and result fields that explain user goal, cost/value, and reasoning mode.

The goal is not to expose private reasoning. The goal is to leave enough structured state for the next agent to continue safely.

### Repository restructuring

v1.5 adapter files were consolidated and renamed for clarity. The `adapters/` directory now contains only the four core surfaces. Advanced surfaces (LSP, sandbox, skill) moved to `advanced/`. Reference guides split into `reference/PORT_ADAPTER_BOUNDARY_NOTES.md` and `reference/THE_ART_OF_NAMING.md`. All replaced v1.5 files are archived under `archive/v1.5/INDEX.md`.

### External anchors used in v1.6

The revision was checked against established references: ports-and-adapters/hexagonal architecture for the boundary model; AGENTS.md for agent instruction placement; MCP security guidance for least privilege; JSON Lines for streaming structured CLI output; OpenTelemetry for observability vocabulary; SemVer for version signaling; NIST SSDF and SLSA for secure development and supply-chain posture.

### Final stance

v1.6 is intended as a stable operational baseline. Future changes should usually be adapter-specific unless a new cross-domain pattern clearly improves agent safety, replayability, maintainability, or cost.

---

## 2026-05-24: PARA — project agent-readiness audit companion protocol

This entry records the addition of `reference/PROJECT_AGENT_READINESS_AUDIT.md`.

### Origin

The protocol was extracted from a field audit of a multi-store FnB webapp. The audit began with normal debugging and expanded into workflow hardening: branch drift, store provisioning, Firebase auth, Cloudflare naming, Imgur setup, Python/uv runtime pinning, script naming, stale-doc scans, and journaled decision records.

### Decision

PARA is a UBAP companion protocol, not a replacement for UBAP.

UBAP defines the structural contract: core/base, port, adapter, rules/config, recipe, artifact, drift control.

PARA checks whether a project workflow is actually operable by weak, stateless, or future agents.

### Adaptive scale

The protocol is deliberately adaptive:

- Small projects use Lite PARA: naming, runtime, dependency, and dry-run/syntax checks.
- Medium projects use Standard PARA: workflow simulation, boundary, scriptability, auth/runtime/docs checks, validation, and journal entry.
- Large projects use Full PARA: end-to-end scenario rehearsal, read-only verifier before mutator, external-service and drift checks, runtime reproducibility, docs-chain update, stale-reference scan, and journal decision record.

This prevents small MCP/CLI tools from inheriting full-stack ceremony while making full-stack and multi-tenant workflows prove agent-readiness before they are called done.

### Done definition update

The core done definition now requires medium and large operating workflows to have a scale-appropriate Project Agent-Readiness Audit or an escape hatch explaining why it was deferred.

### Documentation chain

Updated:

- `README.md`
- `AGENTS.md`
- `METADATA.yml`
- `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md`
- `UNIVERSAL_BASE_ADAPTER_PROTOCOL_v1.6.md`

### Rationale

The key lesson is that useful agent work should not end as private reasoning. If a session discovers a future workflow risk, the result should become a script, a clearer name, a validation gate, a doc-chain update, or a protocol rule.
