# Frontend Design Editing Layer

Purpose: make future frontend design edits cheaper, faster, and easier to hand over by moving repeatable visual changes into deterministic project scripts and a small design-token config.

This note replaces the earlier long proposal. It is meant to be a compact implementation and handover brief for agents maintaining `arh-frontend-design-HLD`.

## Current State

Skill folder:

`D:\00_ARH\01_homelab\00_agent-hub\_skills\_arh-custom\arh-frontend-design-hld`

Relevant files already present:

- `SKILL.md`
- `scripts/init-artifact.sh`
- `scripts/design.config.json`
- `scripts/generate-tailwind-config.sh`
- `scripts/set-spacing-scale.sh`
- `scripts/generate-design-tokens.sh`
- `scripts/audit-accessibility.sh`
- `scripts/performance-budget.sh`
- `scripts/bundle-artifact.sh`
- `scripts/archive-project.sh`

The useful direction is already correct: centralize mutable design choices in `design.config.json`, regenerate Tailwind/CSS from that config, and expose small `set-*` scripts for routine edits.

The old draft had three problems:

- It mixed strategy, Q&A, and generated script bodies in one long document.
- It proposed scripts that were not actually present in the package.
- It included brittle shell patterns and examples that could overwrite user CSS too broadly.

## Design Goal

Future agents should avoid manually reading and editing multiple frontend files for common visual adjustments.

Preferred loop:

1. Inspect `design.config.json`.
2. Run or create a focused `scripts/set-*.sh` command.
3. Regenerate derived files through `scripts/generate-tailwind-config.sh`.
4. Run the smallest useful validation.
5. Leave a concise handover record with commands, files changed, and remaining risks.

This changes frontend iteration from "agent edits Tailwind, CSS, components, and context by hand" to "agent changes one token and validates generated output."

## Token Model

Use scripts for high-frequency, low-risk design edits:

- Font family
- Primary/accent color
- Default energy mode
- Spacing density
- Border radius
- Motion speed
- Shadow intensity
- Container width
- Focus ring style
- Breakpoint presets

Avoid scripts for one-off composition work:

- New page layout
- Component hierarchy changes
- Copy and IA changes
- Domain-specific states
- Custom animation choreography
- Accessibility fixes that depend on actual markup

## Canonical Config

`scripts/design.config.json` is the source of truth for routine visual tokens.

Current keys:

```json
{
  "designTokens": {
    "fontFamily": {
      "sans": ["Inter", "system-ui"],
      "serif": ["Georgia", "serif"],
      "mono": ["monospace"]
    },
    "primaryColor": "#2563EB",
    "energyDefault": "precise",
    "spacingScale": "comfortable",
    "borderRadius": "default",
    "motionSpeed": "normal",
    "shadowIntensity": "default",
    "containerMaxWidth": "standard",
    "focusRing": {
      "color": "#2563EB",
      "width": "2px",
      "offset": "2px"
    },
    "breakpoints": {
      "sm": "640px",
      "md": "768px",
      "lg": "1024px",
      "xl": "1280px",
      "2xl": "1536px"
    }
  }
}
```

Do not add a second spec file unless there is a real consumer for it. One config is cheaper to maintain and easier to hand over.

## Script Contract

Every design editing script should follow the same contract.

Location:

`scripts/set-<token>.sh`

Run location:

Generated project root, not the skill package root.

Required behavior:

- Accept a single focused value or preset.
- Validate allowed values before writing.
- Support `--dry-run`.
- Update `design.config.json` only.
- Call `scripts/generate-tailwind-config.sh` or `./scripts/generate-tailwind-config.sh` after mutation.
- Return compact JSON on stdout.
- Return errors as compact JSON on stdout or stderr and non-zero exit.

Result shape:

```json
{
  "status": "success",
  "changed": true,
  "summary": "Spacing scale set to compact",
  "evidence": ["design.config.json", "tailwind.config.js", "src/index.css"],
  "next_action_hint": "Run pnpm build or pnpm dev to preview"
}
```

Do not print long prose from scripts. The agent can summarize the JSON.

## Implementation Rules

Use structured tooling for JSON:

- Preferred: `node -e` because Node is already required for Vite projects.
- Acceptable: `jq` or `jaq` when available.
- Avoid: `sed` for JSON mutation except as a temporary fallback with a warning.

Use narrow generation:

- Prefer replacing marked generated blocks.
- Avoid overwriting the entire `src/index.css` if the generated project may contain user CSS.
- Use markers such as:

```css
/* design-config:start */
/* generated token variables */
/* design-config:end */
```

When updating existing scripts, move toward marker-based replacement instead of whole-file writes.

Backups:

- For generated project edits, write backups under `_history/` or `.design-history/`.
- Do not leave `.bak` files in the project root.
- Include backup paths in script JSON when a backup is created.

Portability:

- Existing package scripts are Bash scripts.
- On this ARH Windows workstation, run them through Git Bash or compatible shell.
- Do not introduce PowerShell-only project scripts unless the skill explicitly supports both.

## Script Backlog

Already present:

- `set-spacing-scale.sh`

Highest-value scripts to add next:

1. `set-font.sh`
   - Input: one or more font-family values.
   - Mutates: `designTokens.fontFamily.sans`.
   - Validation: reject empty values and shell control characters.

2. `set-primary-color.sh`
   - Input: hex color, e.g. `#2563EB`.
   - Mutates: `designTokens.primaryColor` and usually `designTokens.focusRing.color`.
   - Validation: `^#[0-9A-Fa-f]{6}$`.

