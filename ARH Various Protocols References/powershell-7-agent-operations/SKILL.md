---
name: powershell-7-agent-operations
description: Use when an agent writes or runs Windows PowerShell 7 / pwsh commands, creates .ps1 scripts, debugs PowerShell shell failures, chooses between pwsh and Git Bash, or needs to avoid bash/CMD syntax mistakes in Windows agent workflows. Triggers include "pwsh", "PowerShell 7", "PowerShell script", "shell command on Windows", "Git Bash path conversion", "why did this PowerShell command fail", and "guard this command before running".
---

# PowerShell 7 Agent Operations

Use this skill whenever command correctness depends on Windows shell semantics. The job is to keep agents anchored in `pwsh` 7+, prevent bash/CMD contamination, and provide a fast guard before commands or scripts run.

## First Minute

1. Establish identity: this environment uses **PowerShell 7 via `pwsh`**, not legacy `powershell.exe`, CMD, or Bash unless explicitly stated.
2. Check the command shape before running:
   ```powershell
   .\scripts\Test-PwshCommand.ps1 -Command '<command>' -Json
   ```
   Or run through the guarded executor when you want validation plus captured execution:
   ```powershell
   .\scripts\Invoke-ArhPwshRun.ps1 -Command '<command>' -Json
   ```
3. For `.ps1` files, require:
   ```powershell
   #Requires -Version 7.0
   $ErrorActionPreference = "Stop"
   ```
4. Prefer native PowerShell cmdlets and explicit parameters over aliases or CMD switches.
5. Use Git Bash only for POSIX scripts or Unix text pipelines; when crossing shells, follow `references/git-bash-compatibility.md`.

## Hard Rules

| Do | Avoid |
|---|---|
| `pwsh` / `pwsh.exe` | `powershell.exe` unless explicitly testing PS 5.1 |
| `Get-ChildItem -Force` | `ls -la` |
| `Get-Content -Raw` or `Get-Content` | `cat` in generated agent commands |
| `Select-String -Pattern ...` | `grep` / `findstr` in pwsh commands |
| `New-Item -ItemType Directory -Force -Path ...` | `mkdir -p ...` |
| `New-Item -ItemType File -Force -Path ...` | `touch ...` |
| `Copy-Item -Recurse -LiteralPath ...` | `cp -r ...` |
| `Move-Item -LiteralPath ... -Destination ...` | `mv ...` |
| `python script.py` or `python -` | `python3 ...` |
| `$env:VAR='value'` | `VAR=value command` or `$VAR=value` |
| `Test-Path`, `Join-Path`, `Resolve-Path` | ad hoc string-built paths |
| `$LASTEXITCODE` for native commands | `$?` as the only native-command status check |
| `Remove-Item -LiteralPath ...` with checked root | string-built recursive deletes |
| `Start-Process ... -WindowStyle Hidden` for background helpers | visible popup `pwsh` windows |

## Quoting Rules

When generating command arguments that contain spaces, quotes, or special characters, prefer **outer double quotes with inner single quotes**:

```powershell
git commit -m "feat: integrated 'user login' module"
```

Avoid Bash-habit outer single quotes for Windows command lines when the argument itself contains quotes:

```powershell
git commit -m 'feat: integrated "user login" module'
```

If a double quote must appear inside a double-quoted PowerShell string, escape it with a backtick:

```powershell
"SELECT `"id`", `"name`" FROM logs"
```

Do not use Bash-style `\"` as the default PowerShell escape.

## Version-Aware Syntax

PowerShell 7 supports `&&`, `||`, ternary `? :`, null coalescing `??`, and `$IsWindows`. Legacy Windows PowerShell 5.1 does not support all of these. In ARH, default to PS7 features only when the command is definitely launched with `pwsh`.

For portable conditional chaining inside scripts, prefer explicit status handling:

```powershell
python script.py
if ($LASTEXITCODE -eq 0) {
    Write-Host "ok"
}
```

## Command Guard

Run the bundled guard before risky commands, generated one-liners, or new script bodies:

```powershell
# Check one command
.\scripts\Test-PwshCommand.ps1 -Command 'ls -la && cat file.txt' -Json

# Check a script file
.\scripts\Test-PwshCommand.ps1 -Path .\script.ps1 -Json
```

Exit codes:

- `0`: clean
- `1`: warnings
- `2`: blocking errors
- `3`: guard failure

Findings include `severity`, `id`, `message`, and `agent_action`.

## Guarded Runner

