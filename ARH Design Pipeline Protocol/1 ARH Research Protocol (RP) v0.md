# Universal Research Protocol (URP) v3.1.2

**Name:** Universal Research Protocol  
**Version:** 3.1.2  
**Status:** Revised baseline candidate  
**Purpose:** Gather source-grounded, high-quality patterns, references, gaps, and anti-patterns for downstream build planning (RBSP).  
**Target environment:** Windows + PowerShell (`pwsh`) agent operation by default, while patterns from any ecosystem remain admissible when they can be salvaged, adapted, benchmarked, or used as warnings.

---

## 0. Position in Build Chain

```text
User Need → URP (research) → RBSP (synthesis) → ATBIP (implementation) → UBAP conformance gate → Runtime
```

URP output must be directly usable by a downstream build planner without repeating the search.

The full chain operates under the Universal Base/Adapter Protocol (UBAP v1.6). URP seeds the risk and surface fields that RBSP locks and ATBIP writes into METADATA.yml for the conformance gate.

---

## 1. Core Principle

Research finds **design leverage**, not popular tools.

Every candidate must answer at least one:

- What pattern can be salvaged?
- What component can be integrated?
- What reference behavior can be benchmarked?
- What gap does this fill?
- What failure or anti-pattern does it warn against?
- What downstream build decision does this materially improve?

A candidate that does not change a future build decision is research inventory, not URP material.

---

## 2. Operating Bias

1. Pattern fit over popularity  
2. End-to-end use-case fit over domain fame  
3. Extractable architecture over direct portability  
4. Agent-operability over human-only usability  
5. Evidence over vibes  
6. Gap completion over redundant options  
7. Verification before commitment  
8. Minimal dependency gravity  

---

## 3. Scope Extraction

Before searching, convert the user request into a compact research frame.

- User goal  
- Target system (default: Windows + `pwsh`)  
- Intended build mode (`pattern extraction | direct integration | new tool | hybrid`)  
- Primary output expected (`CLI | MCP server | library | workflow | document | service`)  
- Hard constraints  
- Soft preferences  
- Required capabilities  
- Known environment  
- Risk sensitivity (`low | medium | high`)  
- UBAP risk class (`read_only | local_mutation | external_mutation | destructive | open_world`) — translate risk sensitivity into the canonical UBAP term; carry forward to RBSP verbatim  
- UBAP risk modifiers (`secret_bearing | regulated_data | network_access | filesystem_broad_scope | privileged_auth | generated_code_execution | payment_or_cost_impact`) — list all that apply; empty list is valid  
- Downstream consumer (`RBSP | build planner | implementation agent`)  

If the user asks for a tool, research both:

- tools/components that already solve the problem;
- systems whose internal design can be salvaged into a better tailored build.

---

## 4. Search Lanes

Search in parallel lanes, not one keyword path.

| Lane | Search focus |
|------|---------------|
| Direct solution | Existing tools/components for the task |
| Pattern | Architectures, algorithms, DSLs, workflows, schemas |
| Ecosystem | Package managers, inspectability, runtime, dependency drag |
| Agent operability | Non-interactive mode, JSON output, schemas, exit codes, deterministic behavior |
| Gap | Missing capabilities required for end-to-end fit |
| Anti-pattern | Known failures, abandoned approaches, fragile integrations |

The final output should make clear which lane produced each useful candidate when that context affects the build.

---

## 5. Candidate Roles and Use Modes

Every worthy candidate gets one primary role and one use mode.

### 5.1 Candidate Roles

| Role | Meaning | Downstream treatment |
|------|---------|---------------------|
| `[PATTERN]` | Design to salvage: architecture, algorithm, schema, workflow, UX, or API contract. No runtime adoption required. | Extract mechanism; avoid inheriting ecosystem gravity by default. |
| `[INTEGRATE]` | Can be used as-is, installed, invoked, wrapped, or embedded with justified operational cost. | Validate runtime, license, automation, and output contract before adoption. |
| `[GAP FILLER]` | Covers a missing sub-capability needed for full end-to-end fit. | Use, wrap, or reimplement only the missing piece. |
| `[ANTI-PATTERN]` | Shows what to avoid or where existing solutions break. | Preserve warning, rejection reason, and failure mode. |

### 5.2 Use Modes

