# DESIGN — PowerShell Script Design Patterns

Covers: script anatomy, parameter design, type usage, output conventions, error handling, function organization, guard clauses.

---

## Script vs Module Decision

| Signal | Use script (`.ps1`) | Use module (`.psm1`) |
|---|---|---|
| Size | Single operation, < ~400 lines | Reusable library, multiple functions |
| Callers | Run directly or from scheduled task | Dot-sourced or `Import-Module` by other scripts |
| State | Stateless, runs to completion | Shared functions, persistent state |
| Distribution | Internal use, self-contained | Shared across multiple scripts |
| Testing | Optional | Pester tests required |

Default: write a `.ps1` script. Only promote to a module when multiple scripts need to share functions.

---

## Canonical Script Anatomy

Section order is mandatory. Never reorder.

```powershell
#Requires -Version 7.0          # 1. Version requirement
<#                              # 2. Comment-based help (INSIDE scope or top-of-file)
.SYNOPSIS
  Verb-noun one-liner under 80 chars.

.DESCRIPTION
  Why this script exists. What it does at a high level.

.PARAMETER ParamName
  Explain each parameter. Valid values if constrained.

.EXAMPLE
  pwsh -File script.ps1 -ParamName value
  What this example demonstrates.

.NOTES
  Author, date, version — optional but useful for shared scripts.
#>
param(                          # 3. Parameters block
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [Parameter()]
    [ValidateSet('json','text')]
    [string]$Format = 'text',

    [Parameter()][switch]$WhatIf,
    [Parameter()][switch]$Json
)

$ErrorActionPreference = 'Stop' # 4. Error preference — always Stop
Set-StrictMode -Version Latest  # 5. Strict mode — optional but recommended
$ScriptDir = $PSScriptRoot      # 6. Anchor path to script location

# -- Helpers ------------------------------------------------------------------  # 7. Status helpers (standard ARH pattern)

function Write-OK   ($m) { Write-Host "[OK]   $m" -ForegroundColor Green  }
function Write-INFO ($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan   }
function Write-WARN ($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-ERR  ($m) { Write-Host "[ERR]  $m" -ForegroundColor Red    }

# -- Functions ----------------------------------------------------------------  # 8. Business logic functions

function Invoke-MainLogic {
    param([string]$Input)
    # ...
}

# -- Entry point --------------------------------------------------------------  # 9. Entry point — minimal, calls functions

Invoke-MainLogic -Input $Target
```

---

## Parameter Design

### Type Rules

| Need | Type |
|---|---|
| Boolean flag | `[switch]` — never `[bool]` |
| File path | `[string]` with `[ValidateScript({ Test-Path $_ })]` |
| One of fixed values | `[ValidateSet('a','b','c')]` |
| Non-empty string | `[ValidateNotNullOrEmpty()]` |
| Integer range | `[ValidateRange(1, 100)]` |
| Multiple values | `[string[]]` (array) — use singular param name |
| 3-state flag | `[Nullable[bool]]` — true/false/unspecified |
| Credentials | `[PSCredential]` with `[System.Management.Automation.CredentialAttribute()]` |

### Validation Attributes

```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter()]
    [ValidateSet('Start','Stop','Restart')]
    [string]$Action = 'Start',

    [Parameter()]
    [ValidateRange(1, 65535)]
    [int]$Port = 8080,

    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$ConfigPath,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$Json
)
```

### Parameter Sets

Use parameter sets for alternate input modes. Name them explicitly.

```powershell
param(
    [Parameter(Mandatory=$true, ParameterSetName='ByName')]
    [string]$Name,

    [Parameter(Mandatory=$true, ParameterSetName='ById')]
    [int]$Id,

    [Parameter(ParameterSetName='ByName')]
    [Parameter(ParameterSetName='ById')]
    [switch]$Verbose   # shared across both sets
)
```

### Default Values

```powershell
# ✅ Base relative defaults on $PSScriptRoot, not cwd
[string]$OutputDir = (Join-Path $PSScriptRoot 'output')

# ✅ Use env vars for user-specific defaults
[string]$ConfigPath = (Join-Path $env:USERPROFILE '.arh\config.json')

# ❌ Never bare relative paths as defaults
[string]$OutputDir = '.\output'   # breaks when cwd != script dir
```

---

## Output Conventions

### Two streams, two purposes

```powershell
# Console messages — Write-Host (info stream, NOT in pipeline)
Write-Host "[OK]   Operation complete" -ForegroundColor Green
Write-Host "[ERR]  File not found: $path" -ForegroundColor Red

# Pipeline data — Write-Output (or bare object/value)
Write-Output $result
$result   # bare — same effect

# Never use Write-Host for data a caller might capture
# Never use Write-Output for console messages (caller won't see color)
```

### Standard ARH color scheme

```powershell
function Write-OK   ($m) { Write-Host "[OK]   $m" -ForegroundColor Green  }
function Write-INFO ($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan   }
function Write-WARN ($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-ERR  ($m) { Write-Host "[ERR]  $m" -ForegroundColor Red    }
function Write-DIFF ($m) { Write-Host "[DIFF] $m" -ForegroundColor Magenta}
```

### JSON output mode (for agent consumption)

Scripts that agents call should support `-Json`:

```powershell
param([switch]$Json)

# Build result object
$result = [PSCustomObject]@{
    status  = 'ok'        # ok | warn | error
    message = 'Done'
    data    = $output
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5 -Compress
} else {
    Write-OK $result.message
}
```

