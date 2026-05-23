# arh-ps1-qa — Agent Handbook

## What these tools do

Two CLI scripts for the PS1 script lifecycle:

- **`arh-ps1-qa.ps1`** — QA pipeline wrapping PSScriptAnalyzer + ARH-specific checks
- **`New-PS1.ps1`** — Scaffold new scripts from the canonical ARH template

Together they enforce consistency across all `.ps1` scripts in the hub and save the token cost of writing boilerplate from scratch every time.

---

## When to use

| Situation | Command |
|---|---|
| Starting a new script | `New-PS1.ps1 -Name "Verb-Noun" -Synopsis "..."` |
| Reviewing a script before commit | `arh-ps1-qa.ps1 -Path .\script.ps1 -Mode lint` |
| Security check | `arh-ps1-qa.ps1 -Path .\script.ps1 -Mode audit` |
| Full hub script audit | `arh-ps1-qa.ps1 -Path .\env\scripts -Mode full -Json` |
| Design check (structure/style) | `arh-ps1-qa.ps1 -Path .\script.ps1 -Mode design` |
| Agent needs structured result | Add `-Json` to any arh-ps1-qa command |

---

## Installation

No install step required. Call directly with `pwsh -File`:

```powershell
$QA  = "D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-ps1-qa\arh-ps1-qa.ps1"
$NEW = "D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-ps1-qa\New-PS1.ps1"
```

PSScriptAnalyzer is required for `arh-ps1-qa.ps1`:
```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

---

## arh-ps1-qa.ps1 — QA Pipeline

### Modes

| Mode | What runs |
|---|---|
| `lint` | PSSA settings file + ARH compliance checks |
| `design` | PSSA design/style rules + ARH compliance |
| `audit` | PSSA security rules only + ARH security patterns |
| `full` | Everything combined |

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `-Path` | cwd | File or directory to analyze |
| `-Mode` | `lint` | Analysis mode |
| `-Json` | off | Output JSON instead of console |
| `-Fix` | off | Auto-fix correctable PSSA issues (lint only) |

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Clean — no findings |
| 1 | Warnings only |
| 2 | One or more errors |
| 3 | Tool failure (PSSA not installed, path not found) |

### JSON output structure

```json
{
  "mode": "full",
  "overall_status": "warn",
  "files_analyzed": 3,
  "total_findings": 5,
  "error_count": 0,
  "warning_count": 5,
  "info_count": 0,
  "pssa_findings": [
    { "RuleName": "PSAvoidUsingCmdletAliases", "Severity": "Warning", "Line": 42, "Message": "...", "ScriptName": "..." }
  ],
  "arh_findings": [
    { "RuleName": "ARH-001", "Severity": "Warning", "Line": 1, "Message": "Missing #Requires -Version 7.0", "ScriptName": "..." }
  ]
}
```

### ARH custom rules

| Rule | Check | Severity |
|---|---|---|
| ARH-001 | `#Requires -Version 7.0` present | Warning |
| ARH-002 | `$ErrorActionPreference = 'Stop'` present | Warning |
| ARH-003 | No `powershell.exe` in script body | Error |
| ARH-004 | No bare relative paths (not via `$PSScriptRoot`) | Warning |
| ARH-005 | No `Get-ChildItem -Recurse` near ARH junction (KF-17) | Error |
| ARH-006 | No `cmd /c` spawning | Warning |
| ARH-007 | No hardcoded `C:\Users\smoqu` paths | Warning |

---

## New-PS1.ps1 — Script Scaffolder

### Parameters

| Parameter | Required | Description |
|---|---|---|
| `-Name` | Yes | Script name (Verb-Noun, no .ps1 extension) |
| `-Synopsis` | Yes | One-line .SYNOPSIS text |
| `-Description` | No | Multi-line .DESCRIPTION text |
| `-OutputDir` | No (cwd) | Where to write the file |
| `-Force` | No | Overwrite existing file |

### What it generates

A complete `.ps1` with:
- `#Requires -Version 7.0`
- Comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`)
- Typed `param()` block with `$Target`, `$WhatIf`, `$Json`
- `$ErrorActionPreference = 'Stop'` + `Set-StrictMode`
- Standard ARH color helpers (`Write-OK`, `Write-INFO`, `Write-WARN`, `Write-ERR`)
- Placeholder main function named `Invoke-<Noun>`
- Entry point with try/catch + JSON output support
- Passes `arh-ps1-qa lint` immediately after creation

### Workflow

```powershell
# 1. Scaffold
pwsh -File $NEW -Name "Sync-SessionData" -Synopsis "Syncs session files to obs DB"
# → Creates Sync-SessionData.ps1 in cwd

# 2. Implement (fill in the Invoke-SessionData function body)

# 3. QA check
pwsh -File $QA -Path .\Sync-SessionData.ps1 -Mode design

# 4. Fix any warnings, then full check
pwsh -File $QA -Path .\Sync-SessionData.ps1 -Mode full
```

---

## Agent decision tree

```
Working with a .ps1 file?
│
├─ New script?
│   └─ New-PS1.ps1 -Name "..." -Synopsis "..."
│
├─ Quick lint before commit?
│   └─ arh-ps1-qa.ps1 -Path .\file.ps1 -Mode lint
│
├─ Security review?
│   └─ arh-ps1-qa.ps1 -Path .\file.ps1 -Mode audit
│
├─ Full hub script audit?
│   └─ arh-ps1-qa.ps1 -Path .\env\scripts -Mode full -Json
│
└─ Auto-fix style issues?
    └─ arh-ps1-qa.ps1 -Path .\file.ps1 -Mode lint -Fix
```