Use the runner when the agent should execute a command only after passing the guard and needs a structured result:

```powershell
.\scripts\Invoke-ArhPwshRun.ps1 -Command 'Write-Output "ok"' -Json
```

Default behavior:

- blocks guard errors
- blocks warnings unless `-AllowWarnings` is supplied
- runs under child `pwsh -NoProfile -ExecutionPolicy Bypass`
- captures stdout, stderr, native exit code, duration, guard findings, and timeout status

Runner examples:

```powershell
# Validate and execute
.\scripts\Invoke-ArhPwshRun.ps1 -Command 'Get-ChildItem -Force' -Json

# Inspect learned/static guard output without DB-backed learned rules
.\scripts\Invoke-ArhPwshRun.ps1 -Command 'Get-ChildItem -Force' -NoLearned -Json

# Permit non-blocking warnings only after reviewing findings
.\scripts\Invoke-ArhPwshRun.ps1 -Command '<reviewed command>' -AllowWarnings -Json
```

## Common Agent Failure Patterns

- **Ambiguous shell identity:** model knows Windows but emits Bash. Fix by stating `pwsh 7+` and using cmdlets.
- **CMD/PowerShell hybrid:** `dir /b`, `copy`, `del`, `set VAR=x`, and `findstr` leak from CMD examples. Replace with PS-native commands.
- **Unix file command leakage:** `mkdir -p`, `touch`, `cp -r`, `mv`, `chmod`, `sed`, and `awk` are not safe defaults for pwsh. Use native cmdlets or short Python scripts.
- **Quote-loop failure:** nested quotes copied from Bash examples cause repeated retries. For human text arguments, use outer double quotes and inner single quotes.
- **Git Bash path conversion:** `/c/foo`, `/p:Config`, and colon path lists can be rewritten by MSYS. Use PowerShell for Windows paths or set `MSYS_NO_PATHCONV=1` in Bash.
- **Output leaks:** any uncaptured expression writes to output. Assign to `$null` or cast `[void]` when suppressing.
- **Array scalar trap:** single-item output becomes scalar. Wrap with `@(...)` when count/iteration stability matters.

## Script Authoring Checklist

- Add `#Requires -Version 7.0` at the top for ARH scripts.
- Use approved verb-noun function names where practical.
- Use `[CmdletBinding()]` for non-trivial scripts.
- Use `param(...)` with typed parameters instead of parsing raw args.
- Use `-LiteralPath` for user-provided filesystem paths.
- Resolve and verify destructive targets before `Remove-Item` or `Move-Item`.
- Use `try/catch` only after making non-terminating errors terminating with `-ErrorAction Stop`.
- For JSON, prefer `ConvertFrom-Json` / `ConvertTo-Json`; for external JSON CLI parsing, ARH also has `jaq`.

## Resource Map

- `scripts/Test-PwshCommand.ps1` - static guard for command/script text.
- `scripts/Invoke-ArhPwshRun.ps1` - guarded executor that validates, runs, captures streams, and returns JSON.
- `references/git-bash-compatibility.md` - when pwsh must interoperate with Git Bash/MSYS2.
- `references/python-inline-patterns.md` - safe `python -` and here-string patterns from PowerShell.
- `references/salvage-report.md` - what was adopted, adapted, and rejected from the source skills, Kimi issue, and `pwsh-repl`.
- `references/developer-journal.md` - implementation history, source salvage notes, tests, and extension roadmap.

## Validation

After editing this skill or guard script:

```powershell
$env:PYTHONPATH='D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-skill-qa\src'
python -B -m arh_skill_qa.cli check D:\00_ARH\01_homelab\00_agent-hub\_skills\_arh-custom\powershell-7-agent-operations --json
```

If the CLI is installed:

```powershell
arh-skill-qa check D:\00_ARH\01_homelab\00_agent-hub\_skills\_arh-custom\powershell-7-agent-operations --json
```

Guard smoke tests:

```powershell
.\scripts\Test-PwshCommand.ps1 -Command 'Get-ChildItem -Force' -Json
.\scripts\Test-PwshCommand.ps1 -Command 'ls -la' -Json
.\scripts\Test-PwshCommand.ps1 -Command 'mkdir -p "a" "b"' -Json
.\scripts\Test-PwshCommand.ps1 -Path .\scripts\Test-PwshCommand.ps1 -Json -NoLearned
.\scripts\Invoke-ArhPwshRun.ps1 -Command 'Write-Output "ok"' -Json
```
