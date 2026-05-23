# Developer Journal: PowerShell 7 Agent Operations

This journal explains how `powershell-7-agent-operations` and its guard script were formed. It is for future agents extending the skill, guard, hook, or MCP wrapper.

## Purpose

Agents repeatedly make Windows shell mistakes because training data blends Bash, CMD, Windows PowerShell 5.1, and PowerShell 7. The goal was to create an ARH-native skill and lightweight guard that makes `pwsh` command generation more reliable before moving toward runtime wrapping or MCP execution.

The initial deliverable is intentionally small:

```text
powershell-7-agent-operations/
  SKILL.md
  scripts/Test-PwshCommand.ps1
  references/git-bash-compatibility.md
  references/salvage-report.md
  references/developer-journal.md
```

No daemon, polling, auto-start task, or PATH shim was installed.

## Source Material

### Kimi CLI Issue

Source:

```text
https://github.com/MoonshotAI/kimi-cli/issues/1136
```

Salvaged:

- Agents need explicit shell identity, not just "Windows".
- The model should know whether it is targeting PowerShell 7 or legacy Windows PowerShell.
- Shell examples must avoid CMD/PowerShell/Bash mixtures.
- Version-aware syntax matters: PowerShell 7 supports features unavailable in Windows PowerShell 5.1.

Used in:

- `SKILL.md` hard rule: use `pwsh`, not `powershell.exe`.
- Guard rule: `legacy-powershell`.
- Skill sections: "Version-Aware Syntax", "Common Agent Failure Patterns".

### Juejin / Antigravity Article Extract

Source:

```text
C:\Users\smoqu\Downloads\Antigravity.md
Original URL: https://juejin.cn/post/7597348590709981224
```

The web page itself was not readable from browser extraction, but the local markdown copy was readable.

Salvaged:

- The concrete recurring failure: PowerShell nested quoting in generated commands.
- The practical rule: for human text arguments, prefer outer double quotes with inner single quotes.
- Example:

```powershell
git commit -m "feat: integrated 'user login' module"
```

- Avoid Bash-habit outer single quotes around a string containing double quotes:

```powershell
git commit -m 'feat: integrated "user login" module'
```

- For embedded double quotes inside a PowerShell double-quoted string, use the backtick escape, not Bash-style backslash escaping.

Used in:

- `SKILL.md` "Quoting Rules".
- Guard rules:
  - `git-commit-single-quote-message`
  - `bash-double-quote-escape`

### Local `powershell-1.0.0` Skill

Path:

```text
D:\00_ARH\01_homelab\00_agent-hub\skills\powershell-1.0.0
```

Salvaged:

- PowerShell output behavior: uncaptured expressions emit output.
- `$LASTEXITCODE` is needed for native commands.
- `$null` should be on the left side of comparisons.
- Arrays collapse to scalar for single-item results.
- `Write-Host` bypasses the pipeline.
- PowerShell comparison operators are not Bash/C-style operators.

Used in:

- `SKILL.md` hard rules and script checklist.
- Future guard candidates, not all implemented yet.

### Local `powershell-7-expert_20260306102454` Skill

Path:

```text
D:\00_ARH\01_homelab\00_agent-hub\skills\powershell-7-expert_20260306102454
```

Salvaged:

- PS7-specific features: pipeline chain operators, ternary, null coalescing, platform variables.
- Script requirement: `#Requires -Version 7.0`.
- Cross-platform checks with `$IsWindows`, `$IsLinux`, `$IsMacOS`.
- Wrapper idea from `scripts/ps7_wrapper.ts`: run `pwsh` explicitly and pass arguments as arrays.

Rejected/adapted:

- The TypeScript wrapper builds script arguments too loosely for direct reuse.
- We kept the explicit `pwsh` invocation principle, but did not import the wrapper.

Used in:

- `SKILL.md` script checklist.
- Guard `-Path` mode checks for `#Requires -Version 7.0`.

### Local `powershell-shell-detection_20260310022026`

Path:

```text
D:\00_ARH\01_homelab\00_agent-hub\skills\powershell-shell-detection_20260310022026
```

