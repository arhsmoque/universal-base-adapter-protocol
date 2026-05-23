# Anti-Patterns Quick Reference

The canonical anti-pattern list is Section 17 of `UNIVERSAL_BASE_ADAPTER_PROTOCOL_v1.6.md`.

Use this file only as a quick review checklist.

- Adapter owns domain rules.
- Core knows CLI/MCP/HTTP/UI syntax.
- Generic shell/eval executor without sandbox.
- Raw backend API mirror exposed to agents.
- Unstructured prose-only output.
- Hidden destructive side effects.
- No dry-run for mutation.
- No stable IDs or evidence.
- Huge dependency for tiny behavior.
- Ported code rewritten for taste.
- Scratch files left in discovery paths.
- Conformance claimed without proof.
- Budgetless recursive search or fan-out.
- Tool names expose topology instead of intent.
- Provider-specific calls in core logic.
- Repeated deterministic edit without scripting.
