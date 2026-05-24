# Project Agent-Readiness Audit Protocol

Short name: PARA  
Status: UBAP companion protocol  
Purpose: verify that a project workflow is safe, deterministic, and cheap for weak, stateless, or future agents to operate.

---

## 1. Relationship To UBAP

UBAP defines the structural contract:

- Core / Base
- Port
- Adapter
- Rules / Config
- Recipe
- Artifact
- Drift control

PARA audits operational agent-readiness:

- Can a stateless agent infer what to run?
- Can it stop before destructive or external side effects?
- Can it avoid recreating external resources that should be shared?
- Can it replay the workflow later without version, dependency, auth, or documentation drift?

PARA does not replace UBAP. It is the scale-aware audit layer for proving that a UBAP-shaped project is actually operable.

---

## 2. When PARA Is Required

Run a PARA pass before declaring a workflow agent-safe when the work involves any of:

- full-stack applications;
- medium-scale CLI, MCP, worker, API, or automation tools;
- deployment or release workflows;
- credentials, auth refresh, external services, billing, or hosted infrastructure;
- multi-tenant, multi-store, multi-branch, or generated-artifact workflows;
- runtime or dependency pinning;
- migration from manual process to scriptable recipe;
- a repeated workflow likely to be operated by future agents.

For trivial one-file changes, PARA is optional. For medium and large projects, PARA becomes part of done.

---

## 3. Adaptive Depth

PARA scales to the project. Do not apply full-stack ceremony to a tiny local tool, and do not accept a shallow checklist for a multi-service deployment.

| Scale | Examples | PARA depth | Required evidence |
|---|---|---|---|
| Small | One-off script, narrow local CLI, tiny adapter | Lite | Naming check, runner/dependency check, one dry-run or syntax check, short journal note if workflow changed |
| Medium | MCP server, reusable CLI, worker, API adapter, shared automation recipe | Standard | Workflow simulation, boundary audit, scriptability audit, auth/runtime/docs checks, validation commands, journal entry |
| Large | Full-stack app, multi-service platform, multi-tenant/store deployment, production release flow | Full | End-to-end scenario rehearsal, read-only verifier before mutator, external-service/auth audit, drift checks, runtime reproducibility, docs-chain update, stale-reference scan, journal decision record |

Escalate one level if the workflow includes destructive mutation, privileged auth, payments/cost impact, regulated data, broad filesystem access, or generated code execution.

---

## 4. Output Standard

A PARA pass produces concrete artifacts, not just review prose.

Expected outputs, scaled by depth:

- fixed scripts or added recipes where repeatable work exists;
- read-only verifier before mutating provisioner for medium/large workflows;
- structured JSON result envelopes for agent-facing recipes;
- updated human docs and agent docs;
- stale-reference scan results;
- validation command results;
- a journal entry explaining request, simulation, findings, fixes, and residual caveats.

If no change is needed, record why no change was needed.

---

## 5. Audit Stages

### 5.1 Workflow Simulation

Pick a realistic future task and rehearse it from start to finish.

Record:

- inferred values;
- commands a weak agent would run;
- expected outputs;
- blockers;
- manual steps;
- places the agent might create or request the wrong external resource;
- places the agent might proceed into a partial deployment.

For small projects, this can be a short dry-run. For large projects, use a realistic end-to-end scenario.

### 5.2 Boundary Audit

Name the durable boundaries and verify scripts preserve them.

Check:

- core/base files are not deployment-specific;
- adapters are not blindly copied as base;
- generated branches/artifacts are not treated as source;
- infrastructure config is not duplicated per tenant unless intended;
- recipes express the boundary in their names and output fields.

### 5.3 Scriptability Audit

Find every manual, repeated, or fragile action.

Convert repeatable work into named recipes. Prefer:

- read-only verifier before mutating provisioner;
- JSON result envelope;
- explicit `ok`, `checks`, `errors`, `warnings`, `next_command`;
- hard stop before external mutation;
- explicit partial-work escape hatch if bypass is allowed.

### 5.4 Naming Audit

Reject phase-only or topology-only names.

Weak:

- `preflight.py`
- `deploy.py`
- `sync.py`
- `helper.py`
- `api_runner.py`

Stronger:

- `verify-new-store-deployment-readiness.py`
- `provision-new-store-deployment.py`
- `sync-base-engine-to-store-branches.py`
- `migrate-store-config-field.py`
- `verify-mcp-server-release-readiness.py`

