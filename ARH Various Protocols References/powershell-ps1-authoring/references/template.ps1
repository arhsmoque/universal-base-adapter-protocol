#Requires -Version 7.0
<#
.SYNOPSIS
  [One-line summary — imperative verb, under 80 chars]

.DESCRIPTION
  [Multi-line description of what this script does and why it exists.]

.PARAMETER Target
  [Describe Target. What values are valid.]

.PARAMETER Format
  Output format: 'text' (default) or 'json'.

.PARAMETER WhatIf
  Show what would happen without making changes.

.PARAMETER Json
  Emit machine-readable JSON result instead of colored console output.

.EXAMPLE
  pwsh -File .\ScriptName.ps1 -Target "value"

.EXAMPLE
  pwsh -File .\ScriptName.ps1 -Target "value" -Json
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Target,

    [Parameter()]
    [ValidateSet('text','json')]
    [string]$Format = 'text',

    [Parameter()][switch]$WhatIf,
    [Parameter()][switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ScriptDir = $PSScriptRoot

# -- Helpers ------------------------------------------------------------------

function Write-OK   ($m) { Write-Host "[OK]   $m" -ForegroundColor Green  }
function Write-INFO ($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan   }
function Write-WARN ($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-ERR  ($m) { Write-Host "[ERR]  $m" -ForegroundColor Red    }

# -- Functions ----------------------------------------------------------------

function Invoke-MainLogic {
    param([string]$Input)

    # TODO: implement main logic

    return [PSCustomObject]@{
        status  = 'ok'
        message = "Processed: $Input"
        data    = $null
    }
}

# -- Entry point --------------------------------------------------------------

if ($WhatIf) {
    Write-INFO "[WhatIf] Would process: $Target"
    exit 0
}

try {
    $result = Invoke-MainLogic -Input $Target

    if ($Json) {
        $result | ConvertTo-Json -Depth 5 -Compress
    } else {
        Write-OK $result.message
    }
} catch {
    $err = $_
    if ($Json) {
        [PSCustomObject]@{ status='error'; message="$err" } | ConvertTo-Json -Compress
    } else {
        Write-ERR "Failed: $err"
    }
    exit 1
}
