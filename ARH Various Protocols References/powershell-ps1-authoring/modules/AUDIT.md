# AUDIT — PS1 Script Review & Quality Analysis

Covers: PSScriptAnalyzer rules, security patterns, code smells, review checklist, ARH-specific checks.

---

## Five Lenses for Script Review

| Lens | Questions | Tools |
|---|---|---|
| **Correctness** | Does it handle errors? Exit codes checked? Edge cases? | Manual + PSSA |
| **Security** | Credentials exposed? Invoke-Expression on input? Injection risk? | PSSA security rules |
| **Reliability** | `$ErrorActionPreference = Stop`? Paths safe? Atomic ops? | Manual |
| **Maintainability** | Named functions? No magic strings? Clear param names? | PSSA style rules |
| **ARH Compliance** | `#Requires -Version 7.0`? No KF-17 violation? Paths via `$PSScriptRoot`? | arh-ps1-qa ARH checks |

---

## PSScriptAnalyzer Rule Categories

### Security Rules (always on)

| Rule | What it catches |
|---|---|
| `PSAvoidUsingInvokeExpression` | `Invoke-Expression` — code injection risk with dynamic input |
| `PSAvoidUsingPlainTextForPassword` | Param names like `Password`, `Secret` with `[string]` type |
| `PSAvoidUsingUsernameAndPasswordParams` | Explicit username+password params — should use `[PSCredential]` |
| `PSAvoidUsingConvertToSecureStringWithPlainText` | `ConvertTo-SecureString -AsPlainText` without warning |
| `PSAvoidUsingComputerNameHardcoded` | Hardcoded hostnames in cmdlets |
| `PSUsePSCredentialType` | Any param named Credential that isn't `[PSCredential]` |

### Correctness Rules

| Rule | What it catches |
|---|---|
| `PSAvoidUsingCmdletAliases` | `ls`, `dir`, `gci`, `%`, `?` etc. — use full names in scripts |
| `PSAvoidDefaultValueSwitchParameter` | `[switch]$Verbose = $true` — switches default to false always |
| `PSMisleadingBacktick` | Trailing backtick with whitespace after — not a line continuation |
| `PSUseCorrectCasing` | Cmdlet/parameter casing mismatches (style + helps readability) |
| `PSUseDeclaredVarsMoreThanAssignments` | Variable assigned but never read (dead variable) |
| `PSAvoidGlobalVars` | `$global:Var` — use `$script:` scope instead |

### Style Rules

| Rule | What it catches |
|---|---|
| `PSProvideCommentHelp` | Functions without `.SYNOPSIS` comment-based help |
| `PSUseOutputTypeCorrectly` | `[OutputType()]` declaration mismatch |
| `PSUseShouldProcessForStateChangingFunctions` | Cmdlets with `Set-`/`Remove-` verbs without `SupportsShouldProcess` |
| `PSReviewUnusedParameter` | Declared parameter never referenced in function body |
| `PSAvoidTrailingWhitespace` | Trailing spaces — encoding noise, diff noise |

---

## Running PSScriptAnalyzer

```powershell
# Install once
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force

# Lint a single file
Invoke-ScriptAnalyzer -Path .\script.ps1

# Full directory scan
Invoke-ScriptAnalyzer -Path D:\00_ARH\01_homelab\00_agent-hub\env\scripts -Recurse

# Severity filter
Invoke-ScriptAnalyzer -Path .\script.ps1 -Severity Error, Warning

# Use ARH settings
Invoke-ScriptAnalyzer -Path .\script.ps1 -Settings D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-ps1-qa\pssa-config.psd1

# JSON output (for agent consumption)
Invoke-ScriptAnalyzer -Path .\script.ps1 | ConvertTo-Json -Depth 3
```

---

## ARH-Specific Checks (arh-ps1-qa)

These are not covered by PSScriptAnalyzer and are checked by `arh-ps1-qa.ps1`:

| Check | Pattern | Severity |
|---|---|---|
| Missing version requirement | No `#Requires -Version 7.0` | Warning |
| Missing error preference | No `$ErrorActionPreference = 'Stop'` | Warning |
| Legacy engine usage | `powershell.exe` in script body | Error |
| Relative paths | `'.\` or `".\"` path strings (not in `$PSScriptRoot` expression) | Warning |
| KF-17 violation | `Get-ChildItem.*-Recurse` on paths containing `ARH` or `D:\ARH` | Error |
| Raw cmd spawning | `cmd /c` or `cmd.exe` in script | Warning |
| Hardcoded user path | `C:\Users\smoqu` in script | Warning |
| Unchecked LASTEXITCODE | External command call not followed by `$LASTEXITCODE` check | Info |

---

## Security Taxonomy

| Vulnerability Class | PS1 Manifestation | PSSA Rule |
|---|---|---|
| **Code Injection** | `Invoke-Expression $userInput` | `PSAvoidUsingInvokeExpression` |
| **Credential Exposure** | `[string]$Password` param | `PSAvoidUsingPlainTextForPassword` |
| **Path Traversal** | `Get-Content "$BaseDir\$userInput"` without sanitization | Manual |
| **Privilege Escalation** | `Start-Process ... -Verb RunAs` in unexpected places | Manual |
| **Hardcoded Secrets** | API keys / tokens in string literals | Manual (grep for `apikey`, `token`, `secret`, `password`) |
| **Command Injection via Subprocess** | `& "git $userInput"` (string interpolation in cmdlet name) | Manual |

### Quick security grep patterns

```powershell
# Find credential risks
Select-String -Path *.ps1 -Pattern 'Password|Secret|ApiKey|Token' -CaseSensitive:$false

# Find Invoke-Expression usage
Select-String -Path *.ps1 -Pattern 'Invoke-Expression|iex\s'

# Find hardcoded paths with username
Select-String -Path *.ps1 -Pattern 'C:\\Users\\[^$]'

# Find cmd spawning
Select-String -Path *.ps1 -Pattern 'cmd\.exe|cmd /c'
```

---

## Code Smells Catalog

| Smell | Example | Fix |
|---|---|---|
| Alias in script | `ls $dir`, `% { }`, `? { }` | `Get-ChildItem`, `ForEach-Object`, `Where-Object` |
| Global variable | `$global:State = 'running'` | `$script:State` or pass as parameter |
| Magic string | `if ($status -eq 'running123')` | Named constant or `[ValidateSet]` |
| Swallowed error | `try { ... } catch { }` (empty catch) | Log and rethrow or handle explicitly |
| Ignored exit code | `git push` then continue | Check `$LASTEXITCODE -ne 0` |
| Deep nesting (>3 levels) | `if { if { if { } } }` | Guard clauses + early return |
| Undeclared variable use | `$result` used before assignment | `Set-StrictMode -Version Latest` catches this |
| Positional parameters | `Set-Item 'path' 'value'` | Named: `Set-Item -Path 'path' -Value 'value'` |
| String concatenation for paths | `$dir + '\' + $file` | `Join-Path $dir $file` |
| `Write-Host` for pipeline data | `Write-Host $objects` | `Write-Output $objects` |

---

## Review Checklist

Before approving / finalizing a script:

- [ ] `#Requires -Version 7.0` present
- [ ] `$ErrorActionPreference = 'Stop'` present
- [ ] All paths via `Join-Path $PSScriptRoot ...` or absolute with `$env:`
- [ ] Parameters: typed, validated, no `[bool]` (use `[switch]`)
- [ ] Error handling: try/catch around I/O, external commands, network calls
- [ ] `$LASTEXITCODE` checked after native commands
- [ ] No `Invoke-Expression` with dynamic input
- [ ] No plain-text passwords or API keys in source
- [ ] No `cmd /c "pwsh ..."` — use `Start-Process pwsh -WindowStyle Hidden`
- [ ] No `Get-ChildItem -Recurse` on `D:\ARH` junction (KF-17)
- [ ] Destructive ops: `Test-Path` + optional backup before `Remove-Item`
- [ ] Functions: verb-noun naming, approved verbs only
- [ ] Console output uses `Write-Host` with `-ForegroundColor`
- [ ] PSScriptAnalyzer clean (or findings reviewed and accepted)