Run the inferability test: from name alone, can a new agent infer object, action, side effect, risk, and likely output?

### 5.5 Auth And External-Service Audit

Check that agents cannot accidentally create, request, or mutate the wrong resource.

Verify:

- credentials are required before mutation;
- auth/token refresh happens before git or remote side effects;
- missing credentials stop the workflow unless an explicit partial-work flag exists;
- docs say which resources are shared and must not be recreated;
- recovery commands are scriptable;
- approval boundaries match risk.

### 5.6 Runtime Reproducibility Audit

Check every script runner and dependency boundary.

Verify:

- scripts use the canonical runner;
- runtime version is pinned or intentionally bounded;
- dependencies are pinned or intentionally bounded;
- shell examples match the actual operating environment;
- docs do not contain stale command variants;
- upgrade path is explicit for pinned runtime/dependencies.

### 5.7 Scalability Audit

Check whether the workflow will still work when the project grows.

Small projects:

- Is the script name still clear when there are five scripts?
- Is the dependency pin enough for repeatability?
- Is there a cheap dry-run?

Medium projects:

- Can agents discover the correct recipe without reading all docs?
- Are input schemas or examples provided?
- Are failure modes structured enough for automation?
- Are auth and external-service assumptions explicit?

Large projects:

- Are base/adapter/artifact boundaries enforced by scripts?
- Are tenant/store/customer branches or configs generated deterministically?
- Are drift checks available before deployment?
- Are runtime/dependency versions pinned?
- Are docs, metadata, recipe index, and journal updated together?
- Is there a replayable end-to-end rehearsal?

### 5.8 Documentation Chain Audit

Update every layer future agents might read:

- `AGENTS.md` for operating rules;
- `README.md` for human workflow;
- `METADATA.yml` for machine-readable project surface;
- `recipes/index.yml` or equivalent for recipe discovery;
- recipe docstrings and help output;
- `JOURNAL.md` or decision log for reasoning.

Run stale-reference scans for:

- old script names;
- old schema names;
- wrong shell syntax;
- deprecated commands;
- old external-service paths;
- old model/runtime/dependency IDs;
- stale recipe names.

### 5.9 Validation Gate

Run the smallest deterministic checks that prove the audit did not break the workflow.

Examples:

- recipe `--help`;
- dry-run;
- syntax/type checks;
- schema parse;
- conformance checker;
- drift checker;
- stale-reference scan;
- `git diff --check`.

Expected failures must be labelled as expected. Example: a readiness check failing because credentials are not set can be correct during a dry audit.

### 5.10 Journal Entry

Every Standard or Full PARA pass ends with a journal entry containing:

- user request;
- simulated workflow;
- scale selected and why;
- obstacles found;
- fixes made;
- validation results;
- residual caveats;
- canonical commands after the audit.

Lite PARA may use a short note in the relevant PR, commit message, or journal.

---

## 6. Done Requirement

For medium and large projects, done requires a scale-appropriate PARA pass when the task creates or changes an operating workflow.

Minimum done additions:

- **Small:** name/runtime/dry-run checked.
- **Medium:** Standard PARA completed or explicitly scoped down with reason.
- **Large:** Full PARA completed, including end-to-end simulation, docs-chain update, stale-reference scan, and journal entry.

If PARA is skipped for a medium or large workflow, record an escape hatch with reason, risk, and follow-up owner.

---

## 7. Anti-Patterns

| Anti-pattern | Why it fails |
|---|---|
| Workflow is documented only in prose | Stateless agents cannot operate it reliably |
| Mutating recipe has no read-only verifier | Agent can reach side effects before discovering missing prerequisites |
| Phase-only script names | Agent cannot infer target or risk |
| Auth checked after mutation | Expired credentials create partial deployments |
| External resource creation left ambiguous | Agent may ask user to create resources that should be shared/namespaced |
| Runtime floats to future versions | Future agents inherit dependency or interpreter drift |
| Docs updated in only one place | Stale command paths mislead weaker agents |
| Audit produces findings but no script/doc fixes | Reasoning is spent but not encoded |

---

## 8. Quick Checklist

```text
PARA scale selected: Lite / Standard / Full
Future workflow simulated
Boundaries named
Manual steps converted or justified
Read-only verifier exists before mutator where needed
Names pass inferability test
Auth checked before mutation
External resources declared shared/per-instance
Runtime and dependencies controlled
Docs chain updated
Stale references scanned
Validation run
Journal/decision record written
```
