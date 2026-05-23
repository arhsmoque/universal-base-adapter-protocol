# arh-skill-qa — Agent Handbook

## What This Tool Does

`arh-skill-qa` is the ARH skill quality gate. Use it after creating or updating
a `SKILL.md` folder so another agent can immediately see whether the skill is
importable, lean, actionable, and wired to its bundled resources.

## Commands

```powershell
# Check one skill
arh-skill-qa check path\to\skill --json

# Check every direct child skill under a root
arh-skill-qa check-all D:\00_ARH\01_homelab\00_agent-hub\_skills\_arh-custom --json

# Emit only a repair-oriented plan
arh-skill-qa amend-plan path\to\skill --json

# Build a compact skill registry
arh-skill-qa registry build --skills-root path\to\skills --output skill-registry.json
```

## Interpreting Output

- `status=ok`: no blocking or warning findings.
- `status=warn`: skill is usable but should be improved.
- `status=error`: import/readiness issue; fix before relying on the skill.

Findings include `severity`, `id`, `file`, `message`, and `agent_action`.
Agents should fix `error` first, then high-value `warn` findings.

## Agent Rules

- Always run with `--json` when another agent will parse the result.
- Do not treat token/line warnings as automatic failure; use them to decide
  what belongs in `references/`.
- If an external tool such as `skill-validator` is installed, use it as a
  secondary signal, not as the only source of truth.
- This tool is explicit and one-shot. It does not install watchers, pollers, or
  background jobs.