Salvaged:

- Shell detection order:
  - PowerShell: `$PSVersionTable`, `$env:PSModulePath`.
  - Git Bash/MSYS: `$MSYSTEM`, `uname -s`.
- Environment variable differences:
  - PowerShell: `$env:VAR`.
  - Bash: `$VAR`.
- Path style differences.
- MSYS path conversion traps.

Used in:

- `references/git-bash-compatibility.md`.
- `SKILL.md` shell decision rules.
- Guard rule: `bash-env-prefix`.

### Local `ado-windows-git-bash-compatibility_20260313042933`

Path:

```text
D:\00_ARH\01_homelab\00_agent-hub\skills\ado-windows-git-bash-compatibility_20260313042933
```

Salvaged:

- Azure/Windows Git Bash path-conversion risks.
- `MSYS_NO_PATHCONV=1`.
- `MSYS2_ARG_CONV_EXCL`.
- `cygpath` conversion examples.

Used in:

- `references/git-bash-compatibility.md`.

### `pwsh-repl-v0.2.0-win-x64`

Path:

```text
C:\Users\smoqu\Downloads\pwsh-repl-v0.2.0-win-x64
```

Observed:

- `PowerShellMcpServer.exe`
- `Modules\AgentBlocks`
- `Invoke-DevRun`
- stream capture
- cached full outputs
- condensed summaries
- error pattern registry
- project tool discovery

Salvaged as design ideas:

- A future runner should capture PowerShell streams separately.
- Full output should be cached, while the agent receives a short summary.
- Error patterns can be recognized and grouped.

Rejected for now:

- Installing or auto-starting `PowerShellMcpServer.exe`.
- Letting a long-running REPL execute arbitrary agent-written text by default.
- Making it the default command path before security/process-lifetime review.

Future extension target:

```text
Invoke-ArhPwshRun.ps1
arh-pwsh-runtime-mcp
```

## Implementation Blueprint

### Skill

`SKILL.md` is the agent-facing operating guide. It tells agents:

- when to use this skill
- that `pwsh` 7+ is the default
- how to quote command arguments
- when to use Git Bash references
- how to run the guard
- how to interpret guard exit codes

### Guard Script

`scripts/Test-PwshCommand.ps1` is a static preflight guard. It accepts either:

```powershell
-Command '<text>'
```

or:

```powershell
-Path '.\script.ps1'
```

It emits a structured object or JSON:

```json
{
  "status": "warn",
  "target": "<command>",
  "shell": "PowerShell 7.6.1",
  "findings": [
    {
      "severity": "warn",
      "id": "bash-ls",
      "message": "Bash-style ls flags detected.",
      "agent_action": "Use Get-ChildItem -Force or Get-ChildItem with explicit parameters."
    }
  ]
}
```

Exit codes:

```text
0 = ok
1 = warnings
2 = blocking errors
3 = guard runtime failure
```

## Guard Rules Implemented

| Rule ID | Severity | Purpose |
|---|---|---|
| `not-pwsh7` | error | guard must run under PowerShell 7+ |
| `legacy-powershell` | error | block generated calls to legacy Windows PowerShell |
| `missing-requires-version` | warn | `.ps1` should declare `#Requires -Version 7.0` |
| `missing-erroractionpreference` | warn | `.ps1` should set `$ErrorActionPreference = "Stop"` |
| `bash-ls` | warn | catches `ls -la` style commands |
| `bash-cat` | warn | catches `cat file` style commands |
| `bash-grep` | warn | catches `grep` in pwsh commands |
| `cmd-dir-switch` | warn | catches `dir /b`-style CMD leakage |
| `cmd-set-env` | warn | catches `set VAR=value` CMD leakage |
| `bash-env-prefix` | warn | catches `VAR=value command` Bash leakage |
| `git-commit-single-quote-message` | warn | catches Bash-style commit message quoting |
| `bash-double-quote-escape` | warn | catches `\"` Bash-style escaping |
| `unix-rm-rf` | warn | catches `rm -rf` |
| `native-status` | warn | catches likely misuse of `$?` for native command status |
| `unsafe-recursive-remove` | error | blocks recursive delete without visible target verification |
| `move-without-visible-guard` | warn | warns on `Move-Item` without visible path/backup guard |
| `visible-background-process` | warn | warns when background helpers may open visible pwsh windows |

