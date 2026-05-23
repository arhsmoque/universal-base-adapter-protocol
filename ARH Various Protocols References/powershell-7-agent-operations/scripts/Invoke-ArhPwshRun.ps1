#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Command,

    [Parameter()]
    [string]$WorkingDirectory = (Get-Location).Path,

    [Parameter()]
    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 120,

    [Parameter()]
    [switch]$AllowWarnings,

    [Parameter()]
    [switch]$NoLearned,

    [Parameter()]
    [switch]$Json
)

$ErrorActionPreference = "Stop"

function New-RunResult {
    param(
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [object]$Guard,
        [int]$ExitCode = 0,
        [string]$Stdout = "",
        [string]$Stderr = "",
        [int]$DurationMs = 0,
        [string]$ErrorMessage = ""
    )

    [pscustomobject]@{
        status = $Status
        command = $Command
        working_directory = $WorkingDirectory
        guard = $Guard
        exit_code = $ExitCode
        stdout = $Stdout
        stderr = $Stderr
        stdout_lines = if ($Stdout) { @($Stdout -split "\r?\n" | Where-Object { $_ -ne "" }).Count } else { 0 }
        stderr_lines = if ($Stderr) { @($Stderr -split "\r?\n" | Where-Object { $_ -ne "" }).Count } else { 0 }
        duration_ms = $DurationMs
        error = $ErrorMessage
    }
}

function Write-RunResult {
    param(
        [Parameter(Mandatory)][object]$Result,
        [Parameter(Mandatory)][int]$ExitCode
    )

    if ($Json) {
        $Result | ConvertTo-Json -Depth 8
    }
    else {
        $Result
    }

    exit $ExitCode
}

try {
    $scriptRoot = Split-Path -Parent $PSCommandPath
    $guardScript = Join-Path $scriptRoot "Test-PwshCommand.ps1"
    if (-not (Test-Path -LiteralPath $guardScript)) {
        throw "Guard script not found: $guardScript"
    }

    $resolvedWorkingDirectory = Resolve-Path -LiteralPath $WorkingDirectory -ErrorAction Stop
    $guardArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $guardScript,
        "-Command", $Command,
        "-Json"
    )
    if ($NoLearned) {
        $guardArgs += "-NoLearned"
    }

    $guardOutput = & pwsh @guardArgs 2>&1
    $guardExit = $LASTEXITCODE
    $guardText = @($guardOutput) -join [Environment]::NewLine
    $guard = $null

    try {
        $guard = $guardText | ConvertFrom-Json -Depth 10
    }
    catch {
        $guard = [pscustomobject]@{
            status = "failure"
            raw = $guardText
            error = $_.Exception.Message
        }
    }

    if ($guardExit -eq 2 -or $guard.status -eq "error") {
        $result = New-RunResult -Status "blocked" -Command $Command -WorkingDirectory $resolvedWorkingDirectory.Path -Guard $guard -ExitCode 2
        Write-RunResult -Result $result -ExitCode 2
    }

    if (($guardExit -eq 1 -or $guard.status -eq "warn") -and -not $AllowWarnings) {
        $result = New-RunResult -Status "blocked" -Command $Command -WorkingDirectory $resolvedWorkingDirectory.Path -Guard $guard -ExitCode 1
        Write-RunResult -Result $result -ExitCode 1
    }

    if ($guardExit -gt 2 -or $guard.status -eq "failure") {
        $result = New-RunResult -Status "guard_failure" -Command $Command -WorkingDirectory $resolvedWorkingDirectory.Path -Guard $guard -ExitCode 3
        Write-RunResult -Result $result -ExitCode 3
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $wrappedCommand = @"
`$ErrorActionPreference = 'Stop'
try {
    & {
$Command
    }
    if (`$null -ne `$LASTEXITCODE) {
        exit `$LASTEXITCODE
    }
    exit 0
}
catch {
    Write-Error `$_.Exception.Message
    exit 1
}
"@

    $processInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $processInfo.FileName = "pwsh"
    $processInfo.ArgumentList.Add("-NoProfile")
    $processInfo.ArgumentList.Add("-ExecutionPolicy")
    $processInfo.ArgumentList.Add("Bypass")
    $processInfo.ArgumentList.Add("-Command")
    $processInfo.ArgumentList.Add($wrappedCommand)
    $processInfo.WorkingDirectory = $resolvedWorkingDirectory.Path
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $processInfo
    [void]$process.Start()

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $completed = $process.WaitForExit($TimeoutSeconds * 1000)

    if (-not $completed) {
        $process.Kill($true)
        $process.WaitForExit()
        $stopwatch.Stop()
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $result = New-RunResult -Status "timeout" -Command $Command -WorkingDirectory $resolvedWorkingDirectory.Path -Guard $guard -ExitCode 124 -Stdout $stdout -Stderr $stderr -DurationMs ([int]$stopwatch.ElapsedMilliseconds) -ErrorMessage "Command exceeded TimeoutSeconds=$TimeoutSeconds."
        Write-RunResult -Result $result -ExitCode 124
    }

    $stopwatch.Stop()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
    $status = if ($exitCode -eq 0) { "success" } else { "failed" }
    $result = New-RunResult -Status $status -Command $Command -WorkingDirectory $resolvedWorkingDirectory.Path -Guard $guard -ExitCode $exitCode -Stdout $stdout -Stderr $stderr -DurationMs ([int]$stopwatch.ElapsedMilliseconds)

    if ($exitCode -eq 0) {
        Write-RunResult -Result $result -ExitCode 0
    }

    Write-RunResult -Result $result -ExitCode 2
}
catch {
    $result = New-RunResult -Status "runner_failure" -Command $Command -WorkingDirectory $WorkingDirectory -Guard $null -ExitCode 3 -ErrorMessage $_.Exception.Message
    Write-RunResult -Result $result -ExitCode 3
}
