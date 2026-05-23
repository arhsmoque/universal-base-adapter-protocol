---
name: frontend-design-gold
description: Apply context-adaptive frontend design direction for UI creation, review, redesign, and implementation with accessibility, performance, and state coverage.
---

# Frontend Design Gold

Use this skill when designing, reviewing, redesigning, or implementing frontend interfaces: pages, components, flows, dashboards, marketing surfaces, tools, prototypes, and design-system decisions.

## Core stance

Design is translation.

Translate the situation into structure, hierarchy, interaction, tone, and implementation constraints. Do not begin from a trend, component library, color palette, dark mode, card layout, glassmorphism, or generic SaaS aesthetic.

The goal is not "pretty UI." The goal is appropriate, usable, memorable, resilient interface design that fits the audience, task, content, platform, and failure cost.

## First response behavior

Before giving direction or code, silently classify the task:

- **Direction request**: produce design strategy, rationale, and a clear implementation path.
- **Review request**: identify what works, what fails, severity, and specific fixes.
- **Implementation request**: design through code while preserving the user's stack and constraints.
- **Refactor request**: improve the existing UI without needless rewrites.
- **Ambiguous request**: make reasonable assumptions, state them briefly, and proceed.

Ask a follow-up only when the missing information would materially change the design and cannot be safely assumed. Otherwise, proceed with stated assumptions.

## Adaptive design kernel

For every meaningful frontend task, derive the design from this chain:

### 1. Situation scan

Identify:

- Content type: product, report, form, dashboard, feed, commerce, story, portfolio, lesson, tool, game, event, legal/financial, internal ops.
- Human context: private/public, emotional/practical, casual/formal, high-stakes/low-stakes, one-time/repeated use.
- Audience: age range, technical comfort, domain familiarity, accessibility needs, language/cultural expectations.
- Environment: mobile/desktop/tablet, noisy event, office, classroom, field work, low bandwidth, projected display, touch/keyboard/mouse.
- Primary action: what must be obvious within 3 seconds.
- Failure cost: confusion, embarrassment, lost data, financial risk, safety risk, reputation damage.
- Emotional energy: calm, warm, solemn, urgent, playful, premium, rebellious, precise, celebratory, editorial.
- Data reality: static/dynamic, real-time/batch, sparse/dense, trusted/untrusted, sensitive/public.

### 2. Archetype selection

Choose the dominant interface archetype before choosing visuals:

- **Task tool**: speed, predictability, clear affordances, short feedback loops.
- **Operational console**: density, scanability, status hierarchy, low ornament.
- **Narrative/editorial**: pacing, typography, rhythm, imagery, guided attention.
- **Commerce/choice**: comparison, confidence, filters, trust cues, low-friction checkout.
- **Social/feed**: familiarity, contribution flow, moderation, empty and loading states.
- **Learning/onboarding**: progressive disclosure, visible progress, recovery paths.
- **Legal/reporting**: readability, traceability, restrained tone, export/print readiness.
- **Showcase/portfolio**: strong first impression, media quality, story and credibility.
- **Game/interactive**: feedback, rules clarity, playful motion, state persistence.

If several archetypes apply, name the primary and secondary tension, then resolve the tradeoff.

### 3. Translate into design primitives

Make visible decisions across:

- Information architecture and navigation.
- Layout and composition.
- Typography and reading rhythm.
- Color, contrast, and semantic state mapping.
- Component choice and interaction model.
- Motion and transition behavior.
- Media treatment and image handling.
- Forms, validation, and recovery.
- Data visualization and table density.
- Responsive behavior and input modality.
- Copy tone, labels, and microcopy.
- Design tokens and theming.

## Visual direction rules

### Typography

Typography is voice, hierarchy, and pacing. Choose type intentionally.

- Body text must be readable under the actual use condition.
- Display type may carry mood, but never at the cost of comprehension.
- Use a limited scale and consistent spacing rhythm.
- Preserve hierarchy through size, weight, spacing, placement, and contrast.
- Avoid decorative fonts for critical actions, numbers, labels, forms, and safety messages.
- Support text resizing without overlap or clipped controls.

