# arh-skill-qa

ARH-native quality gate for Agent Skill folders. It checks import readiness,
trigger quality, progressive disclosure, resource hygiene, and ARH local fit.

```powershell
uv tool install --editable D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-skill-qa
arh-skill-qa check D:\00_ARH\01_homelab\00_agent-hub\_skills\_arh-custom\python-uv --json
```

Exit codes: `0=ok`, `1=warn`, `2=error`, `3=tool failure`.
