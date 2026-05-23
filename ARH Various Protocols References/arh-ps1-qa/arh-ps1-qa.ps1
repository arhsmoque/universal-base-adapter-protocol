#Requires -Version 7.0
<#
.SYNOPSIS
  ARH PowerShell QA pipeline — lint, design check, security audit.

.DESCRIPTION
  Wraps PSScriptAnalyzer with ARH-specific checks. Analyzes .ps1 files for
  correctness, security, style, and ARH compliance rules (KF-17, path anchoring,
  error preference, version requirement, etc.).

  Modes:
    lint   — PSScriptAnalyzer errors + warnings + ARH compliance checks
    design — Structural/style rules + ARH anatomy checks
    audit  — Security rules only + ARH security patterns
    full   — All of the above combined

.PARAMETER Path
  File or directory to analyze. Defaults to current directory.

.PARAMETER Mode
  Analysis mode: lint | design | audit | full. Default: lint.

.PARAMETER Json
  Output structured JSON instead of colored console output.

.PARAMETER Fix
  Auto-fix PSScriptAnalyzer correctable issues (lint mode only).
  Does NOT auto-fix security findings.

.EXAMPLE
  pwsh -File arh-ps1-qa.ps1 -Path .\script.ps1

.EXAMPLE
  pwsh -File arh-ps1-qa.ps1 -Path .\scripts -Mode full -Json

.EXAMPLE
  pwsh -File arh-ps1-qa.ps1 -Path .\script.ps1 -Mode lint -Fix
#>
param(
    [Parameter()]
    [string]$Path = (Get-Location).Path,

    [Parameter()]
    [ValidateSet('lint','design','audit','full')]
    [string]$Mode = 'lint',

    [Parameter()][switch]$Json,
    [Parameter()][switch]$Fix
)

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot

# -- Helpers ------------------------------------------------------------------