Use mode preserves decision precision without expanding the role taxonomy.

| Use mode | Meaning |
|----------|---------|
| `salvage` | Extract the pattern/mechanism only. |
| `integrate` | Use directly, wrap, or embed after validation. |
| `benchmark` | Treat as behavioral, UX, command, or output reference; not necessarily adopted. |
| `gap_fill` | Use to close a specific missing capability. |
| `reject` | Preserve as warning or ruled-out option. |

Example: a mature CLI may be `[PATTERN]` with `use_mode: benchmark` when its UX and error shape are valuable but direct integration is not.

---

## 6. Evaluation Criteria

Apply these qualitatively. Do not use scoring formulas unless the user explicitly asks for a numerical ranking.

**For any candidate:**

- `RelevanceFit`
- `SourceReliability`
- `FrictionCost`
- `RiskProfile`
- `EvidenceStrength`

**For `[PATTERN]`:**

- `PatternRichness`
- `Extractability`
- `GapCoverage`
- `WindowsAdaptability`

**For `[INTEGRATE]`:**

- `PlatformFit`
- `AgentOperability`
- `RuntimeDeployability`
- `LicenseViability`
- `OutputContractFit`

**For `[GAP FILLER]`:**

- exact coverage of missing piece
- integration or reimplementation friction
- replacement cost if omitted

**For `[ANTI-PATTERN]`:**

- failure relevance
- likelihood of recurrence in this build
- warning value for downstream agents

---

## 7. Hard Quarantine Gates

Quarantine a candidate for `[INTEGRATE]` when any apply:

- Violates an explicit user constraint
- License is incompatible with intended use
- Requires unsupported OS, runtime, GUI, service, or unsafe privilege
- Requires interactivity with no automation path
- Has no inspectable or verifiable source for direct use
- Creates security exposure disproportionate to value
- Cannot provide or be wrapped into machine-readable output where the build requires agent tooling

Quarantined candidates may still remain as `[PATTERN]`, `[GAP FILLER]`, or `[ANTI-PATTERN]` if their design, sub-capability, or failure mode is useful.

Do not silently delete quarantined candidates when they explain an important rejection or prevent repeated research.

---

## 8. Risk Flags

Risk flags are not automatic rejection for pattern salvage. They are signals for RBSP and implementation planning.

Mark critical warnings only:

- License needs review before integration
- Interactive-only interface
- No machine-readable output where agent tooling needs it
- Requires unsafe privileges without clear need
- Abandoned with unresolved critical issues
- No verifiable source yet
- Heavy runtime or dependency chain for a small reusable pattern
- Network/auth/secrets required for basic operation
- Stale or unmaintained candidate

For `[INTEGRATE]`, risk flags may trigger quarantine under Section 7. For `[PATTERN]`, risk flags usually become adaptation notes.

---

## 9. Platform and Agent Tags

### 9.1 Platform tags

Use max three platform tags per candidate.

| Tag | Meaning |
|-----|---------|
| `[WIN-NATIVE]` | Native Windows executable, installer, or directly runnable binary. |
| `[WIN-RUNTIME]` | Needs Python, Node, Go, .NET, Java, or similar runtime on Windows. |
| `[LINUX-HOSTED]` | Requires WSL, Docker, or Linux; pattern-only unless user approves runtime. |
| `[CROSS-PLATFORM]` | Explicitly supports Windows and at least one other major OS. |
| `[SOURCE-ONLY]` | Source/design inspectable, but direct execution path is not established. |

### 9.2 Agent-operability tags

| Tag | Meaning |
|-----|---------|
| `[JSON-OUT]` | Structured JSON or equivalent machine-readable output. |
| `[NO-PROMPT]` | Non-interactive execution path exists. |
| `[STDIN-STDOUT]` | Composable filter or stream interface. |
| `[IDEMPOTENT]` | Safe to repeat or repeat effects are detectable. |
| `[DRY-RUN]` | Can preview mutation impact. |
| `[STABLE-ID]` | Returns durable IDs/references for follow-up calls. |
| `[INTERACTIVE]` | Problematic for agents; negative tag unless only used as pattern. |

---

## 10. Candidate Evidence

Every retained candidate must include enough evidence for downstream use.

