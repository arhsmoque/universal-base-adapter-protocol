# Research-to-Build Synthesis Protocol (RBSP) v1.1

## Purpose

Turn URP research output into a compact, actionable design plan for an agent environment, tool, MCP server, CLI utility, context layer, or workflow component.

RBSP sits between URP (research) and ATBIP (implementation).

## Master Principle

Research is only useful when it changes the build. Every source, candidate, pattern, rejection, or recommendation must explain one of: what to use, adapt, reject, build from scratch, verify, or what risk changes the design.

## 1. Scope

Use RBSP when the user asks to:
- research tools, libraries, components, protocols, or implementation options
- compare design patterns
- choose what to port, wrap, adapt, or reject
- create a build plan from research
- design an agent-facing tool surface
- improve MCP, CLI, workflow, context, or automation architecture

Do not use RBSP when the user only wants a simple answer, a tutorial, or a plain list of links.

## 2. URP Handoff Mapping

URP v3.1.1 output fields map to RBSP inputs as follows:

| URP field | RBSP use |
|-----------|----------|
| `candidate.name` | Candidate identity |
| `candidate.role` (PATTERN/INTEGRATE/GAP FILLER/ANTI-PATTERN) | Adoption decision input |
| `candidate.use_mode` (salvage/integrate/benchmark/gap_fill/reject) | Directly informs decision |
| `candidate.build_assertion` | Preserved verbatim in decision record |
| `candidate.verification_probe` | Used in validation plan |
| `candidate.windows_adaptation` (for PATTERN) | Carried into pattern salvage |
| `candidate.deps` / `freshness` / `agent_operability_tags` | Adoption criteria |
| `gap_map` | Input for `build_from_scratch` decisions |
| `anti_patterns` | Input for `reject` decisions |

RBSP does not re‑research. It synthesizes.

## 3. Candidate Roles (from URP, kept)

| Role | Meaning | Downstream treatment |
|------|---------|---------------------|
| `[PATTERN]` | Design to salvage | Extract mechanism; do not inherit stack |
| `[INTEGRATE]` | Use as‑is or wrap | Validate runtime, license, automation |
| `[GAP FILLER]` | Covers missing sub‑capability | Use, wrap, or reimplement only missing piece |
| `[ANTI-PATTERN]` | Warning | Preserve rejection reason and failure mode |

## 4. Adoption Decisions

| Decision | Use When | Output Required |
|----------|----------|----------------|
| **Use** | Candidate fits environment and solves the need directly | Version/source, install/run note, smoke test |
| **Wrap** | Candidate useful but interface needs agent‑safe boundary | Wrapper contract, constraints, error handling |
| **Extract** | Candidate valuable mainly as pattern | Pattern summary, reimplementation target, LOC estimate |
| **Reject** | Candidate not worth using | Specific rejection reason (from URP anti‑pattern) |
| **Build from scratch** | No candidate fits or pattern is smaller than dependency | Minimal design, implementation units, tests |

Default bias: extract small patterns; avoid importing whole ecosystems for one behavior.

## 5. Candidate Evidence (preserved from URP)

For each candidate being considered, carry forward from URP:

```yaml
name: ""
role: ""
use_mode: ""
build_assertion: ""
verification_probe: ""
windows_adaptation: (if PATTERN)
deps: ""
freshness: ""
agent_operability_tags: []
```

Do not invent new evidence. Only synthesize decisions.

## 6. Pattern Salvage Rules

A pattern is salvage‑worthy only if it improves one of: correctness, safety, observability, agent decision load, portability, output structure, failure recovery, testability, maintainability, or user‑visible behavior.

For each salvaged pattern, specify:

```yaml
pattern_name: ""
source: ""
why_it_matters: ""
what_to_copy: ""
what_not_to_copy: ""
windows_adaptation: (from URP)
implementation_target: "pwsh | python | mcp_server | cli | skill | config"
test_probe: (from URP verification_probe or derived)
```

Do not copy architecture gravity accidentally.

## 7. Agent‑Operability Gate

Before adopting or designing a component, check:

- exposes intent, not backend topology
- accepts structured constraints instead of shell choreography
- returns structured observations
- provides stable IDs and evidence
- supports dry‑run for risky operations
- gives recoverable errors and next‑action hints
- avoids required interactivity
- is deterministic, idempotent, testable, versioned

If a tool makes the agent choose between low‑level backend options, the abstraction is too low.

