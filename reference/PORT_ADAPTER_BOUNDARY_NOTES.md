# Port / Adapter Boundary Notes

This note exists because the boundary is simple in diagrams and messy in real projects. Use it when a component is being promoted, refactored, or reviewed.

## Core rule

The Core / Port layer owns invariant behavior. Adapters translate runtime details.

If the behavior must remain true when the CLI becomes an MCP server, the MCP server becomes a web API, or the worker becomes a scheduled job, it belongs in the Core / Port layer.

## Common blur cases

| Case | Usually belongs where | Reason |
|---|---|---|
| Input parsing from CLI flags | Adapter | Runtime format translation |
| JSON schema validation for tool payload | Adapter boundary | Blocks bad runtime payload before core |
| Domain validation such as “amount must be positive” | Core | Business invariant |
| Auth token extraction | Adapter | Runtime/request concern |
| Authorization decision such as “role may delete” | Core or policy port | Business/security rule |
| Dry-run diff calculation | Core | Mutation semantics must be stable |
| Human formatting | Adapter | Presentation concern |
| Result envelope assembly | Adapter with core evidence | Adapter shapes output, core supplies facts |
| Retry policy for external dependency | Rules/Config plus infrastructure adapter | Tunable operational policy |

## Post-port placement check

Mechanical ports often import the original project’s runtime shape. After the port works, ask:

1. Which functions contain reusable behavior?
2. Which functions only parse flags, environment, HTTP, MCP, or UI payloads?
3. Which constants are real domain constants and which are runtime defaults?
4. Which errors are domain errors and which are adapter errors?
5. Which tests should follow the core and which should stay with the adapter?

Move domain behavior into the Core / Port layer. Keep runtime translation in adapters.

## Refactoring heuristic

If a test can run without CLI, HTTP, MCP, UI, network, or shell setup, it probably tests the Core / Port layer. If a test exists mainly to prove serialization, flags, auth extraction, stdout, or status codes, it probably tests the Adapter.

## Acceptable shortcut

For Level 0 experiments, a single file may contain both core and adapter logic if it declares this shortcut in metadata. Promotion to Level 1 requires boundary separation or a recorded escape hatch.