---

## Error Handling

### Always Stop, always try/catch

```powershell
$ErrorActionPreference = 'Stop'   # top of script

# ✅ Wrap operations that can fail
try {
    $content = Get-Content $path -Raw
    $parsed  = $content | ConvertFrom-Json
} catch [System.IO.FileNotFoundException] {
    Write-ERR "Config not found: $path"
    exit 1
} catch {
    Write-ERR "Unexpected error: $_"
    exit 1
}

# ✅ Capture $_ immediately — it's overwritten by the next command
try {
    risky-operation
} catch {
    $err = $_           # capture now
    Write-WARN "Failed: $err"
    # now safe to call other things
}
```

### Native command exit codes

```powershell
# ✅ Check $LASTEXITCODE for external tools, not $?
duckdb $DB ".read $sqlFile"
if ($LASTEXITCODE -ne 0) {
    Write-ERR "duckdb failed (exit $LASTEXITCODE)"
    exit 1
}

# ✅ Treat non-zero exit as error
$output = & git status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-ERR "git status failed: $output"
    exit 1
}
```

### WhatIf support

Add `-WhatIf` for scripts that make state changes:

```powershell
param([switch]$WhatIf)

if ($WhatIf) {
    Write-INFO "[WhatIf] Would delete: $path"
} else {
    Remove-Item -LiteralPath $path -Force
    Write-OK "Deleted: $path"
}
```

---

## Guard Clauses and Early Returns

Validate preconditions at the top. Flatten nesting.

```powershell
# ❌ Deep nesting
function Process-File {
    param($path)
    if (Test-Path $path) {
        $content = Get-Content $path
        if ($content) {
            if ($content.Length -gt 0) {
                return $content | ConvertFrom-Json
            }
        }
    }
}

# ✅ Guard clauses
function Process-File {
    param([string]$path)
    if (-not (Test-Path $path))      { throw "Not found: $path" }
    $content = Get-Content $path -Raw
    if ([string]::IsNullOrEmpty($content)) { return $null }
    return $content | ConvertFrom-Json
}
```

---

## Function Organization

```powershell
# Functions go BEFORE the entry point (PS resolves names at parse time for scripts)
# Order: helpers → private logic → public API → entry point

# Private functions: prefix with internal comment or use verb-noun that signals internal use
function ConvertTo-FlatList { ... }   # private helper
function Invoke-MainLogic   { ... }   # main worker

# Entry point: keep minimal — just call functions
$result = Invoke-MainLogic -Input $Target
if ($Json) { $result | ConvertTo-Json -Depth 5 }
else       { Write-OK "Done: $($result.count) items" }
```

### Function naming

```powershell
# ✅ Approved verb + singular noun
function Get-HubSnapshot   { ... }
function Invoke-Harvest    { ... }
function Test-PathSafe     { ... }
function New-AuditSession  { ... }

# ❌ Avoid
function getSnapshot       { ... }   # no verb-noun
function Do-Stuff          { ... }   # vague verb
function ProcessAllFiles   { ... }   # no dash separator
```

Approved verbs: `Get-Verb` in pwsh lists all. Common: `Get`, `Set`, `New`, `Remove`, `Invoke`, `Test`, `Add`, `Update`, `Start`, `Stop`, `Build`, `Convert`, `Export`, `Import`.

---

## Path Handling

```powershell
# ✅ Script-relative paths — always safe
$HarvestScript = Join-Path $PSScriptRoot 'harvest_agent_sessions.ps1'
$CacheDir      = Join-Path $PSScriptRoot 'cache'
$ConfigFile    = Join-Path $PSScriptRoot '..\config\settings.json'

# ✅ User profile paths
$AppData = Join-Path $env:APPDATA 'arh'
$Home    = $env:USERPROFILE

# ✅ Literal paths for special characters
Get-Item -LiteralPath $path     # use -LiteralPath when path may contain [], *, ?
Remove-Item -LiteralPath $path

# ❌ Never hardcode user-specific paths in shared scripts
$Config = 'C:\Users\smoqu\.arh\config.json'   # breaks for other users

# ❌ Never bare relative paths
$Log = '.\logs\out.log'   # depends on cwd, not script location
```

---

## Spawning Background Processes

```powershell
# ✅ Hidden window, fire-and-forget
Start-Process pwsh -WindowStyle Hidden `
    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Param val"

# ✅ Hidden window, wait for completion
Start-Process pwsh -WindowStyle Hidden -Wait `
    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# ❌ cmd /c "pwsh ..." — spawns TWO windows (cmd.exe + pwsh.exe)
cmd /c "pwsh -File $script"

# ❌ Invoke-Expression for dynamic script paths — code injection risk
Invoke-Expression "& $scriptPath $args"

# ✅ Safe dynamic invocation
& $scriptPath @argsHash
```

---

## Structured Output (PSCustomObject)

Prefer `[PSCustomObject]` over hashtables for output — supports pipeline, formatting, and `ConvertTo-Json`.

```powershell
# ✅
$result = [PSCustomObject]@{
    timestamp = (Get-Date -Format 'o')
    status    = 'ok'
    count     = $items.Count
    items     = $items
}

# Consistent JSON serialization
$result | ConvertTo-Json -Depth 5 | Set-Content $outputFile -Encoding UTF8

# Consistent console output
Write-INFO "Processed $($result.count) items"
```
