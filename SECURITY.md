# Security Policy

This repository defines governance rules for agent-operated systems. Report issues when a protocol rule could permit unsafe execution, credential exposure, unreviewed mutation, or misleading conformance claims.

## High-Risk Areas

- MCP token passthrough, SSRF, broad scopes, local server startup, and session misuse.
- Generic shell or code execution without sandboxing.
- Mutation paths without dry-run, idempotency, approval, and audit evidence.
- Schemas that weaken result envelope, metadata, or conformance requirements.
- Agent-specific instruction files that override shared doctrine.

## Handling

For private/internal use, open a private issue or contact the repository owner. Do not publish exploit details for active systems until affected components are remediated.
