# Worker / Automation Adapter Contract

Use when the capability runs on schedules, queues, events, long-running jobs, or recurring automation.

## Required Boundary

```text
trigger -> worker adapter -> base operation -> ports -> event log/artifacts -> close/suspend state
```

## Must Define

- trigger source and schedule/event contract
- idempotency key
- retry/backoff policy
- timeout and cancellation behavior
- queue/topic contract
- concurrency limits
- event log and artifact paths
- dead-letter or blocked-state behavior
- continuation packet for incomplete work
- cleanup and retention policy

## Guardrails

- Repeated execution must be safe.
- Writes require idempotency or duplicate detection.
- Long work needs resumable state, not hidden background assumptions.
- Secrets must be scoped and redacted from logs.
