# TOOLCHAIN — PS1 Quality Tools

Covers: PSScriptAnalyzer installation and usage, Pester basics, VS Code integration, arh-ps1-qa CLI.

---

## PSScriptAnalyzer

The primary static analysis tool for PS1. Catches style, correctness, and security issues.

### Install

```powershell
# Install for current user (no admin required)
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force

# Verify
Get-Module PSScriptAnalyzer -ListAvailable | Select-Object Name, Version
```

### Basic usage

```powershell
# Analyze a file
Invoke-ScriptAnalyzer -Path .\script.ps1

# Analyze directory recursively
Invoke-ScriptAnalyzer -Path .\scripts -Recurse

# Only errors and warnings
Invoke-ScriptAnalyzer -Path .\script.ps1 -Severity Error, Warning

# Use ARH settings profile
Invoke-ScriptAnalyzer -Path .\script.ps1 `
    -Settings D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-ps1-qa\pssa-config.psd1

# Output as JSON for agents
Invoke-ScriptAnalyzer -Path .\script.ps1 | ConvertTo-Json -Depth 3

# Fix auto-correctable issues
Invoke-ScriptAnalyzer -Path .\script.ps1 -Fix
```

### Output fields

| Field | Meaning |
|---|---|
| `RuleName` | PSAvoidUsingAliases, PSUseShouldProcess, etc. |
| `Severity` | Error, Warning, Information |
| `Line` / `Column` | Location in source |
| `Message` | Human-readable explanation |
| `ScriptName` | File path |

### Rule discovery

```powershell
# List all available rules
Get-ScriptAnalyzerRule | Select-Object RuleName, Severity, Description

# List security rules only
Get-ScriptAnalyzerRule | Where-Object { $_.RuleName -match 'Password|Credential|Invoke' }

# Check one specific rule
Invoke-ScriptAnalyzer -Path .\script.ps1 -IncludeRule PSAvoidUsingInvokeExpression
```

---

## ARH PSSA Settings Profile

Location: `_cli-utils/arh-ps1-qa/pssa-config.psd1`

Key ARH opinionated settings:
- `PSAvoidUsingWriteHost` → **excluded** (ARH uses Write-Host intentionally for console scripts)
- Security rules → all enabled
- Style rules → warnings, not errors

Apply via: `Invoke-ScriptAnalyzer -Path . -Settings ...\pssa-config.psd1`

---

## arh-ps1-qa CLI

The ARH quality pipeline wrapping PSScriptAnalyzer + ARH-specific checks.

```powershell
$QA = "D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-ps1-qa\arh-ps1-qa.ps1"

# Lint a file (PSSA warnings + errors)
pwsh -File $QA -Path .\script.ps1 -Mode lint

# Design check (structure + ARH compliance)
pwsh -File $QA -Path .\script.ps1 -Mode design

# Security audit
pwsh -File $QA -Path .\script.ps1 -Mode audit

# Full pipeline
pwsh -File $QA -Path .\scripts -Mode full -Json
```

**Exit codes:** 0=clean, 1=warnings, 2=errors, 3=tool failure

---

## New-PS1 Scaffolder

```powershell
$NEW = "D:\00_ARH\01_homelab\00_agent-hub\_cli-utils\arh-ps1-qa\New-PS1.ps1"

# Create new script from ARH template
pwsh -File $NEW -Name "Sync-AgentData" -Synopsis "Syncs session data to obs DB" -OutputDir .

# With description and scope hint
pwsh -File $NEW -Name "Get-HubReport" -Synopsis "Generates hub health report" `
    -Description "Queries arh-obs.duckdb and formats a status report." `
    -OutputDir D:\00_ARH\01_homelab\00_agent-hub\env\scripts
```

Produces a fully-formed `.ps1` with `#Requires`, help block, `param()`, standard helpers, and placeholder entry point.

---

## Pester (Testing)

Pester is the standard PS test framework. Use for scripts that warrant testing.

### Install

```powershell
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
```

### Basic test structure

```powershell
# tests/script.Tests.ps1
BeforeAll {
    . $PSScriptRoot\..\script.ps1   # dot-source to load functions
}

Describe 'ConvertTo-FlatList' {
    It 'returns empty list for null input' {
        $result = ConvertTo-FlatList -Node $null
        $result | Should -HaveCount 0
    }

    It 'flattens nested structure' {
        $node = [PSCustomObject]@{ contents = @(
            [PSCustomObject]@{ name='a'; type='file'; size=100 }
        )}
        $result = ConvertTo-FlatList -Node $node
        $result[0].path | Should -Be 'a'
    }
}
```

### Run tests

```powershell
Invoke-Pester -Path .\tests -Output Detailed

# With coverage (requires Pester 5+)
Invoke-Pester -Path .\tests -CodeCoverage .\script.ps1 -Output Detailed
```

### What to test

- Pure functions (input → output, no side effects)
- Validation logic
- Error handling paths

Skip testing: scheduled task wrappers, file watchers, one-off admin scripts.

---

## VS Code Integration

### Recommended extensions

| Extension | Purpose |
|---|---|
| `ms-vscode.powershell` | Syntax, IntelliSense, integrated PSSA |
| `EditorConfig.EditorConfig` | Enforces file encoding, indent, line endings |

### VS Code settings for ARH PS1

```json
{
  "powershell.scriptAnalysis.settingsPath": "D:\\00_ARH\\01_homelab\\00_agent-hub\\_cli-utils\\arh-ps1-qa\\pssa-config.psd1",
  "powershell.codeFormatting.preset": "OTBS",
  "powershell.codeFormatting.useCorrectCasing": true,
  "files.encoding": "utf8",
  "files.eol": "\r\n"
}
```

`OTBS` = One True Brace Style — opening brace on same line, matching the ARH convention in all existing scripts.

---

## EditorConfig for PS1

```ini
# .editorconfig (at hub root or script dir)
[*.ps1]
charset = utf-8
end_of_line = crlf
indent_style = space
indent_size = 4
trim_trailing_whitespace = true
insert_final_newline = true
max_line_length = 115
```
