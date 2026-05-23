# Agent Tool Build & Implementation Protocol (ATBIP) v1.2.0

**Purpose:** Turn an RBSP Build Specification into a working, tested, agent‑operable tool. Starts after RBSP. Does not redesign.

**Target environment:** Windows + PowerShell (`pwsh`) unless RBSP says otherwise.

**Adaptive principle:** Use the full protocol for complex builds. For small tools (single file, no external deps, pure logic), skip optional sections but keep contracts, smoke test, and handoff.

---

## 0. Position in Chain

```
URP → RBSP → ATBIP → Runtime
```

## 1. Core Principle

Build the smallest correct tool that preserves the RBSP design intent. Every file, function, test, and config must trace to: a required capability, an RBSP implementation unit, a selected pattern, a safety boundary, a validation requirement, or a handoff requirement.

## 2. Operating Bias

1. Contract first, code second  
2. Core logic before adapters  
3. Structured output before pretty output  
4. Read paths broad, write paths narrow  
5. Dry‑run before mutation (mandatory for writes)  
6. Deterministic tests before polish  
7. Explicit state before hidden state  
8. Stable schemas before clever behavior  
9. Small dependencies before ecosystem gravity  
10. Handoff‑ready over locally working only  

## 3. Input Contract (from RBSP)

ATBIP expects an RBSP Build Specification containing at least:

- `implementation_units` (list)
- `validation_plan` (test types and verification probes)
- `risk_register` (or note that none exist)
- `ubap_surface` — canonical UBAP surface type
- `ubap_risk_class` — canonical UBAP risk class
- `ubap_risk_modifiers` — list (may be empty)
- `ubap_conformance_target` — 0, 1, or 2
- `provider_hint` — intended agent runtime

If any of the first three are missing, mark `input_status: "blocked"` and return the missing list.  
If the UBAP fields are missing, default `ubap_conformance_target` to 1 and log a warning — do not block, but note the gap in the handoff.  
Do not improvise architecture – only implementation.

## 4. Build Readiness Gate

Before coding, verify:

| Gate | Pass condition |
|------|----------------|
| Capability coverage | Every must‑have capability maps to a unit |
| Interface contract | Each operation has inputs, outputs, errors, verification |
| State model | Persistent/transient state is named and located |
| Error model | Recoverable vs fatal errors distinguishable |
| Validation plan | Smoke, failure, dry‑run (if writes), idempotency (if retryable) tests exist |
| Risk register | High‑risk actions have mitigation (dry‑run, confirmation) |
| Environment fit | Runtime/toolchain available or install path defined |
| UBAP fields present | `ubap_surface`, `ubap_risk_class`, `ubap_conformance_target` available from RBSP |

No mutating implementation starts until read/write boundaries and dry‑run are specified.

## 5. Implementation Unit Contract (minimal)

Each unit must have:

```yaml
name: ""
type: "core_library | cli_adapter | mcp_adapter | pwsh_script | python_script | ts_cli | go_cli | rust_cli | config_schema | state_store | test_pack | skill_doc"
responsibility: ""
dependencies: []   # name + purpose + license
inputs: []         # schema or description
outputs: []        # schema or description
errors: []         # recoverable error types
tests_required: [] # test types from Section 12
```

## 6. Build Order

1. Scaffold, schemas, and METADATA.yml — generate `METADATA.yml` from RBSP decision panel fields (`ubap_surface`, `ubap_risk_class`, `ubap_risk_modifiers`, `ubap_conformance_target`, `provider_hint`). Set `commands.smoke` from RBSP verification probe. Set `owner` and `version`. Use `templates/METADATA.yml` from the UBAP repository as the base. METADATA.yml is a build artifact, not a handoff artifact — create it now, update it as the build proceeds.  
2. Core pure logic  
3. State/config layer (if needed)  
4. Error/result envelope  
5. Read operations  
6. Dry‑run planners (if any write)  
7. Mutating operations (with dry‑run enforcement)  
8. CLI/MCP/adapter layer  
9. Test harness (including verification probes)  
10. Packaging/install scripts  
11. Documentation  
12. Recipe capture — if the build path is non-trivial and likely to recur, distill the successful route into a recipe entry for `recipes/index.yml`. Minimum fields: `name`, `description`, `inputs`, `execution_strategy`, `dry_run`, `verification`. If the path is one-off or trivially short, record `recipe: none — one-off` in METADATA.yml. Do not skip this step silently.  
13. Handoff packet  

