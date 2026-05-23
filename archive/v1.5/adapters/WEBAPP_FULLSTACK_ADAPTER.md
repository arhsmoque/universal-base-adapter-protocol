# Webapp / Full-Stack Adapter Contract

Use when the capability is exposed through pages, components, HTTP APIs, server actions, or full-stack flows.

## Required Boundary

```text
UI event / HTTP request -> web adapter -> application service/base -> persistence ports -> result envelope -> UI/API response
```

## Must Define

- route/page/component boundary
- server/client split
- shared input/output schema
- form validation and error mapping
- loading, empty, and failure states
- auth/session mapping
- authorization boundary
- transaction boundary
- persistence adapter
- cache and invalidation policy
- background job boundary if needed
- accessibility requirements
- smoke and failure tests

## Guardrails

- Components must not own base business rules.
- API handlers must not leak internal DB models directly.
- Use typed contracts between frontend and backend.
- Mutations need preview, confirmation, or undo when risk demands.
- Keep UI copy in the adapter; keep invariant behavior in the base.