## Tests Performed

### Clean Command

```powershell
Test-PwshCommand.ps1 -Command 'Get-ChildItem -Force' -Json
```

Expected and observed:

```text
status=ok
exit=0
```

### Bash Leakage

```powershell
Test-PwshCommand.ps1 -Command 'ls -la && cat file.txt' -Json
```

Expected and observed:

```text
status=warn
exit=1
findings=bash-ls,bash-cat
```

### Legacy PowerShell

```powershell
Test-PwshCommand.ps1 -Command 'powershell.exe -NoProfile -Command Get-Date' -Json
```

Expected and observed:

```text
status=error
exit=2
finding=legacy-powershell
```

### Unsafe Recursive Delete

```powershell
Test-PwshCommand.ps1 -Command 'Remove-Item -Recurse C:\Temp\foo' -Json
```

Expected and observed:

```text
status=error
exit=2
finding=unsafe-recursive-remove
```

### Commit Message Quoting

Used a here-string so the guard received the intended literal command:

```powershell
$cmd = @'
git commit -m 'feat: integrated "user login" module'
'@
Test-PwshCommand.ps1 -Command $cmd -Json
```

Expected and observed:

```text
status=warn
exit=1
finding=git-commit-single-quote-message
```

### Bash Double-Quote Escape

```powershell
$cmd = @'
ssh host "mysql -e \"SELECT id FROM logs\""
'@
Test-PwshCommand.ps1 -Command $cmd -Json
```

Expected and observed:

```text
status=warn
exit=1
finding=bash-double-quote-escape
```

### Guard Self-Check

```powershell
Test-PwshCommand.ps1 -Path .\scripts\Test-PwshCommand.ps1 -Json -NoLearned
```

Use `-NoLearned` because the guard script contains regex literals and remediation strings that include the same substrings the learned patterns match (e.g., `mkdir -p`, `touch`, `python3`). Without `-NoLearned`, these patterns fire on the guard's own examples.

Initial issue:

- the guard self-triggered on its own remediation strings and regex literals.

Fixes:

- narrowed `legacy-powershell` to command-position matches.
- reworded the `bash-mkdir-p` message to avoid `; PowerShell`, which the `legacy-powershell` regex matched.
- built the backslash-quote regex dynamically:

```powershell
$backslashQuotePattern = [regex]::Escape(([char]92).ToString() + [char]34)
```

Final observed:

```text
status=ok
exit=0
```

### Syntax Parse

```powershell
$tokens=$null
$parseErrors=$null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
  '...\Test-PwshCommand.ps1',
  [ref]$tokens,
  [ref]$parseErrors
)
```

Observed:

```text
Syntax OK
```

### Skill QA

```powershell
$env:PYTHONPATH='D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-skill-qa\src'
python -B -m arh_skill_qa.cli check D:\00_ARH\01_homelab\00_agent-hub\_skills\_arh-custom\powershell-7-agent-operations --json
```

Observed:

```text
status=ok
score=100
exit=0
```

## Known Gaps

The guard is static and regex-based. It does not parse PowerShell AST for command semantics yet.

Closed follow-up after initial deployment:

- `mkdir -p` now triggers `bash-mkdir-p` as an error.
- `touch` now triggers `bash-touch`.
- `cp -r` now triggers `bash-cp-recursive`.
- `mv` now triggers `bash-mv`.
- `chmod` now triggers `bash-chmod`.
- `sed` and `awk` now trigger `bash-sed` and `bash-awk`.
- `python3` now triggers `python3-libreoffice-trap` as an error.

Remaining likely additions:

- bare `npm` in Bash on ARH -> `npm.cmd`, but only when the execution context is actually Bash.
- AST-aware parsing so remediation strings and regex literals are not confused with executable command positions.

## MCP / Hook Roadmap

