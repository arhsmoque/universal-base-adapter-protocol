# CLI Adapter Contract

Use when the capability must run from a shell, script, task runner, CI job, or human terminal.

## Required Boundary

```text
CLI args/stdin/env -> CLI adapter -> base command -> result envelope -> stdout/stderr/exit code
```

The CLI adapter maps shell input to the base. It must not own domain rules.

## Must Define

- command names and subcommands
- flags and defaults
- JSON output mode
- human output mode if needed
- exit code table
- stdin/stdout/stderr behavior
- config discovery order
- shell/platform support
- examples and smoke tests
- cleanup behavior for generated files

## Exit Code Guidance

| Code | Meaning |
|---:|---|
| 0 | success |
| 1 | expected user/input failure |
| 2 | policy or permission block |
| 3 | partial success |
| 10+ | internal/runtime failure |

## Guardrails

- Prefer `--json` for agent use.
- Do not require interactive prompts for agent paths.
- Return parseable errors with recovery hints.
- Write large outputs to artifact paths and return references.
- Keep shell-specific quirks in adapter tests, not base tests.