## 7. Folder Structure (recommended)

Keep separation of core, adapters, tests, docs. For small tools, flatten but comment boundaries. No mandatory layout.

## 8. Result Envelope Standard (from RBSP)

Implement exactly as RBSP specifies. For writes, also include:

- `dry_run` boolean  
- `idempotency_key` when operation is not naturally idempotent  

## 9. Agent‑Facing Operation Pattern

Each operation must:

- Express intent (not backend choreography)  
- Support `--dry-run` (for writes) unless RBSP explicitly waives  
- Accept structured inputs (JSON or flags)  
- Output structured result envelope  
- Be non‑interactive by default (no prompts)  
- Be idempotent or accept idempotency key  

Implementation rule: `agent expresses intent → tool resolves → result describes reality`.

## 10. Read / Write Boundary

**Read:** may search broadly, rank, dedupe, infer defaults, retry safely.  
**Write:** must require stable IDs, support dry‑run, validate preconditions, report exact changes, define verification, define undo/compensation, and be idempotent or accept key.

Never hide mutation inside a read operation.

## 11. Configuration and State

Prefer stateless. If state required, declare:

```yaml
persistent_files: []
cache_files: []
config_files: []
temp_files: []
locks: []
cleanup_commands: []
```

No hidden global config. No writes outside declared locations.

## 12. Error Taxonomy (qualitative)

Use these classes – numeric codes optional.

| Class | Meaning | Agent action |
|-------|---------|--------------|
| `user_error` | Bad input, missing flags, invalid target | Fix invocation, do not retry blindly |
| `state_conflict` | Resource lock, file exists, version mismatch | Inspect, narrow target, or ask user |
| `external_failure` | Network, API, missing dependency | Retry with backoff if safe |
| `internal_bug` | Unexpected panic, invariant violation | Stop and report |

Error shape:

```json
{
  "error_type": "user_error | state_conflict | external_failure | internal_bug",
  "message": "",
  "recoverable": true,
  "retryable": false,
  "suggested_next_actions": [],
  "evidence": []
}
```

## 13. Non‑Interactive Execution

Tools must never require prompts for automatable operations.

Required: `--json` (or equivalent), `--no-interactive`, `--dry-run` (for writes), `--yes` only after dry‑run, `--no-color`, deterministic under CI, timeout‑safe.

## 14. Dependency Policy

For each dependency, record: name, version, purpose, license, runtime cost.  
Prefer stdlib or small inline implementation unless dependency clearly reduces total cost.

## 15. Adaptive Test Strategy

**Minimum for all builds:**

| Test type | Required when |
|-----------|---------------|
| Smoke test | Every tool (must run URP/RBSP verification probe) |
| Failure test | Every recoverable error type |
| Dry‑run test | Every write operation |
| Idempotency test | Every retryable mutation |

**Add as build grows:**

| Test type | Trigger |
|-----------|---------|
| Contract test | Operation has formal schema |
| Unit test | Core logic has branching or state |
| Platform test | Default environment = Windows + pwsh |
| Packaging test | Tool is installable via package manager |

Each test must include a command/method and expected result.  
The smoke test must execute the verification probe from URP (or derived from RBSP).

## 16. Validation Ladder

Schema validates → core unit tests pass (if any) → failure tests pass → dry‑run tests pass → smoke test passes → packaging test passes (if applicable) → **UBAP conformance gate passes** → handoff complete.

**UBAP conformance gate:** run `python -B scripts/check_conformance.py <component_dir> --level <ubap_conformance_target> --json` from the UBAP repository against the component directory. The result must show `verified_level >= ubap_conformance_target` with no `"severity": "error"` findings. If the gate fails, findings become implementation deviations — record in §17 and resolve before handoff. A component does not exit ATBIP at its claimed conformance level until the checker agrees.

Bash fallback (Linux agents): `python -B scripts/check_conformance.py <component_dir> --level <ubap_conformance_target> --json`

## 17. Deviation Handling