3. `set-energy-default.sh`
   - Input: `warm|precise|playful|celebratory|urgent|reflective`.
   - Mutates: `designTokens.energyDefault`.

4. `set-border-radius.sh`
   - Input: `sharp|default|pill`.
   - Mutates: `designTokens.borderRadius`.

5. `set-motion-speed.sh`
   - Input: `slow|normal|fast`.
   - Mutates: `designTokens.motionSpeed`.

6. `set-shadow-intensity.sh`
   - Input: `subtle|default|prominent`.
   - Mutates: `designTokens.shadowIntensity`.

7. `set-container-width.sh`
   - Input: `narrow|standard|wide|full`.
   - Mutates: `designTokens.containerMaxWidth`.

8. `set-focus-ring.sh`
   - Input: color, width, offset.
   - Mutates: `designTokens.focusRing`.

9. `set-breakpoints.sh`
   - Input: preset name first; raw JSON only if needed.
   - Mutates: `designTokens.breakpoints`.

Prefer adding one generic helper over copying logic into every script.

Recommended helper:

`scripts/lib/design-config.sh`

Responsibilities:

- Find `design.config.json`.
- Validate required commands.
- Update JSON by path.
- Run generator.
- Emit JSON result.
- Create history backups.

This keeps each `set-*` script small.

## Generator Improvements

`scripts/generate-tailwind-config.sh` should become the only writer for derived design files.

Near-term fixes:

- Quote string arguments in generated `tailwind.config.js`.
- Ensure `getSpacing(...)`, `getBorderRadius(...)`, `getShadows(...)`, and `getAnimations(...)` receive string literals.
- Generate `screens` as valid JavaScript object syntax.
- Replace invalid CSS declarations such as `ring:` with real outline or box-shadow CSS.
- Do not assume `src/contexts/DesignEnergyContext.tsx` exists.
- If a target file is missing, report that in JSON instead of failing with an unhelpful shell error.

Preferred output files:

- `tailwind.config.js`
- marked block inside `src/index.css`
- optional generated file such as `src/design/generated-tokens.css`
- optional generated file such as `src/design/design-runtime.ts`

The generator should not edit application components.

## Init Integration

`scripts/init-artifact.sh` should install the editing layer into every generated project.

Minimum behavior:

- Copy `design.config.json`.
- Copy `generate-tailwind-config.sh`.
- Copy all available `set-*.sh` scripts.
- Copy any helper files under `scripts/lib/`.
- Mark scripts executable.
- Run initial generation once.
- Add package scripts for common commands.

Suggested `package.json` scripts:

```json
{
  "design:apply": "bash scripts/generate-tailwind-config.sh",
  "design:spacing": "bash scripts/set-spacing-scale.sh",
  "design:font": "bash scripts/set-font.sh",
  "design:color": "bash scripts/set-primary-color.sh",
  "design:energy": "bash scripts/set-energy-default.sh"
}
```

Do not advertise scripts that are not copied into the generated project.

## Agent Workflow

When a user asks for a routine visual edit in a generated frontend project:

1. Check whether `design.config.json` exists.
2. Check whether a matching `scripts/set-*.sh` exists.
3. If it exists, run it with `--dry-run`, then run it for real.
4. Validate with the cheapest relevant command:
   - config-only change: `pnpm build`
   - visual/responsive change: `pnpm build` plus screenshot check if server is available
   - accessibility-related change: `scripts/audit-accessibility.sh`
5. Report the script JSON summary, validation result, and any files touched.

When the script does not exist:

1. Add the missing script to the skill package first if it is generally reusable.
2. Add it to `init-artifact.sh`.
3. Smoke-test script syntax.
4. Use the script rather than doing a one-off edit.

Only do manual frontend edits when the requested change is not token/config driven.

## Handover Template

Use this compact handover block after frontend design-editing work:

```md
## Frontend Design Edit Handover

Project:
Request:
Token/config changed:
Commands run:
Files changed:
Validation:
Screenshots/artifacts:
Known risks:
Next suggested script:
```

Example:

```md
## Frontend Design Edit Handover

Project: apps/demo-dashboard
Request: make the interface more compact
Token/config changed: designTokens.spacingScale = compact
Commands run:
- bash scripts/set-spacing-scale.sh compact
- pnpm build
Files changed:
- design.config.json
- tailwind.config.js
- src/index.css
Validation: build passed
Screenshots/artifacts: not captured
Known risks: visual density not reviewed on mobile
Next suggested script: set-border-radius.sh
```

## Maintenance Checklist

Before calling the editing layer ready:

- `bash -n scripts/*.sh` passes.
- `design.config.json` is valid JSON.
- `generate-tailwind-config.sh --dry-run` returns JSON.
- `set-spacing-scale.sh compact --dry-run` returns JSON.
- A disposable generated project can run `scripts/init-artifact.sh <name>`.
- Generated project can run `pnpm build`.
- `SKILL.md` script list matches actual files.

## Decision

Keep the light base/config/script model.

Do not adopt heavier machinery for this skill:

- No LSP adapter.
- No MCP worker.
- No OpenTelemetry.
- No SBOM workflow.
- No separate design spec until another tool needs it.

The next practical improvement is to harden `generate-tailwind-config.sh`, then add `scripts/lib/design-config.sh`, then implement the remaining high-frequency `set-*` scripts one by one.