### Color

Color must serve meaning, mood, and accessibility.

- Derive palette from subject, brand, context, and emotional energy.
- Avoid generic purple/blue AI gradients unless the context justifies them.
- Never communicate state through color alone.
- Use accent color for action or semantic meaning, not random decoration.
- Verify contrast for text, icons, focus indicators, charts, and disabled states.
- Treat light/dark mode as contextual, not automatically "modern."

### Layout and composition

Choose layout based on behavior:

- Timeline for chronological memory, activity, events, or audit history.
- Grid for browsable collections.
- Single-column for focused mobile tasks.
- Dashboard only for monitoring or control systems.
- Editorial layout for storytelling and reports.
- Dense table only for comparison, operations, or expert workflows.
- Wizard/stepper only when sequencing reduces cognitive load.

Cards are valid when they represent real repeated objects: records, posts, messages, products, tasks, people, files. Avoid decorative card soup.

Use scale, hierarchy, balance, contrast, proximity, alignment, and grouping deliberately.

### Signature detail

Every design may have one signature detail that belongs to the product's content or behavior. It must improve orientation, emotion, or task success.

Examples:

- Wedding memory wall: live post arrival with a soft memory-book rhythm.
- Document review tool: precise annotation margin.
- Music tool: waveform navigation.
- Learning app: progress map tied to the learning journey.
- Ops tool: status pulse that distinguishes stale, live, and degraded systems.

If removing the detail does not change the experience, it is decoration.

### Motion

Motion must explain, confirm, focus, or preserve continuity.

Use motion for loading, upload progress, state transitions, focus movement, error recovery, and continuity between related views. Avoid motion that delays work, distracts from content, flashes, traps attention, or ignores reduced-motion preferences.

## Production floor

A design is not complete until these are covered.

### Accessibility floor

Aim for WCAG 2.2 AA as the default floor.

- Use semantic HTML before custom ARIA.
- Keyboard users must be able to reach, operate, and understand every interactive element.
- Focus indicators must be visible and not obscured by sticky headers, modals, or overlays.
- Touch targets should be comfortable on mobile; never rely on tiny precision targets.
- Provide non-drag alternatives for drag/drop and reordering.
- Avoid redundant data entry across multi-step flows.
- Authentication must not depend on memory puzzles or inaccessible interactions.
- Form errors must be described in text and programmatically associated with fields.
- Icon-only controls need accessible names.
- Hover-only content must also work by focus and touch.
- Do not hide important actions behind hover.
- Respect reduced motion.
- Test with keyboard, screen-reader basics, zoom, high contrast, and mobile touch.

Use WAI-ARIA Authoring Practices only when native HTML is insufficient. Match the expected keyboard interaction pattern for widgets such as dialogs, tabs, menus, accordions, comboboxes, grids, and sliders.

### Performance floor

Use Core Web Vitals as experience constraints:

- Loading performance: protect LCP.
- Interaction responsiveness: protect INP.
- Visual stability: protect CLS.

Design choices must support performance:

- Compress and size media.
- Lazy-load below-the-fold media.
- Avoid unnecessary autoplay video and heavy background effects.
- Reserve layout space for media and async content.
- Show skeletons/placeholders only when they reduce perceived uncertainty.
- Keep first screen lightweight.
- Avoid hydration, animation, and analytics work that blocks input.
- Preserve user input after errors, refreshes, and retries.
- Design graceful behavior for slow network and offline/poor connection.

### State floor

Every meaningful UI must cover:

- Empty.
- Loading.
- Partial loading.
- Success.
- Error.
- Validation error.
- Permission denied.
- Unauthenticated.
- Offline/poor network.
- Uploading/saving.
- Retry.
- Rate limited.
- Read-only/locked.
- Disabled but explainable.
- Completed/archive.
- Destructive confirmation and recovery where possible.

States should feel like part of the product, not leftover error screens.

### Responsiveness and input floor

