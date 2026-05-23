---
name: powershell-ps1-authoring
description: >
  ARH skill for writing, designing, and reviewing PowerShell 7 (.ps1) scripts.
  Covers script anatomy, parameter patterns, error handling, output conventions,
  PSScriptAnalyzer integration, and the arh-ps1-qa CLI tool. Triggers on any
  PS1 authoring task: writing a new script, reviewing an existing one, setting
  up QA gates, or scaffolding from the ARH template. Complements
  powershell-7-agent-operations (which covers running commands safely).
category: powershell
tags: [powershell, ps1, pwsh, pssa, psscriptanalyzer, scripting, arh, design, audit, quality]
---

# PowerShell PS1 Authoring — ARH Domain Skill

One skill to govern writing and reviewing `.ps1` scripts on this machine.
Four expert perspectives:

- **Design** — script anatomy, parameters, types, output, error handling
- **Audit** — PSScriptAnalyzer, security patterns, dead code, code smells
- **Toolchain** — PSScriptAnalyzer, Pester, VS Code integration, script signing
- **Debugging** — common PS7 failure modes, `$ErrorActionPreference` traps, path errors

`arh-ps1-qa.ps1` is the CLI quality pipeline. `New-PS1.ps1` scaffolds new scripts.

---

## ARH Hard Rules — Read First

These override generic PS advice. Violations cause silent failures.

| Rule | Why |
|---|---|
| `#Requires -Version 7.0` at top of every personal script | Prevents accidental run under PS 5.1 where syntax differs |
| `$ErrorActionPreference = 'Stop'` early in every script | Non-terminating errors become exceptions; prevents silent failures |
| `Set-StrictMode -Version Latest` in personal scripts | Catches uninitialized vars, bad array references |
| Paths: always `Join-Path $PSScriptRoot '...'` | Never bare relative paths — break when cwd differs from script location |
| `pwsh` — never `powershell.exe` | KF: legacy engine, different behavior |
| `Write-Host` for console output, `Write-Output` for pipeline data | Write-Host emits to info stream (not pipeline), keeps scripts pipeline-composable |
| Destructive ops: `Test-Path` before `Remove-Item` / `Move-Item` | Verify destination; backup to `_history/` for irreversible ops |
| Never `Get-ChildItem -Recurse` through `D:\ARH` junction | KF-17: resolves junction → disk walk of entire ARH tree. Use arh-gateway MCP |
| `Start-Process pwsh -WindowStyle Hidden` for background helpers | Prevents visible popup windows (prior incident: arh-watch.ps1 cmd.exe flash) |
| `$env:VAR` — never `$VAR` for env vars | `$VAR` creates a PS variable; `$env:VAR` reads environment |
| Quote paths in `Start-Process -ArgumentList` with backtick-escaped inner quotes | Unquoted paths with spaces fail silently |

---

## Mode Router

| What you're doing | Module to load |
|---|---|
| Write a new script (anatomy, params, error handling) | `modules/DESIGN.md` |
| Review existing script for quality/security | `modules/AUDIT.md` |
| Run PSScriptAnalyzer, Pester, configure PSSA | `modules/TOOLCHAIN.md` |
| Debug why a script fails, path/encoding/scope issues | `modules/DEBUGGING.md` |
| Need a canonical blank script to start from | `references/template.ps1` |
| Identify bad patterns in existing code | `references/anti-patterns.md` |
| PSScriptAnalyzer settings file | `references/pssa-config.psd1` |

Load one module. Load more only when the task spans domains.

---

## Agent Orchestration — Use the CLI Tools

Two CLI tools in `_cli-utils/arh-ps1-qa/`:

```powershell
# Scaffold a new script from the ARH template
pwsh -File New-PS1.ps1 -Name "Sync-AgentData" -Synopsis "Syncs agent session data" -OutputDir .

# Lint a single file (PSScriptAnalyzer + ARH rules)
pwsh -File arh-ps1-qa.ps1 -Path .\script.ps1 -Mode lint

# Full audit of a directory
pwsh -File arh-ps1-qa.ps1 -Path D:\00_ARH\01_homelab\00_agent-hub\env\scripts -Mode full

# Security audit only
pwsh -File arh-ps1-qa.ps1 -Path .\script.ps1 -Mode audit

# Machine-readable output
pwsh -File arh-ps1-qa.ps1 -Path .\script.ps1 -Mode full -Json
```

