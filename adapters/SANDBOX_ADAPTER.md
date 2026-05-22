# Sandbox Adapter

Purpose: stage risky operations before commit.

## Applies to

- destructive local mutation;
- external mutation;
- generated code execution;
- shell/network access;
- bulk changes.

## Required features

```text
--dry-run     preview changes
--staged      apply into temp copy / transaction / branch
--commit      commit after explicit approval
--rollback    revert or discard staged state where practical
```

## Envelope additions

```json
{
  "approval": {
    "required": true,
    "approval_token": "",
    "staged_changes": []
  },
  "sandbox": {
    "filesystem_scope": "",
    "network_policy": "",
    "timeout_ms": 0,
    "secrets_injected": false
  }
}
```

## Hard rule

No raw secrets inherited into agent-written code. Use scoped clients or explicit temporary credentials only when policy allows it.
