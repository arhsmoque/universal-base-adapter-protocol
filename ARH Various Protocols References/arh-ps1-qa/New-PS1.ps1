#Requires -Version 7.0
<#
.SYNOPSIS
  Scaffold a new ARH-compliant PowerShell 7 script from the canonical template.

.DESCRIPTION
  Generates a .ps1 file with the correct ARH script anatomy:
  #Requires, comment-based help, typed param block, status helpers,
  error handling, and a placeholder entry point.

  The output file is ready to run and passes arh-ps1-qa lint immediately.

.PARAMETER Name
  Script name without .ps1 extension. Should be Verb-Noun format.
  Examples: Sync-AgentData, Get-HubReport, Invoke-CleanupRoutine

.PARAMETER Synopsis
  One-line description for the .SYNOPSIS help block.

.PARAMETER Description
  Optional multi-line description for the .DESCRIPTION block.

.PARAMETER OutputDir
  Directory to write the script. Defaults to current directory.

.PARAMETER Force
  Overwrite if file already exists.

.EXAMPLE
  pwsh -File New-PS1.ps1 -Name "Sync-AgentData" -Synopsis "Syncs session data to obs DB"

.EXAMPLE
  pwsh -File New-PS1.ps1 -Name "Get-HubReport" -Synopsis "Hub health report" `
      -Description "Queries arh-obs.duckdb and formats status." `
      -OutputDir D:\00_ARH\01_homelab\00_agent-hub\env\scripts
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Synopsis,

    [Parameter()]
    [string]$Description = '',

    [Parameter()]
    [string]$OutputDir = (Get-Location).Path,

    [Parameter()][switch]$Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot

function Write-OK   ($m) { Write-Host "[OK]   $m" -ForegroundColor Green  }
function Write-INFO ($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan   }
function Write-ERR  ($m) { Write-Host "[ERR]  $m" -ForegroundColor Red    }

# -- Validate name follows Verb-Noun convention -------------------------------

function Test-ApprovedVerb {
    param([string]$ScriptName)
    if ($ScriptName -notmatch '^([A-Z][a-z]+)-([A-Z][A-Za-z]+)$') {
        Write-WARN "Name '$ScriptName' does not follow Verb-Noun convention (e.g. Get-HubReport, Invoke-Sync)"
    } else {
        $verb = ($ScriptName -split '-')[0]
        $approvedVerbs = Get-Verb | Select-Object -ExpandProperty Verb
        if ($verb -notin $approvedVerbs) {
            Write-WARN "'$verb' is not an approved PowerShell verb. Run Get-Verb for the full list."
        }
    }
}

function Write-WARN ($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }

# -- Template generation ------------------------------------------------------

function New-ScriptContent {
    param([string]$ScriptName, [string]$ScriptSynopsis, [string]$ScriptDescription)

    $ts   = Get-Date -Format 'yyyy-MM-dd'
    $desc = if ($ScriptDescription) { $ScriptDescription } else { "[Describe what this script does and why it exists.]" }
    $mainFn = "Invoke-$($ScriptName -replace '^.*?-','')"

    return @"
#Requires -Version 7.0
<#
.SYNOPSIS
  $ScriptSynopsis

.DESCRIPTION
  $desc

.PARAMETER Target
  [Describe Target. What values are valid.]

.PARAMETER WhatIf
  Show what would happen without making changes.

.PARAMETER Json
  Emit machine-readable JSON result.

.EXAMPLE
  pwsh -File .\$ScriptName.ps1 -Target "value"

.NOTES
  Created: $ts
#>
param(
    [Parameter(Mandatory=`$true)]
    [ValidateNotNullOrEmpty()]
    [string]`$Target,

    [Parameter()][switch]`$WhatIf,
    [Parameter()][switch]`$Json
)

`$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
`$ScriptDir = `$PSScriptRoot

# -- Helpers ------------------------------------------------------------------

function Write-OK   (`$m) { Write-Host "[OK]   `$m" -ForegroundColor Green  }
function Write-INFO (`$m) { Write-Host "[INFO] `$m" -ForegroundColor Cyan   }
function Write-WARN (`$m) { Write-Host "[WARN] `$m" -ForegroundColor Yellow }
function Write-ERR  (`$m) { Write-Host "[ERR]  `$m" -ForegroundColor Red    }

# -- Functions ----------------------------------------------------------------

function $mainFn {
    param([string]`$Input)

    # TODO: implement logic

    return [PSCustomObject]@{
        status  = 'ok'
        message = "Processed: `$Input"
        data    = `$null
    }
}

# -- Entry point --------------------------------------------------------------

if (`$WhatIf) {
    Write-INFO "[WhatIf] Would process: `$Target"
    exit 0
}

try {
    `$result = $mainFn -Input `$Target

    if (`$Json) {
        `$result | ConvertTo-Json -Depth 5 -Compress
    } else {
        Write-OK `$result.message
    }
} catch {
    `$err = `$_
    if (`$Json) {
        [PSCustomObject]@{ status='error'; message="`$err" } | ConvertTo-Json -Compress
    } else {
        Write-ERR "Failed: `$err"
    }
    exit 1
}
"@
}

# -- Entry point --------------------------------------------------------------

Test-ApprovedVerb -ScriptName $Name

$outputPath = Join-Path $OutputDir "$Name.ps1"

if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
    Write-ERR "File already exists: $outputPath (use -Force to overwrite)"
    exit 1
}

$content = New-ScriptContent -ScriptName $Name -ScriptSynopsis $Synopsis -ScriptDescription $Description
Set-Content -Path $outputPath -Value $content -Encoding UTF8

Write-OK "Created: $outputPath"
Write-INFO "Next: pwsh -File arh-ps1-qa.ps1 -Path `"$outputPath`" -Mode lint"
