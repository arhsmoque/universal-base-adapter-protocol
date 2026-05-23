#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(ParameterSetName = "Command", Mandatory)]
    [string]$Command,

    [Parameter(ParameterSetName = "Path", Mandatory)]
    [string]$Path,

    [Parameter()]
    [switch]$Json,

    [Parameter()]
    [switch]$NoLearned,

    [Parameter()]
    [ValidateSet("pwsh", "python", "any")]
    [string]$Language = "pwsh"
)

$ErrorActionPreference = "Stop"

$DB_SCRIPT = 'D:\00_ARH\.ARH-AGENT-ENV\_env-mgmt\env\scripts\pwsh_guard_db.py'

function New-Finding {
    param(
        [Parameter(Mandatory)][ValidateSet("error", "warn", "note")][string]$Severity,
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$AgentAction,
        [string]$Source = 'static'
    )
    [pscustomobject]@{
        severity = $Severity
        id = $Id
        message = $Message
        agent_action = $AgentAction
        source = $Source
    }
}

function Get-LearnedPatterns {
    if (-not (Test-Path -LiteralPath $DB_SCRIPT)) {
        Write-Verbose "Learned pattern DB helper not found: $DB_SCRIPT"
        return @()
    }

    try {
        $raw = & python $DB_SCRIPT get-active-patterns $Language 2>$null
        $rawText = @($raw) -join [Environment]::NewLine
        if ([string]::IsNullOrWhiteSpace($rawText)) {
            return @()
        }
        $patterns = $rawText | ConvertFrom-Json -Depth 10
        return $patterns
    } catch {
        Write-Verbose "Could not load learned patterns: $($_.Exception.Message)"
        return @()
    }
}