```yaml
candidate:
  name: ""
  source_url: ""
  source_kind: official_docs | github | registry | paper | blog | spec | issue | other
  role: PATTERN | INTEGRATE | GAP FILLER | ANTI-PATTERN
  use_mode: salvage | integrate | benchmark | gap_fill | reject
  fit_summary: "one sentence why it matters"
  salvageable_pattern_or_direct_use: ""
  platform_tags: []            # from Section 9.1
  agent_operability_tags: []   # from Section 9.2
  friction_or_risk: []         # critical warnings only
  verification_probe: "one command / code snippet (≤5 lines) that proves value or failure in <30 seconds"
  build_assertion: "If [condition], then [action] because [reason]"
  freshness: "checked (YYYY-MM-DD) | stale (>2y) | unmaintained | unknown"
  deps: "runtime: x, libs: y, network: z (one line)"
```

For `[PATTERN]` role, also add:

```yaml
windows_adaptation:
  difficulty: trivial | moderate | complex | near-impossible
  steps_estimate: "e.g., rewrite 200 lines of bash to pwsh"
  blocking_issues: []   # e.g., fork(), /proc, io_uring
```

For `[ANTI-PATTERN]` role, also add:

```yaml
warning_preserved:
  failure_mode: ""
  why_it_matters_to_this_build: ""
  downstream_guardrail: ""
```

---

## 11. Output Document

Produce a single Markdown document unless the user requests another format.

```markdown
# URP Output: [Topic]

## Research Frame
(short: goal, target env, hard constraints, required capabilities, downstream consumer)

## Candidates
| Candidate | Role | Use mode | Source kind | Source | Fit summary | Platform | Agent tags | Key pattern / direct use | Deps | Freshness | Verification probe | Build assertion |
|-----------|------|----------|-------------|--------|-------------|----------|------------|--------------------------|------|-----------|--------------------|------------------|

## Pattern Cards
(Only for top 1-3 PATTERN candidates.)

```yaml
pattern_name: ""
source: ""
problem_solved: ""
core_mechanism: ""
what_to_extract: []
what_to_ignore: []
adaptation_notes: ""
windows_adaptation:
  difficulty: trivial | moderate | complex | near-impossible
  steps_estimate: ""
  blocking_issues: []
verification_probe: ""
build_assertion: ""
```

## Searched & Not Found
Required when a required capability was searched and no usable candidate was found. Omit only when no meaningful negative search occurred.

| Capability | Search scope | Why nothing usable | Confidence |
|------------|--------------|--------------------|------------|

## Gap Map
| Required capability | Coverage | Best source(s) | Missing piece | Downstream action |
|--------------------|----------|----------------|----------------|--------------------|

## Anti-Patterns & Rejections
| Candidate / pattern | Why rejected or avoided | What to preserve |
|---------------------|------------------------|------------------|

## Conflicts & Resolutions
(Only when candidates contradict.)

| Contradiction | Candidates | Recommended resolution | Rationale grounded in constraints |
|---------------|------------|------------------------|-----------------------------------|
```

---

## 12. Quality Bar

A valid URP output lets the downstream RBSP/build planner answer:

- What design material is worth using?
- What should be integrated, wrapped, extracted, benchmarked, rejected, or built from scratch?
- Which source supports each useful candidate?
- What gap remains after the research?
- What negative path should not be repeated?
- What can be verified in under 30 seconds?
- What dependency or runtime cost is being imported?
- What risk changes the downstream design?
- What Windows/PowerShell adaptation is required?

If the build planner must repeat the search before acting, URP failed.

---

## 13. RBSP Handoff Rule

URP does not choose the final architecture. It prepares decision-grade material for RBSP.

A handoff is ready when the research output contains:

- a compact research frame including `ubap_risk_class` and `ubap_risk_modifiers`;
- candidate evidence with source kind, role, use mode, risk, freshness, deps, probe, and assertion;
- top pattern cards where patterns are worth salvaging;
- negative evidence when searches failed;
- a gap map;
- anti-patterns/rejections;
- conflict resolution when candidates disagree.

RBSP carries `ubap_risk_class` and `ubap_risk_modifiers` forward verbatim into the decision panel and ultimately into METADATA.yml. URP must not leave these blank when the build involves mutation, external calls, secrets, or filesystem writes.

URP should not become a build plan. That is RBSP’s job.