The user asked whether a runtime MCP could auto-wrap PowerShell execution.

Conclusion:

- MCP alone cannot magically intercept native shell calls.
- It can provide a guarded execution tool that agents choose to use.
- True auto-wrap needs runtime hooks, a command policy, or a PATH shim.

Recommended staged rollout:

### Phase 1: Explicit Guard

Current state:

```powershell
Test-PwshCommand.ps1 -Command '<command>' -Json
```

### Phase 2: Guarded Runner

Create:

```text
Invoke-ArhPwshRun.ps1
```

Responsibilities:

- run `Test-PwshCommand.ps1`
- block on error
- optionally allow warnings
- execute command
- capture stdout/stderr/exit code
- return JSON

Implemented as:

```text
scripts/Invoke-ArhPwshRun.ps1
```

It validates through `Test-PwshCommand.ps1`, blocks errors, blocks warnings unless `-AllowWarnings` is supplied, launches a child `pwsh`, captures stdout/stderr asynchronously, enforces `-TimeoutSeconds`, and emits a JSON-friendly result object.

### Phase 3: MCP Wrapper

Create:

```text
arh-pwsh-runtime-mcp
```

Tools:

```text
pwsh_validate(command | path)
pwsh_run(command, cwd, timeout, allow_warnings)
pwsh_script_check(path)
pwsh_explain_failure(command, stderr, exit_code)
pwsh_patterns()
```

### Phase 4: Hook Integration

If the active agent runtime supports pre-command hooks, route risky commands through the guard when they contain:

```text
pwsh
.ps1
PowerShell
Remove-Item
Move-Item
mkdir -p
rm -rf
powershell.exe
```

### Phase 5: PATH Shim

Only if hooks are unavailable and strict enforcement is worth the risk. This can affect humans and unrelated tools, so it is not recommended as the first enforcement path.

## Extension Guidelines

When adding a guard rule:

1. Add one focused pattern.
2. Include `severity`, `id`, `message`, and `agent_action`.
3. Add a positive test that should remain clean.
4. Add a negative test that triggers the new finding.
5. Run self-check on `Test-PwshCommand.ps1`.
6. Run `arh-skill-qa` on the skill folder.

Prefer rules that catch repeated agent mistakes over stylistic preferences.

Avoid rules that block legitimate expert PowerShell unless the `agent_action` provides a clear safe alternative.

## Update 2026-05-12: Guarded Runner and Unix Leakage Rules

User-reported failure:

```powershell
mkdir -p "D:\00_ARH\01_homelab\02_stacks-frontend\universal-dashboard" "D:\00_ARH\01_homelab\02_stacks-frontend\universal-dashboard\assets"
```

Observed behavior:

- In PowerShell, `mkdir` is `New-Item`.
- GNU `mkdir -p` muscle memory can fail or misbind, especially when agents pass multiple directories.
- The existing guard had learned-pattern DB integration but did not include this static rule.

Integration decisions:

- Preserved `-NoLearned`, `source`, and DuckDB-backed learned pattern loading.
- Hardened learned-pattern loading by checking the DB helper path and joining multi-line JSON before `ConvertFrom-Json`.
- Added optional per-pattern severity while leaving existing rules as warnings.
- Marked `mkdir -p` and `python3` as errors because they are explicit ARH hard-rule failures.
- Added `Invoke-ArhPwshRun.ps1` instead of mixing execution into `Test-PwshCommand.ps1`; validation and execution now have separate responsibilities.

New static rule IDs:

```text
bash-mkdir-p
bash-touch
bash-cp-recursive
bash-mv
bash-chmod
bash-sed
bash-awk
python3-libreoffice-trap
```

Runner contract:

```powershell
.\scripts\Invoke-ArhPwshRun.ps1 -Command '<command>' -Json
```

Output fields:

```text
status
command
working_directory
guard
exit_code
stdout
stderr
stdout_lines
stderr_lines
duration_ms
error
```

Exit behavior:

```text
0   success
1   blocked on warning
2   blocked on error or command failure
3   runner/guard failure
124 timeout
```
