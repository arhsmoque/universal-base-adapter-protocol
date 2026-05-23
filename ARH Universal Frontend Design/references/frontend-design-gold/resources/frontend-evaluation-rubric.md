# Frontend Evaluation Rubric

Use this file when a task requires a deeper design audit, redesign plan, or acceptance checklist.

## Scoring lens

Rate each area as Pass / Risk / Fail.

### 1. Situation fit

- Does the interface match the audience, emotional tone, domain, and use environment?
- Is the dominant archetype clear?
- Is the primary action obvious within 3 seconds?
- Does the design match the failure cost?

### 2. Information architecture

- Are navigation, grouping, and order aligned with user intent?
- Is hierarchy visible without reading every label?
- Are progressive disclosure and density used appropriately?

### 3. Visual design

- Typography supports mood and readability.
- Color supports meaning and contrast.
- Spacing, scale, balance, contrast, and grouping guide attention.
- Visual style belongs to the content rather than a generic trend.

### 4. Interaction design

- Controls look and behave like controls.
- Feedback is immediate and useful.
- Destructive, irreversible, or high-stakes actions include appropriate confirmation/recovery.
- Flow minimizes redundant work.
- Edge cases do not strand users.

### 5. Accessibility

- Keyboard complete.
- Focus visible and not obscured.
- Text and non-text contrast pass.
- Labels, names, roles, and values are meaningful.
- Form errors are discoverable and associated.
- Drag/drop has alternatives.
- Hover-only interaction avoided.
- Reduced motion supported.

### 6. Responsiveness

- Mobile, tablet, desktop, and large display behavior are intentional.
- Touch targets are comfortable.
- Content reflows without clipping or horizontal scroll except for intentional data tables.
- Primary actions remain reachable.

### 7. Performance

- LCP, INP, and CLS are protected by design choices.
- Media is optimized.
- Layout space is reserved.
- Initial screen is not overloaded.
- Animations and scripts do not block input.

### 8. State coverage

Check: empty, loading, partial, success, error, validation, offline, permission, unauthenticated, retry, rate-limited, saving/uploading, read-only, disabled, destructive confirmation, completed/archive.

### 9. Design-system health

- Tokens separate raw values from semantic meaning.
- Components document variants and states.
- New patterns do not duplicate existing system primitives.
- Accessibility behavior is part of the component contract.

## Severity guide

- **Blocker**: prevents task completion, violates accessibility fundamentals, risks data loss, or creates legal/safety exposure.
- **High**: causes likely confusion, trust loss, repeated errors, or material performance harm.
- **Medium**: weakens clarity, speed, consistency, or resilience.
- **Low**: polish, consistency, or maintainability issue with limited user impact.