Any deviation from RBSP must be recorded with: deviation, reason, risk, and condition to reopen decision. Deviations block handoff unless explicitly accepted by user or RBSP designer.

When a deviation bypasses a UBAP protocol rule (not merely RBSP intent), a deviation table row is not sufficient. Also produce an `ESCAPE_HATCH_NOTE.md` entry meeting all six UBAP conditions:

| Condition | Meaning |
|-----------|---------|
| **Named** | Clear, unique identifier for this bypass |
| **Scoped** | Exactly which UBAP rule is bypassed, and where |
| **Justified** | Why the rule cannot be followed in this case |
| **Bounded** | When/how the bypass ends or is revisited |
| **Observable** | How a future agent can detect the bypass is still in effect |
| **Recoverable** | How to restore full compliance if the constraint changes |

If uncertain whether a deviation crosses a UBAP rule, consult `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md §14`.

## 18. Install Contract

Each build must specify:

```yaml
prerequisites: []
install_steps: []
command_name: ""
version_command: ""
schema_command: ""
smoke_test_command: ""   # must pass
uninstall_or_cleanup: ""
```

## 19. Documentation Minimum

- **README.md:** what it does, install, smoke command, example  
- **operations.md:** contracts (inputs, outputs, errors)  

For larger builds, also CHANGELOG.md and troubleshooting.md as needed.

## 20. Handoff Output

ATBIP produces two distinct artifacts. They serve different consumers and must not be merged.

### 20a. ATBIP Completion Summary (post-build record)

Produced once at build completion. Human and agent readable. Permanent record.

```markdown
# ATBIP Completion Summary: [Build Name]

## Built artifacts
- Files:
- Commands:
- METADATA.yml: (path)
- UBAP conformance: verified_level=N, target=N, gate=pass|fail

## Verification
- Smoke test command (verification probe):
- Probe result: (pass/fail + evidence)
- All required tests passed: yes/no (list if no)
- UBAP conformance gate: pass|fail (findings if fail)

## Deviations from RBSP
| Deviation | Reason | Risk | Reopen if | ESCAPE_HATCH_NOTE? |
|-----------|--------|------|-----------|---------------------|

## Recipe captured
- recipes/index.yml entry: yes | no — one-off

## Known limitations
## Next actions for maintainer
## Do not repeat (anti‑pattern reminders)
```

### 20b. UBAP Continuation Packet (mid-task handoff)

Produced when the build is interrupted and handed to a different agent mid-flight. Uses the UBAP `handoff-packet.json` schema. Must be valid JSON.

```json
{
  "intent": "short statement of overall build goal",
  "completed_steps": ["step descriptions matching §6 build order"],
  "remaining_work": "next step and what is unfinished",
  "continuation_token": "opaque reference to build state artifact or null",
  "budget_left": 0,
  "provider_hint": "any | anthropic | openai | google",
  "attachments": ["path/to/METADATA.yml", "path/to/rbsp-spec.md"]
}
```

The receiving agent reads the continuation packet, loads `attachments`, and resumes at `remaining_work`. It does not re-read URP or RBSP from scratch.

Produce 20b whenever `budget_left` is low, context is near limit, or an explicit handoff is requested. Produce 20a only at build completion.

## 21. Quality Bar

ATBIP output is valid only if:

- The tool traces back to RBSP implementation units.  
- Contracts exist before or alongside code.  
- Output is structured and stable.  
- Errors are classified (user, state, external, bug).  
- Write operations have dry‑run and idempotency (or key).  
- Tests cover smoke, failure, dry‑run, idempotency.  
- Install/run/smoke commands are documented and tested.  
- Deviations from RBSP are recorded; UBAP rule bypasses also have `ESCAPE_HATCH_NOTE.md`.  
- METADATA.yml exists and is filled from RBSP fields.  
- UBAP conformance gate passed at `ubap_conformance_target` level.  
- Recipe captured in `recipes/index.yml` or explicitly marked one-off.  
- Completion Summary (20a) produced at build end.  
- Continuation Packet (20b) produced if build was interrupted or handed off mid-flight.  

A future agent can install, run, validate, debug, and extend the tool without re‑reading URP or RBSP.

---

**End of ATBIP v1.1.1**