 # Frontend Design HLD: Context-Adaptive Interface Direction

  ## 1. Skill Identity

  Name: frontend-design

  Purpose:
  Create interfaces that feel inevitable for their subject, audience, and setting. The agent must behave like a product-minded visual designer: first understanding the human situation,
  then translating that into layout, color, type, motion, density, and interaction.

  The goal is not “pretty UI.”
  The goal is appropriate, memorable, usable, production-grade interface design.

  ## 2. Core Principle

  Design is translation.

  Translate:

  - content → structure
  - audience → clarity
  - emotional energy → tone
  - task urgency → interaction speed
  - cultural setting → visual restraint or expressiveness
  - device context → density, reachability, and performance
  - brand/person/event → typography, color, imagery, and rhythm

  Never start from a visual trend.
  Start from the situation.

  ## 3. Mandatory Intent Discovery

  Before choosing any aesthetic, identify:

  - Content type: memory book, dashboard, game, legal report, portfolio, tool, lesson, commerce, etc.
  - Human context: private/public, emotional/practical, casual/formal, high-stakes/low-stakes.
  - Audience: age, tech comfort, attention span, accessibility needs, cultural expectations.
  - Use environment: mobile/desktop, noisy event, office, classroom, low bandwidth, one-time use, repeated workflow.
  - Primary action: what must be obvious within 3 seconds.
  - Emotional energy: warm, solemn, playful, premium, urgent, calm, precise, celebratory, rebellious, editorial.
  - Failure cost: embarrassment, lost data, confusion, wasted time, financial risk, safety risk.

  The interface must be designed from these answers.

  ## 4. Aesthetic Matching Rules

  Do not default to dark mode, light mode, cards, gradients, dashboards, glassmorphism, or “modern SaaS.”

  Choose based on context:

  - Warm human memory → soft light, editorial spacing, tactile surfaces, gentle contrast.
  - Technical control surface → high clarity, dense layout, strong hierarchy, quiet color.
  - Playful game/tool → expressive color, responsive motion, strong affordances.
  - Serious document/report → restrained palette, readable type, calm structure.
  - Luxury/editorial → disciplined whitespace, high-quality typography, low-noise details.
  - High-volume operational app → compact, scannable, predictable, low decoration.

  ## 5. Energy Translation

  Energy must become visible decisions:

  - Warm/intimate: soft neutrals, natural contrast, human copy, serif or warm sans, subtle texture.
  - Precise/professional: restrained neutrals, clear grid, minimal ornament, strong labels.
  - Celebratory: richer accents, generous rhythm, expressive media, but not at the cost of usability.
  - Urgent/action-heavy: bold affordances, fewer choices, strong status feedback.
  - Reflective/storytelling: slower rhythm, larger media, calmer motion, editorial hierarchy.
  - Playful: bolder shapes, color, motion, but with clear task boundaries.

  ## 6. Typography

  Do not blindly default to Inter, Arial, or system fonts.
  Do not blindly reject them either.

  Choose type intentionally:

  - display type should carry mood
  - body type must remain readable under real conditions
  - use limited type scales
  - support large text settings
  - avoid decorative fonts for critical actions
  - preserve hierarchy through size, weight, spacing, and placement

  Typography is not decoration. It is voice, hierarchy, and pacing.

  ## 7. Color

  Color must serve meaning, mood, and accessibility.

  Rules:

  - derive palette from subject and energy
  - avoid generic purple/blue AI gradients unless justified
  - maintain readable contrast
  - never communicate state through color alone
  - use accent color for action or meaning, not random emphasis
  - test light/dark decisions against actual use environment

  ## 8. Layout And Composition

  Choose layout based on behavior:

  - timeline for chronological social memory
  - grid for browsable collections
  - single-column for focused mobile tasks
  - dashboard only for data/control systems
  - editorial layout for storytelling
  - dense tables only for comparison/operations

  Cards are allowed when they represent real repeated objects: posts, products, messages, records.
  Avoid decorative card soup.

  Use scale, hierarchy, balance, contrast, and grouping deliberately.

  ## 9. Signature Detail

  Every design should have one signature interaction or detail that belongs to the content.

  It must help the experience, not decorate it.

  Examples:

  - wedding timeline: live memory pulse, elegant post arrival, monogram stamp, projector transition
  - document app: precise annotation margin
  - music app: waveform-based navigation
  - education app: progress map tied to learning journey

  If the detail can be removed without changing the experience, it is probably decoration.

  ## 10. Motion

  Motion must explain, confirm, or focus.

  Use motion for:

  - upload progress
  - post arrival
  - state transition
  - focus movement
  - error recovery
  - slideshow continuity

  Avoid:

  - motion that delays tasks
  - decorative floating elements
  - autoplay distractions
  - flashing
  - motion that ignores reduced-motion preferences

  ## 11. Accessibility Floor

  Every design must satisfy baseline accessibility:

  - readable contrast
  - visible focus states
  - meaningful labels for icon buttons
  - touch targets sized for real fingers
  - keyboard-reachable actions
  - scalable text without overlap
  - reduced-motion support
  - errors described in text, not color only
  - important media/actions not hidden behind hover

  Accessibility is part of taste.

  ## 12. Performance Floor

  Design must respect the device and network:

  - lazy-load media
  - avoid autoplay video
  - compress images
  - show placeholders and progress
  - keep first screen lightweight
  - avoid layout shift
  - handle slow network gracefully
  - preserve user input after errors

  A beautiful interface that fails under real use is not finished.

  ## 13. State Design

  Production UI must design every meaningful state:

  - empty
  - loading
  - uploading
  - success
  - failed upload
  - retry
  - offline/poor network
  - locked/read-only
  - permission denied
  - invalid input
  - rate limited
  - completed/final archive

  States should feel like part of the product, not error leftovers.

  ## 14. Anti-Patterns

  Hard avoid:

  - dark neon dashboard for warm human content
  - generic gradient hero without subject relevance
  - decorative glassmorphism by default
  - purple/blue “AI app” palette by habit
  - oversized cards for every section
  - hidden primary action
  - tiny controls on mobile
  - ignoring audience age or context
  - visual polish that slows the main task
  - styling before understanding intent

  ## 15. Required Design Rationale

  Every implementation should include a short rationale:

  /* Vibe: [context + audience + energy]
     Translation: [palette, type, layout, motion, interaction choices]
     Constraints: [accessibility, performance, device/context risks]
  */

  For Ash2026:

  /* Vibe: private wedding social timeline for mixed-age guests at a live event.
     Translation: warm editorial memory-book surface, familiar social post layout,
     clear camera/gallery actions, soft wedding accents, no generic dashboard.
     Constraints: mobile-first, large tap targets, no autoplay video, compressed media,
     clear upload states, readable in crowded event conditions. */

  ## Sources Used

  - NN/g visual design principles: https://media.nngroup.com/media/articles/attachments/Principles_Visual_Design-Letter.pdf
  - Material Design principles: https://m1.material.io/
  - Material accessibility guidance: https://m1.material.io/usability/accessibility.html
  - W3C WCAG 2.2: https://www.w3.org/TR/WCAG22/
  - Apple typography guidance: https://developer.apple.com/design/human-interface-guidelines/typography