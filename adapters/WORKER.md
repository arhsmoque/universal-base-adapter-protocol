# Worker Adapter Contract

Worker adapters run asynchronous, scheduled, or batch jobs. The adapter owns scheduling, trigger, retry configuration, and delivery guarantees. The core owns processing logic and completion criteria.

---

## 1. Boundary: what belongs where

| Concern | Belongs in | Reason |
|---------|-----------|--------|
| Job trigger (cron, queue, event) | Adapter | Scheduling surface |
| Retry policy and backoff | Rules / Config | Tunable operational policy |
| Batch chunk sizing | Adapter | Infrastructure concern |
| Delivery guarantee (at-least-once, exactly-once) | Adapter + idempotency key | Adapter provides key; core enforces idempotency |
| Processing logic | Core | Must be consistent regardless of trigger |
| Completion criteria ("done when all rows processed") | Core | Business invariant |
| Failure classification (transient vs fatal) | Core error taxonomy | Must be consistent |
| Output routing | Adapter | Surface concern |

**Red flag:** if the job handler contains branching business logic that cannot be unit-tested without a scheduler, logic has leaked into the adapter.

---

## 2. Required controls

Every worker job must have all of the following:

| Control | Requirement |
|---------|-------------|
| Idempotency key | Required on every job invocation; core uses it to detect and skip duplicates |
| Completion artifact | A structured record (file, database row, or queue message) proving the job completed — not just "job submitted" |
| Event log | Structured entries for job start, progress milestones, completion, and any failure |
| Failure artifact | On failure: input snapshot, config snapshot, environment summary, error with class and message |
| Replay command | A documented command or path to re-run the job from its recorded input |

---

## 3. Output and event format

Job completion emits a `result-envelope.json`-compatible record:

```json
{
  "status": "success | partial_success | failure | budget_exceeded",
  "data": { "processed": 0, "skipped": 0, "failed": 0 },
  "message": "short summary",
  "trace_id": "job_abc123",
  "duration_ms": 0,
  "idempotency_key": "run_20260523_v1",
  "affected_items": [],
  "reversible": false,
  "verification": "command or assertion to confirm output is correct",
  "errors": []
}
```

Progress events go to a structured event log (`events.jsonl` or equivalent), not interleaved with the completion record.

---

## 4. Anti-patterns

**Fire-and-forget with no completion proof**

```python
# WRONG — job is "done" when submitted, not when processed
queue.send(job_payload)
return {"status": "queued"}
```

Fix: the completion artifact (written by the job itself after processing) is the proof. Callers check for the artifact, not the queue acknowledgement.

**Untracked side effects in batch processing**

```python
# WRONG — some rows silently fail with no record
for row in batch:
    try:
        process(row)
    except:
        pass   # swallowed
```

Fix: every item in a batch that fails must appear in `errors[]` with its ID and failure class. `status: partial_success` when some items succeeded and some failed.

---

## 5. Minimal compliant job skeleton

```python
# worker_adapter.py (pseudo-structure)

def run_job(job: Job):
    trace_id = f"job_{job.id}"
    log_event(trace_id, "start", {"input_count": len(job.items)})

    # Adapter: extract and pass idempotency key
    port_input = {
        "items": job.items,
        "idempotency_key": job.idempotency_key,
        "budget": job.budget
    }

    # Core call
    result = core_port.process_batch(port_input)

    # Adapter: write completion artifact
    write_completion_record(trace_id, result)
    log_event(trace_id, "complete", result)

    return result
```

---

## 6. Budget and continuation

Workers that process large datasets must accept a budget (row count, time limit, or cost cap). When the budget is reached before processing is complete:
- Return `status: budget_exceeded` with a `continuation_token`.
- Write the partial completion artifact with `"partial": true`.
- The next job invocation resumes from the continuation token, not from scratch.