function Write-OK   ($m) { Write-Host "[OK]   $m" -ForegroundColor Green  }
function Write-INFO ($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan   }
function Write-WARN ($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-ERR  ($m) { Write-Host "[ERR]  $m" -ForegroundColor Red    }

# -- PSScriptAnalyzer setup ---------------------------------------------------

function Assert-PSSAInstalled {
    if (-not (Get-Module PSScriptAnalyzer -ListAvailable -ErrorAction SilentlyContinue)) {
        Write-ERR "PSScriptAnalyzer not installed."
        Write-INFO "Run: Install-Module PSScriptAnalyzer -Scope CurrentUser -Force"
        exit 3
    }
}

$PssaConfig  = Join-Path $ScriptDir 'pssa-config.psd1'
$SecurityRules = @(
    'PSAvoidUsingInvokeExpression',
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidUsingUsernameAndPasswordParams',
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    'PSAvoidUsingComputerNameHardcoded',
    'PSUsePSCredentialType'
)
$DesignRules = @(
    'PSAvoidUsingCmdletAliases',
    'PSAvoidDefaultValueSwitchParameter',
    'PSMisleadingBacktick',
    'PSUseDeclaredVarsMoreThanAssignments',
    'PSAvoidGlobalVars',
    'PSProvideCommentHelp',
    'PSUseCorrectCasing',
    'PSReviewUnusedParameter',
    'PSAvoidTrailingWhitespace'
)

# -- ARH custom checks --------------------------------------------------------

function Invoke-ArhChecks {
    param([string]$FilePath)

    $lines   = Get-Content -LiteralPath $FilePath -ErrorAction SilentlyContinue
    $content = $lines -join "`n"
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    $addFinding = {
        param($line, $sev, $rule, $msg)
        $findings.Add([PSCustomObject]@{
            RuleName   = "ARH-$rule"
            Severity   = $sev
            Line       = $line
            Message    = $msg
            ScriptName = $FilePath
            Source     = 'arh'
        })
    }

    # ARH-001: Missing #Requires -Version 7.0
    if ($content -notmatch '#Requires\s+-Version\s+7') {
        & $addFinding 1 'Warning' '001' 'Missing #Requires -Version 7.0'
    }

    # ARH-002: Missing $ErrorActionPreference = Stop
    if ($content -notmatch '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]') {
        & $addFinding 1 'Warning' '002' 'Missing $ErrorActionPreference = ''Stop'''
    }

    # ARH-003: Legacy powershell.exe usage
    if ($content -match 'powershell\.exe') {
        $lineNum = ($lines | Select-String 'powershell\.exe' | Select-Object -First 1).LineNumber
        & $addFinding $lineNum 'Error' '003' 'Uses powershell.exe — use pwsh instead'
    }

    # ARH-004: Bare relative paths (not rooted in $PSScriptRoot or $env:)
    $relMatches = $lines | Select-String '["''][.\\]{1,2}[^/\\]' | Where-Object {
        $_.Line -notmatch '\$PSScriptRoot' -and
        $_.Line -notmatch '\$env:' -and
        $_.Line -notmatch '^\s*#'
    }
    foreach ($m in $relMatches | Select-Object -First 3) {
        & $addFinding $m.LineNumber 'Warning' '004' "Possible bare relative path — use Join-Path `$PSScriptRoot: $($m.Line.Trim())"
    }

    # ARH-005: KF-17 — Get-ChildItem -Recurse near ARH junction
    $kfMatches = $lines | Select-String 'Get-ChildItem.*-Recurse' | Where-Object {
        $_.Line -match 'D:\\ARH|D:\\00_ARH|\\ARH\\' -or
        ($_.Line -match 'Get-ChildItem' -and $_.Line -match '-Recurse' -and $_.Line -match '\$.*Root|\$.*Hub|\$.*Dir')
    }
    foreach ($m in $kfMatches) {
        & $addFinding $m.LineNumber 'Error' '005' "KF-17: Get-ChildItem -Recurse risks D:\ARH junction walk — use arh-gateway MCP"
    }

    # ARH-006: cmd /c spawning
    $cmdMatches = $lines | Select-String 'cmd\s*/c|cmd\.exe' | Where-Object { $_.Line -notmatch '^\s*#' }
    foreach ($m in $cmdMatches) {
        & $addFinding $m.LineNumber 'Warning' '006' "cmd /c spawns visible windows — use Start-Process pwsh -WindowStyle Hidden"
    }

    # ARH-007: Hardcoded user path
    $userMatches = $lines | Select-String 'C:\\Users\\smoqu' | Where-Object { $_.Line -notmatch '^\s*#' }
    foreach ($m in $userMatches) {
        & $addFinding $m.LineNumber 'Warning' '007' "Hardcoded user path — use `$env:USERPROFILE"
    }

    return $findings
}

# -- Analysis runners ---------------------------------------------------------

function Invoke-PssaAnalysis {
    param([string]$TargetPath, [string[]]$Rules, [switch]$UseSettings, [switch]$AutoFix)

    $params = @{ Path = $TargetPath; Recurse = (Test-Path $TargetPath -PathType Container) }

    if ($AutoFix) { $params['Fix'] = $true }

    if ($UseSettings -and (Test-Path $PssaConfig)) {
        $params['Settings'] = $PssaConfig
    } elseif ($Rules) {
        $params['IncludeRule'] = $Rules
        $params['ExcludeRule'] = @('PSAvoidUsingWriteHost')
    }

    try {
        return Invoke-ScriptAnalyzer @params
    } catch {
        Write-WARN "PSSA error on $TargetPath : $_"
        return @()
    }
}

function Get-TargetFiles {
    param([string]$TargetPath)
    if (Test-Path $TargetPath -PathType Leaf) {
        return @($TargetPath)
    }
    return Get-ChildItem $TargetPath -Filter '*.ps1' -Recurse |
        Where-Object { $_.FullName -notmatch '\.archived|\.venv|node_modules|\.git' } |
        ForEach-Object { $_.FullName }
}

# -- Main analysis ------------------------------------------------------------

function Invoke-Analysis {
    param([string]$TargetPath, [string]$AnalysisMode, [switch]$AutoFix)

    Assert-PSSAInstalled

    $pssaFindings = [System.Collections.Generic.List[PSCustomObject]]::new()
    $arhFindings  = [System.Collections.Generic.List[PSCustomObject]]::new()

    $files = Get-TargetFiles -TargetPath $TargetPath
    if ($files.Count -eq 0) {
        Write-WARN "No .ps1 files found in: $TargetPath"
        return
    }

    if (-not $script:Json) { Write-INFO "Analyzing $($files.Count) file(s) — mode: $AnalysisMode" }

    # PSSA pass
    switch ($AnalysisMode) {
        'lint'   {
            $raw = Invoke-PssaAnalysis -TargetPath $TargetPath -UseSettings -AutoFix:$AutoFix
            foreach ($r in $raw) { $pssaFindings.Add($r) }
        }
        'design' {
            $raw = Invoke-PssaAnalysis -TargetPath $TargetPath -Rules $DesignRules
            foreach ($r in $raw) { $pssaFindings.Add($r) }
        }
        'audit'  {
            $raw = Invoke-PssaAnalysis -TargetPath $TargetPath -Rules $SecurityRules
            foreach ($r in $raw) { $pssaFindings.Add($r) }
        }
        'full'   {
            $raw = Invoke-PssaAnalysis -TargetPath $TargetPath -UseSettings
            foreach ($r in $raw) { $pssaFindings.Add($r) }
        }
    }

    # ARH checks pass (all modes)
    foreach ($file in $files) {
        foreach ($f in (Invoke-ArhChecks -FilePath $file)) {
            $arhFindings.Add($f)
        }
    }

    # Combine and classify
    $allFindings = @($pssaFindings) + @($arhFindings)
    $errors   = $allFindings | Where-Object { $_.Severity -eq 'Error'   }
    $warnings = $allFindings | Where-Object { $_.Severity -eq 'Warning' }
    $infos    = $allFindings | Where-Object { $_.Severity -eq 'Information' }

    $overallStatus = if ($errors.Count -gt 0)   { 'error' }
                     elseif ($warnings.Count -gt 0) { 'warn' }
                     else                            { 'ok' }

    return [PSCustomObject]@{
        mode            = $AnalysisMode
        overall_status  = $overallStatus
        files_analyzed  = $files.Count
        total_findings  = $allFindings.Count
        error_count     = ($errors   | Measure-Object).Count
        warning_count   = ($warnings | Measure-Object).Count
        info_count      = ($infos    | Measure-Object).Count
        pssa_findings   = @($pssaFindings | Select-Object RuleName,Severity,Line,Message,ScriptName)
        arh_findings    = @($arhFindings  | Select-Object RuleName,Severity,Line,Message,ScriptName)
    }
}

# -- Output -------------------------------------------------------------------

function Write-ConsoleReport {
    param($Report)

    Write-INFO "Files: $($Report.files_analyzed) | Mode: $($Report.mode) | Findings: $($Report.total_findings)"

    if ($Report.total_findings -eq 0) {
        Write-OK "No findings — script(s) clean."
        return
    }

    $all = @($Report.pssa_findings) + @($Report.arh_findings)

    foreach ($f in ($all | Where-Object { $_.Severity -eq 'Error' })) {
        Write-ERR "[$($f.ScriptName | Split-Path -Leaf):$($f.Line)] $($f.RuleName) — $($f.Message)"
    }
    foreach ($f in ($all | Where-Object { $_.Severity -eq 'Warning' })) {
        Write-WARN "[$($f.ScriptName | Split-Path -Leaf):$($f.Line)] $($f.RuleName) — $($f.Message)"
    }
    foreach ($f in ($all | Where-Object { $_.Severity -eq 'Information' })) {
        Write-INFO "[$($f.ScriptName | Split-Path -Leaf):$($f.Line)] $($f.RuleName) — $($f.Message)"
    }

    $statusColor = @{ ok='Green'; warn='Yellow'; error='Red' }[$Report.overall_status]
    Write-Host "`nStatus: $($Report.overall_status.ToUpper()) — $($Report.error_count) errors, $($Report.warning_count) warnings" `
        -ForegroundColor $statusColor
}

# -- Entry point --------------------------------------------------------------

$resolvedPath = if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path (Get-Location).Path $Path }

if (-not (Test-Path $resolvedPath)) {
    Write-ERR "Path not found: $resolvedPath"
    exit 3
}

try {
    $report = Invoke-Analysis -TargetPath $resolvedPath -AnalysisMode $Mode -AutoFix:$Fix

    if ($Json) {
        $report | ConvertTo-Json -Depth 6 -Compress
    } else {
        Write-ConsoleReport -Report $report
    }

    exit $(switch ($report.overall_status) { 'ok' { 0 } 'warn' { 1 } 'error' { 2 } })

} catch {
    $err = $_
    if ($Json) {
        [PSCustomObject]@{ status='error'; mode=$Mode; message="$err" } | ConvertTo-Json -Compress
    } else {
        Write-ERR "arh-ps1-qa failed: $err"
    }
    exit 3
}