`arh-ps1-qa.ps1` returns structured results with per-rule severity and an overall status.
See `_cli-utils/arh-ps1-qa/AGENT_HANDBOOK.md` for full agent-oriented documentation.

---

## Quick Reference — Canonical Script Header

Every ARH personal script starts like this:

```powershell
#Requires -Version 7.0
<#
.SYNOPSIS
  One-line summary (imperative verb, < 80 chars).

.DESCRIPTION
  Multi-line description. Why this script exists.

.PARAMETER ParamName
  What the parameter does and valid values.

.EXAMPLE
  pwsh -File script.ps1 -ParamName value
#>
param(
    [Parameter(Mandatory=$true)][string]$Target,
    [Parameter()][switch]$WhatIf,
    [Parameter()][switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ScriptDir = $PSScriptRoot

function Write-OK   ($m) { Write-Host "[OK]   $m" -ForegroundColor Green  }
function Write-INFO ($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan   }
function Write-WARN ($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-ERR  ($m) { Write-Host "[ERR]  $m" -ForegroundColor Red    }
```

---

## Anti-Pattern Quick Hits

| What you see | What to do instead |
|---|---|
| `$ErrorActionPreference = "Continue"` (or missing) | `$ErrorActionPreference = 'Stop'` |
| `cd $ScriptDir` then relative paths | `Join-Path $PSScriptRoot 'subdir'` — never `cd` |
| `[bool]$Flag` parameter | `[switch]$Flag` — switch is idiomatic, no `$true` needed at callsite |
| `Write-Host "result: $val"` for pipeline output | `Write-Output $val` for data, `Write-Host` for console messages |
| `$result = & cmd args` error ignored | Check `$LASTEXITCODE` or use `-ErrorAction Stop` |
| `Remove-Item $path -Recurse -Force` without `Test-Path` | Verify path exists and is correct before deleting |
| `powershell.exe -File ...` | `pwsh -File ...` |
| `param([string]$Path = ".\")` | `param([string]$Path = $PSScriptRoot)` — relative defaults break |
| Catch block that only sets a flag | Handle or rethrow inside the catch block |
| `$_` used two lines after the catch | Immediately assign: `$err = $_` before any other command |
| `Invoke-Expression $userInput` | Never — code injection. Restructure to direct calls |
| `"Stop"` not set, script continues on error | All production scripts need `$ErrorActionPreference = 'Stop'` |

Full catalog: `references/anti-patterns.md`

---

## Trigger Signals

Load this skill when:
- Writing or modifying a `.ps1` file
- User asks to "create a script", "scaffold a script", "review this script"
- Script has errors, unexpected behavior, or fails silently
- User asks "how should I structure this"
- PSScriptAnalyzer findings need interpretation
- Script needs to handle errors, spawn processes, or manipulate files safely

---

## Modules (load on demand)

- [DESIGN.md](modules/DESIGN.md) — anatomy, params, types, error handling, output, guard clauses
- [AUDIT.md](modules/AUDIT.md) — PSScriptAnalyzer rules, security patterns, review checklist
- [TOOLCHAIN.md](modules/TOOLCHAIN.md) — install/run PSSA, Pester basics, VS Code integration
- [DEBUGGING.md](modules/DEBUGGING.md) — failure modes, scope pitfalls, path/encoding issues

## References

- [template.ps1](references/template.ps1) — canonical blank ARH script
- [anti-patterns.md](references/anti-patterns.md) — full bad-pattern catalog with corrections
- [pssa-config.psd1](references/pssa-config.psd1) — ARH PSScriptAnalyzer settings

## External Tools

- `arh-ps1-qa` — QA pipeline orchestrator (`_cli-utils/arh-ps1-qa/arh-ps1-qa.ps1`)
- `New-PS1` — script scaffolder (`_cli-utils/arh-ps1-qa/New-PS1.ps1`)
- `PSScriptAnalyzer` — static analysis module (install once: `Install-Module PSScriptAnalyzer -Scope CurrentUser`)