## 8. Architecture Synthesis

Convert selected decisions into a compact architecture. Required elements:

```yaml
modules: []
data_flow: ""
read_write_boundary: ""
shared_utilities: []
external_dependencies: []
state_storage: ""
error_boundary: ""
observability: ""
security_boundary: ""
agent_interface: ""
dry_run_supported: true   # mandatory for write ops
idempotency: "yes | with_key | no"
```

Use an ASCII diagram only when it reduces ambiguity.

## 9. Implementation Unit Mapping

| Unit | Use When | Required Contract |
|------|----------|-------------------|
| Core library | Logic shared by CLI/MCP/agent skill | Inputs, outputs, errors, tests |
| MCP server | Agent calls external capability | Tool schema, output schema, safety notes |
| CLI adapter | Human/script execution | Commands, flags, JSON mode, exit codes |
| PowerShell script | Windows‑native automation | Parameters, object output, error behavior |
| Python script | Lightweight cross‑platform | Dependencies, venv note |
| Agent skill | Instructional capability | Trigger, steps, boundaries, examples |
| Config file | Adjustable behavior | Schema, defaults, override rules |
| Test harness | Validation | Smoke, failure, regression tests |

Prefer one core capability with multiple adapters.

## 10. Result Envelope Standard (inherited)

Every recommended tool should aim for this shape:

```json
{
  "status": "success | partial_success | error",
  "changed": false,
  "data": {},
  "evidence": [],
  "warnings": [],
  "errors": [],
  "next_actions": [],
  "trace_id": "",
  "duration_ms": 0,
  "dry_run": false
}
```

For mutating operations, also include: `affected_items`, `verification`, `reversible`, `undo`, `idempotency_key`.

## 11. Build Sequence

1. Define contracts and schemas
2. Build core pure logic
3. Add structured errors and result envelope
4. Add read/search/inspect path
5. Add dry‑run planner for mutations
6. Add narrow apply/mutate path
7. Add CLI/MCP/skill adapter
8. Add smoke tests and failure tests
9. Add logs, trace IDs, versioning
10. Document examples and anti‑patterns

Do not start with the adapter.

## 12. Validation

Minimum test set from URP: smoke, constraint, failure, dry‑run, idempotency, Windows/pwsh, output contract.

Each test must reference a verification probe (from URP or derived).

## 13. Output Contract

Produce a compact Markdown design plan (under 250 lines):

```markdown
# Research-to-Build Design Plan: [Name]

## 1. Decision Panel
- Goal:
- Target environment:
- Recommended direction:
- Adoption decisions (use/wrap/extract/reject/build_from_scratch):
- Main risk:
- First implementation step:

## 2. Research Findings That Change the Build

| Candidate | URP role | Use mode | Decision | Build assertion (from URP) | Verification probe |
|-----------|----------|----------|----------|----------------------------|--------------------|

## 3. Selected Design

[compact architecture diagram or module map; state read/write boundary; dry‑run support]

## 4. Pattern Salvage Cards (if any)

```yaml
pattern_name: ""
source: ""
what_to_copy: ""
what_not_to_copy: ""
windows_adaptation: ""
implementation_target: ""
test_probe: ""
```
```
## 5. Implementation Plan

| Step | Build Unit | Depends On | Done When |
|------|------------|------------|-----------|

## 6. Validation Plan

| Test Type | Method / Command | Expected Result | URP probe link |
|-----------|------------------|----------------|----------------|

## 7. Risks and Mitigations

| Risk | Mitigation | Reopen Decision If |
|------|------------|--------------------|

## 8. Decision Audit Trail

| Decision | Rationale | Alternative considered | Why rejected |
|----------|-----------|------------------------|--------------|
```

## 14. Minimal Mode (for small decisions)

```markdown
# Compact RBSP Decision

## Decision
-

## Why
-

## Adoption table
| Candidate | Decision | Reason | Verification |
|-----------|----------|--------|--------------|

## Build shape
-

## First step
-
```
```
## 15. Quality Bar

Output is valid only if a builder can answer:
- What should be built?
- Why this design over alternatives?
- Which URP candidates are used, wrapped, extracted, rejected, or built from scratch?
- What pattern is being salvaged?
- What implementation units are needed?
- What is the first build step?
- How will success be tested?
- What risks can reopen the decision?
- Where is the URP verification probe applied?

If the answer is “read the URP output again,” RBSP failed.
```

---