try {
    if ($PSCmdlet.ParameterSetName -eq "Path") {
        $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        $text = Get-Content -LiteralPath $resolved.Path -Raw -ErrorAction Stop
        $target = $resolved.Path
    }
    else {
        $text = $Command
        $target = "<command>"
    }

    $findings = [System.Collections.Generic.List[object]]::new()

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $findings.Add((New-Finding error "not-pwsh7" "Current host is not PowerShell 7+." "Run this guard under pwsh 7+.")) | Out-Null
    }

    if ($text -match '(?im)(^|[;&|]\s*)powershell(\.exe)?\b') {
        $findings.Add((New-Finding error "legacy-powershell" "Command references the legacy Windows PowerShell executable." "Use pwsh unless explicitly testing Windows PowerShell 5.1.")) | Out-Null
    }

    if ($target -ne "<command>") {
        if ($text -notmatch '(?m)^#Requires\s+-Version\s+7(\.0)?') {
            $findings.Add((New-Finding warn "missing-requires-version" "Script does not declare #Requires -Version 7.0." "Add #Requires -Version 7.0 at the top of ARH PowerShell scripts.")) | Out-Null
        }
        if ($text -notmatch '\$ErrorActionPreference\s*=\s*["'']Stop["'']') {
            $findings.Add((New-Finding warn "missing-erroractionpreference" "Script does not set ErrorActionPreference to Stop." "Set `$ErrorActionPreference = `"Stop`" near the top for predictable try/catch behavior.")) | Out-Null
        }
    }

    $backslashQuotePattern = [regex]::Escape(([char]92).ToString() + [char]34)

    $patterns = @(
        @{ id = "bash-ls"; rx = '(?m)(^|[;&|]\s*)ls\s+-[A-Za-z]*[al][A-Za-z]*\b'; action = "Use Get-ChildItem -Force or Get-ChildItem with explicit parameters."; message = "Bash-style ls flags detected." },
        @{ id = "bash-cat"; rx = '(?m)(^|[;&|]\s*)cat\s+'; action = "Use Get-Content, usually Get-Content -Raw for whole-file reads."; message = "cat alias/style detected in generated PowerShell command." },
        @{ id = "bash-grep"; rx = '(?m)(^|[;&|]\s*)grep\s+'; action = "Use Select-String -Pattern instead of grep in pwsh."; message = "grep detected in a PowerShell command." },
        @{ id = "bash-mkdir-p"; severity = "error"; rx = '(?im)(^|[;&|]\s*)mkdir\s+(?:-[A-Za-z]*p[A-Za-z]*|--parents)\b'; action = "Use New-Item -ItemType Directory -Force -Path <path>[,<path>] | Out-Null."; message = "Bash mkdir -p syntax detected. In pwsh, mkdir is an alias for New-Item and does not support GNU mkdir semantics." },
        @{ id = "bash-touch"; rx = '(?im)(^|[;&|]\s*)touch\s+'; action = "Use New-Item -ItemType File -Force -Path <path> | Out-Null, or Set-ItemProperty only when timestamp semantics are required."; message = "touch detected in a PowerShell command." },
        @{ id = "bash-cp-recursive"; rx = '(?im)(^|[;&|]\s*)cp\s+-(?:[A-Za-z]*r[A-Za-z]*|[A-Za-z]*R[A-Za-z]*)\b'; action = "Use Copy-Item -Recurse -LiteralPath <source> -Destination <destination>."; message = "Bash-style recursive cp flags detected." },
        @{ id = "bash-mv"; rx = '(?im)(^|[;&|]\s*)mv\s+'; action = "Use Move-Item -LiteralPath <source> -Destination <destination> after verifying paths; back up durable state to _history when needed."; message = "mv detected in a PowerShell command." },
        @{ id = "bash-chmod"; rx = '(?im)(^|[;&|]\s*)chmod\s+'; action = "Do not use chmod in pwsh. Use Windows ACL tooling when permissions must change, or omit chmod for normal PowerShell scripts."; message = "chmod detected in a PowerShell command." },
        @{ id = "bash-sed"; rx = '(?im)(^|[;&|]\s*)sed\s+'; action = "Use Get-Content with -replace, Select-String, or a short PowerShell/Python script for text transformation."; message = "sed detected in a PowerShell command." },
        @{ id = "bash-awk"; rx = '(?im)(^|[;&|]\s*)awk\s+'; action = "Use Select-String, ConvertFrom-Csv, PowerShell objects, or a short Python script instead of awk in pwsh."; message = "awk detected in a PowerShell command." },
        @{ id = "python3-libreoffice-trap"; severity = "error"; rx = '(?im)(^|[;&|]\s*)python3(?:\.exe)?\b'; action = "Use python script.py or python -; never python3 in this ARH Windows environment."; message = "python3 detected; this environment reserves plain python for the correct interpreter and avoids the LibreOffice interpreter trap." },
        @{ id = "cmd-dir-switch"; rx = '(?im)(^|[;&|]\s*)dir\s+/[a-z]'; action = "Use Get-ChildItem with PowerShell parameters, e.g. Get-ChildItem -Force."; message = "CMD-style dir switch detected." },
        @{ id = "cmd-set-env"; rx = '(?im)(^|[;&|]\s*)set\s+[A-Za-z_][A-Za-z0-9_]*='; action = "Use `$env:NAME = 'value' in PowerShell."; message = "CMD-style environment assignment detected." },
        @{ id = "bash-env-prefix"; rx = '(?m)(^|[;&|]\s*)[A-Za-z_][A-Za-z0-9_]*=.*\s+\w+'; action = "Use `$env:NAME = 'value'; command` in PowerShell."; message = "Bash-style environment prefix detected." },
        @{ id = "git-commit-single-quote-message"; rx = '(?im)\bgit\s+commit\s+-m\s+''[^'']*"[^'']*'''; action = 'Use outer double quotes and inner single quotes, e.g. git commit -m "feat: integrated ''user login'' module".'; message = "Git commit message uses Bash-style outer single quotes around text containing double quotes." },
        @{ id = "bash-double-quote-escape"; rx = $backslashQuotePattern; action = 'In PowerShell double-quoted strings, escape embedded double quotes with a backtick, or restructure with outer double and inner single quotes.'; message = "Bash-style backslash double-quote escape detected." },
        @{ id = "unix-rm-rf"; rx = '(?m)(^|[;&|]\s*)rm\s+-rf\b'; action = "Use Remove-Item -LiteralPath after resolving and verifying the target root."; message = "rm -rf detected." },
        @{ id = "native-status"; rx = '(?m)\$\?\s*[-=]'; action = "Use `$LASTEXITCODE` to check native executable status."; message = "Potential native-command status check with `$?`." }
    )

    foreach ($pattern in $patterns) {
        if ($text -match $pattern.rx) {
            $severity = if ($pattern.severity) { $pattern.severity } else { "warn" }
            $findings.Add((New-Finding $severity $pattern.id $pattern.message $pattern.action 'static')) | Out-Null
        }
    }

    if ($text -match '(?m)Remove-Item\s+.*-Recurse' -and $text -notmatch 'Resolve-Path|\.StartsWith\(|relative_to|Test-Path') {
        $findings.Add((New-Finding error "unsafe-recursive-remove" "Recursive Remove-Item appears without visible target verification." "Resolve the absolute target, verify it is under the intended root, then use Remove-Item -LiteralPath." 'static')) | Out-Null
    }

    if ($text -match '(?im)(^|[;&|]\s*)Move-Item\s+' -and $text -notmatch 'Resolve-Path|Test-Path|_history') {
        $findings.Add((New-Finding warn "move-without-visible-guard" "Move-Item appears without visible path/backup guard." "Verify source/destination and use _history backup when moving durable state." 'static')) | Out-Null
    }

    if ($text -match '(?m)Start-Process\s+' -and $text -notmatch '-WindowStyle\s+Hidden' -and $text -match '(?i)background|daemon|server|watch|poll|service|helper') {
        $findings.Add((New-Finding warn "visible-background-process" "Background/helper Start-Process may open a visible window." "Pass -WindowStyle Hidden for background helpers unless a visible interactive window is required." 'static')) | Out-Null
    }

    # -- Learned patterns from DuckDB ----------------------------------------
    if (-not $NoLearned) {
        $learned = Get-LearnedPatterns
        foreach ($lp in $learned) {
            $rx = if ($lp.is_regex) { $lp.match_text } else { [regex]::Escape($lp.match_text) }
            $triggers = if ($lp.trigger_on) { $lp.trigger_on } else { 'script' }

            # Skip if trigger_on is 'command' and we're checking a script file
            if ($triggers -eq 'command' -and $target -ne '<command>') { continue }
            # Skip if trigger_on is 'script' and we're checking a raw command
            if ($triggers -eq 'script' -and $target -eq '<command>') { continue }

            try {
                if ($text -match $rx) {
                    $severity = if ($lp.severity -in @("error", "warn", "note")) { $lp.severity } else { "warn" }
                    $findings.Add((New-Finding $severity "learned-$($lp.id)" $lp.message $lp.agent_action 'learned')) | Out-Null
                }
            } catch {
                Write-Verbose "Learned pattern id=$($lp.id) regex failed: $($_.Exception.Message)"
            }
        }
    }

    $status = if ($findings | Where-Object severity -eq "error") { "error" } elseif ($findings | Where-Object severity -eq "warn") { "warn" } else { "ok" }
    $result = [pscustomobject]@{
        status = $status
        target = $target
        shell = "PowerShell $($PSVersionTable.PSVersion)"
        findings = @($findings)
    }

    if ($Json) {
        $result | ConvertTo-Json -Depth 6
    }
    else {
        $result
    }

    if ($status -eq "error") { exit 2 }
    if ($status -eq "warn") { exit 1 }
    exit 0
}
catch {
    $result = [pscustomobject]@{
        status = "failure"
        target = if ($Path) { $Path } else { "<command>" }
        error = $_.Exception.Message
    }
    if ($Json) {
        $result | ConvertTo-Json -Depth 4
    }
    else {
        $result
    }
    exit 3
}
