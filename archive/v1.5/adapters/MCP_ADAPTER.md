# MCP Adapter Contract

Use when the capability is exposed to an agent/model as a tool, resource, or prompt.

## First Decision: Tool, Resource, or Prompt

| Surface | Use for | Avoid |
|---|---|---|
| Tool | action, computation, external system interaction | raw backend dumping or hidden destructive effects |
| Resource | stable read-oriented inspectable context | mutation or workflow execution |
| Prompt | reusable instruction template selected by user/agent | hidden execution or side effects |

## Tool Must Define

- intent-shaped name
- one-line description with disambiguating hints
- typed input schema with constraints and defaults
- output schema / structured result where supported
- text fallback for host compatibility
- risk class and annotations
- read/write split
- dry-run support for mutation
- evidence and stable IDs
- conditional next-tool suggestions
- primitive escape hatches
- pagination/full-mode behavior

## Security Requirements

- Validate every tool input, resource URI, prompt argument, and adapter-generated downstream request.
- Do not pass through upstream tokens. Tokens used by an MCP server must be issued for that MCP server and validated for audience, issuer, expiry, and scope.
- Use progressive least privilege: expose read/discovery scopes first, request elevated scopes only when the operation needs them.
- Separate read, write, destructive, and open-world tools so consent and audit match the operation.
- Apply SSRF protections for any URL fetched from server, client, resource metadata, OAuth discovery, or tool input: prefer HTTPS, block private/link-local ranges unless explicitly allowed for development, and cap redirects.
- Treat local MCP servers as executable code. Show the exact startup command before first run, require explicit consent, and prefer sandboxed execution with restricted filesystem and network access.
- Never rely on session IDs for authentication. Bind sessions to authenticated identity where HTTP transports are used, rotate/expire sessions, and verify authorization on every request.
- Log mutation, elevation, and policy-block events with correlation IDs.

## Guardrails

- Do not mirror every backend endpoint.
- Do not combine read and write operations in one ambiguous tool.
- Do not use descriptions to override model/system behavior.
- Do not return megabytes of raw backend output.
- Prefer composites for repeated workflows, progressive discovery for large catalogs.
- Mark read-only, destructive, idempotent, and open-world behavior explicitly where host supports it.