- Design for at least mobile, tablet, desktop, and large display behavior where relevant.
- Prefer fluid layout, sensible max widths, and container-aware components.
- Treat touch, keyboard, mouse, trackpad, and screen-reader navigation as first-class.
- Keep primary action reachable and visible in the dominant device context.
- Do not assume hover exists.
- Do not assume pointer precision.
- Preserve orientation, scroll position, and task progress across breakpoints.

### Design-system floor

When implementing or extending a system:

- Use tokens for color, typography, spacing, radius, shadow, motion, and z-index.
- Separate semantic tokens from raw values.
- Name tokens by purpose, not appearance, when they encode product meaning.
- Keep component APIs small, stateful, and accessible.
- Document variants, states, constraints, and usage guidance.
- Include examples for empty/loading/error/disabled/focus states.
- Prefer stable, inspectable primitives over dependency-heavy novelty.
- Avoid overriding design-system components into inaccessible custom behavior.
- If adopting a formal design-token exchange format, verify the current Design Tokens Community Group status before claiming strict conformance.

## Design-energy translation

Use these as starting points, not presets:

- **Warm/intimate**: soft neutrals, natural contrast, human copy, tactile surfaces, gentle rhythm.
- **Precise/professional**: restrained palette, strong labels, clear grid, low ornament, predictable interactions.
- **Celebratory**: richer accents, generous rhythm, expressive media, controlled delight.
- **Urgent/action-heavy**: bold affordances, fewer choices, persistent status, fast recovery.
- **Reflective/storytelling**: slower rhythm, larger media, calm motion, editorial hierarchy.
- **Playful**: bolder shapes, color, and feedback, while preserving task boundaries.
- **Premium/luxury**: disciplined whitespace, high-quality media, quiet interaction, careful type.
- **Operational**: dense but readable, status-first, compact controls, no decorative friction.

## Anti-patterns

Hard avoid:

- Styling before understanding intent.
- Dark neon dashboards for warm human content.
- Generic gradient hero sections without subject relevance.
- Decorative glassmorphism by default.
- Purple/blue "AI app" palette by habit.
- Oversized card stacks for every section.
- Hiding the primary action.
- Tiny controls on mobile.
- Hover-only critical actions.
- Motion that blocks task progress.
- Visual polish that worsens performance.
- Recreating native controls badly.
- Ignoring keyboard, zoom, contrast, and reduced motion.
- Beautiful empty states that do not tell users what to do next.
- Treating accessibility as post-polish.
- Treating responsiveness as "stack everything vertically."

## Output contract

Match output to the user's need.

### If asked for design direction

Return:

1. **Read of the situation**: archetype, audience, energy, constraints, failure cost.
2. **Design direction**: layout, type, color, interaction, motion, density, media.
3. **Production guardrails**: accessibility, performance, states, responsive behavior.
4. **Rationale**: why this fits.
5. **Next implementation steps**: concise and actionable.

### If asked for review

Return:

- Verdict.
- What works.
- Highest-risk problems first.
- Specific fixes by area: hierarchy, layout, interaction, accessibility, performance, states, responsiveness.
- Optional severity labels: blocker, high, medium, low.
- Do not only critique taste; tie every issue to user impact.

### If asked for implementation

- Preserve the user's stack unless a change is required.
- Prefer semantic HTML and accessible primitives.
- Implement visible focus states, reduced-motion behavior, and all important states.
- Keep dependency additions justified.
- Include a short rationale comment near the page/component root when useful:

```tsx
/*
Vibe: [context + audience + energy]
Translation: [layout, type, color, motion, interaction choices]
Constraints: [accessibility, performance, device/context risks]
*/
```

### If asked for a compact decision

Return a concise verdict and the deciding rationale. Do not force a long template when the user only needs direction.

## Quality bar

A gold-standard frontend answer should make the interface feel inevitable for the situation. It should explain why the design direction fits, expose tradeoffs, avoid trend defaults, and leave the user with concrete next actions or implementable code.

For deeper audit rubrics and source anchors, see:

- `resources/frontend-evaluation-rubric.md`
- `resources/reference-anchors.md`
