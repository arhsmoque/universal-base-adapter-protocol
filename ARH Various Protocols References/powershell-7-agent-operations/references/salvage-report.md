# Salvage Report

## Sources Reviewed

- MoonshotAI Kimi CLI issue #1136: version-aware PowerShell context.
- Juejin article URL supplied by user: page required JavaScript and was not readable in the browser snapshot.
- `C:\Users\smoqu\Downloads\Antigravity.md`: extracted Juejin article about PowerShell quoting skills.
- `skills/powershell-1.0.0`: output, arrays, comparison, strings, pipeline, errors.
- `skills/powershell-7-expert_20260306102454`: PS7 features, cross-platform patterns, wrapper idea.
- `skills/powershell-shell-detection_20260310022026`: PS/Git Bash detection and path conversion.
- `skills/ado-windows-git-bash-compatibility_20260313042933`: Azure Pipelines and Git Bash path traps.
- `pwsh-repl-v0.2.0-win-x64`: PowerShell MCP server plus AgentBlocks execution/cache/pattern functions.

## Adopt

- Strong shell identity: tell the agent it is in PowerShell 7, not generic Windows shell.
- Version-aware guidance: PS7 supports features not present in Windows PowerShell 5.1.
- Native cmdlet examples only; avoid mixed CMD/PowerShell examples.
- PowerShell quoting reflex: outer double quotes with inner single quotes for human text arguments such as `git commit -m`.
- Backtick escaping for double quotes inside double-quoted PowerShell strings.
- Guard command output as JSON with repair actions.
- Capture and summarize execution patterns from AgentBlocks as a future MCP/runner idea.

## Adapt

- `pwsh-repl` `Invoke-DevRun` cache/summary pattern is useful, but should not become the default shell path until security and process lifetime are reviewed.
- TypeScript `ps7_wrapper.ts` shows how to spawn `pwsh`, but its string handling is too loose for direct reuse. Prefer array arguments and explicit `-File`.
- Git Bash compatibility belongs in a reference file, not in the core skill body.

## Reject For Now

- Installing or auto-starting `PowerShellMcpServer.exe` globally.
- Agent-written scripts that execute arbitrary text through a long-lived REPL without a guard.
- Background polling or resident watchers for shell guidance.
- Broad replacement of existing shell tool behavior before the static guard earns trust.

## Future Upgrade

Potential next tool: `Invoke-ArhPwshRun.ps1`, a local runner that:

- runs a guarded command
- captures output/error/warning streams
- summarizes high-frequency errors
- stores full output in a local cache file
- returns JSON for agents

This should be explicit and one-shot, not a background daemon.
