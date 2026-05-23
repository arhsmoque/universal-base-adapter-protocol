# Sandbox Adapter

Sandbox adapters isolate generated code, shell execution, network access, and broad filesystem operations. Required for risk class `open_world` and any component with the `generated_code_execution` modifier.

---

## 1. When a sandbox is required

| Trigger | Reason |
|---------|--------|
| `risk_class: open_world` | Arbitrary shell, eval, or generated code execution |
| `risk_modifier: generated_code_execution` | Agent-produced code running at runtime |
| `risk_modifier: filesystem_broad_scope` | Writes outside declared paths |
| `risk_modifier: network_access` when input is agent-supplied | SSRF and injection risk |
| Untrusted input reaches subprocess or eval | Any surface |

---

## 2. Required sandbox controls

All of the following must be present before the sandbox is classified as `risk_class: open_world` at any conformance level:

| Control | Requirement |
|---------|-------------|
| **Timeout** | Hard wall-clock limit enforced at the OS/container level, not only inside the process |
| **Allowlist** | Explicit list of permitted syscalls, network destinations, or filesystem paths; default-deny |
| **Secret isolation** | No inherited secrets, credentials, or tokens from parent process environment |
| **Scoped writable directory** | Writes only within a declared temp directory; no writes to repo, config, or host paths |
| **Audit record** | Structured log of every execution: input hash, command, start time, duration, exit code, stdout digest |
| **Resource limits** | CPU and memory caps (ulimit, cgroup, or equivalent) |

---

## 3. Boundary: what belongs where

| Concern | Belongs in |
|---------|-----------|
| Sandbox setup (namespace, cgroup, temp dir) | Adapter |
| Allowlist configuration | Rules / Config |
| Timeout value | Rules / Config |
| Execution of generated code | Adapter (sandboxed) |
| Audit record writing | Adapter |
| Interpretation of execution result | Core |
| Safety decision ("should this code run?") | Core |

---

## 4. Anti-patterns

**Shell passthrough without isolation**

```python
# WRONG — untrusted input reaches shell directly
subprocess.run(f"bash -c '{user_input}'", shell=True)
```

Fix: never use `shell=True` with external input. Pass arguments as a list. Apply sandbox controls before any exec.

**Inherited secrets in sandboxed process**

```python
# WRONG — full parent environment passed in
subprocess.run(cmd, env=os.environ)
```

Fix: construct a minimal environment for the sandboxed process. Explicitly list only the env vars it needs. Default to an empty environment plus `PATH`.

---

## 5. Execution result shape

The sandbox adapter returns a standard result envelope. The core interprets the execution result, not the adapter:

```json
{
  "status": "success | failure | blocked",
  "data": {
    "exit_code": 0,
    "stdout_digest": "sha256:...",
    "stderr_lines": 0,
    "resource_usage": { "wall_ms": 142, "cpu_ms": 98, "memory_kb": 4096 }
  },
  "trace_id": "sandbox_exec_abc123",
  "evidence": [
    { "type": "audit_record", "path": "sandbox/audit/abc123.jsonl" }
  ],
  "errors": []
}
```

Raw stdout from the sandboxed process is never returned directly. The core parses it and selects what belongs in `data`.

---

## 6. Replay and verification

Every sandbox execution must be replayable from its audit record. The audit record must contain enough information for a later agent to reproduce the execution (input hash, command, environment summary, resource limits) without re-running untrusted code.
