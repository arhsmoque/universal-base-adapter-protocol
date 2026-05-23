# DEBUGGING — Common PS1 Failure Modes

Covers: silent failures, $ErrorActionPreference traps, path issues, scope problems, encoding failures, external command errors.

---

## Diagnosis Checklist

When a script fails silently or behaves unexpectedly:

1. Add `$ErrorActionPreference = 'Stop'` at top if missing
2. Add `Set-StrictMode -Version Latest` to catch uninitialized vars
3. Run with `-Verbose` to see cmdlet activity
4. Run with `-Debug` to trace function calls
5. Check `$LASTEXITCODE` after any native command

---

## Silent Failure Patterns

### Missing $ErrorActionPreference

```powershell
# ❌ Default is 'Continue' — errors print to console but script keeps running
Get-Content 'nonexistent.json' | ConvertFrom-Json
Write-Host "This runs even though Get-Content failed"

# ✅ Stop on first error
$ErrorActionPreference = 'Stop'
Get-Content 'nonexistent.json' | ConvertFrom-Json   # terminates here
```

### $? is unreliable for native commands

```powershell
# ❌ $? only reflects if PS cmdlets "thought" they succeeded — not native tools
git push
if ($?) { Write-Host "ok" }   # may be $true even if git push failed

# ✅ Use $LASTEXITCODE for native tools
git push
if ($LASTEXITCODE -ne 0) { Write-ERR "git push failed (exit $LASTEXITCODE)"; exit 1 }
```

### $_ overwritten in catch

```powershell
# ❌ $_ is the current error object but gets overwritten by the next pipeline/cmdlet
try { bad-command }
catch {
    Write-Host "Got error"    # $_ is now gone, overwritten by Write-Host state
    Write-Host "Error was: $_"  # empty or wrong
}

# ✅ Capture immediately
try { bad-command }
catch {
    $err = $_                 # save before anything else
    Write-Host "Got error"
    Write-Host "Error was: $err"
}
```

---

## Path and cwd Issues

### Script breaks when cwd differs from script location

```powershell
# ❌ Relative paths depend on whatever cwd is at invocation time
$config = Get-Content '.\config.json'

# ✅ Always anchor to script location
$config = Get-Content (Join-Path $PSScriptRoot 'config.json')
```

### Diagnosing path resolution

```powershell
Write-Host "PSScriptRoot: $PSScriptRoot"
Write-Host "cwd: $(Get-Location)"
Write-Host "Resolved path: $(Resolve-Path $path -ErrorAction SilentlyContinue)"
```

### Special characters in paths

```powershell
# ❌ Get-Item treats [ ] * ? as wildcards
Get-Item 'C:\path\file[1].txt'   # fails — brackets treated as wildcard

# ✅ Use -LiteralPath for paths with special chars
Get-Item -LiteralPath 'C:\path\file[1].txt'
Remove-Item -LiteralPath $path
```

### DuckDB .read path forward slashes

```powershell
# DuckDB on Windows strips backslashes from .read paths
# ❌ & duckdb $DB ".read $sqlPath"    → C:Userssmoqu...

# ✅ Convert to forward slashes before passing
$sqlPathFwd = $sqlPath -replace '\\', '/'
& duckdb $DB ".read $sqlPathFwd"
```

---

## Scope Issues

### Script scope vs function scope

```powershell
$script:State = 'idle'   # script-scope variable — visible to all functions in script

function Set-State {
    param([string]$s)
    $script:State = $s   # must use $script: to write to script scope
    # bare $State = $s would create a LOCAL variable, not update script scope
}
```

### Variables in ForEach-Object / Where-Object

```powershell
# ❌ Variable modified inside pipeline doesn't propagate out
$count = 0
$items | ForEach-Object { $count++ }   # $count stays 0 outside

# ✅ Use a List or accumulate differently
$results = [System.Collections.Generic.List[string]]::new()
$items | ForEach-Object { $results.Add($_) }
```

### Dot-sourcing vs direct invocation

```powershell
# Direct invocation runs in child scope — function defs don't persist
.\script.ps1

# Dot-sourcing runs in current scope — functions and vars persist
. .\script.ps1
```

---

## Encoding Issues

### BOM and special characters

```powershell
# Always write files with explicit UTF-8 (no BOM for compatibility)
$content | Set-Content -Path $file -Encoding UTF8

# ConvertTo-Json + Set-Content instead of Out-File (Out-File adds BOM in PS5)
$data | ConvertTo-Json -Depth 5 | Set-Content -Path $file -Encoding UTF8
```

### Reading files with unknown encoding

```powershell
# Explicit encoding for JSON/config files
Get-Content $file -Raw -Encoding UTF8

# Check encoding of a file (requires System.IO)
$bytes = [System.IO.File]::ReadAllBytes($file)
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-WARN "File has UTF-8 BOM: $file"
}
```

---

## External Command Failures

### Start-Process and WindowStyle Hidden

```powershell
# ❌ Visible window flash
cmd /c "pwsh -File script.ps1"

# ✅ Hidden, fire-and-forget
Start-Process pwsh -WindowStyle Hidden `
    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$script`""

# ✅ Hidden, wait for exit code
$p = Start-Process pwsh -WindowStyle Hidden -Wait -PassThru `
    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
if ($p.ExitCode -ne 0) { Write-ERR "Script failed: exit $($p.ExitCode)" }
```

### Scheduled task not running

Common causes:
1. Script path has spaces — wrap in extra quotes in `-Argument`
2. Working directory wrong — task has no cwd, use `$PSScriptRoot` in script
3. Execution policy block — add `-ExecutionPolicy Bypass` to task action
4. Window hidden but task fails silently — redirect stderr to log:
   ```
   pwsh -File "script.ps1" *>> "C:\logs\task.log"
   ```

---

## FileSystemWatcher Events Not Firing

```powershell
# ❌ Events fire but nothing happens if EnableRaisingEvents is $false
$w.EnableRaisingEvents = $true   # must be set AFTER registering event handlers

# ❌ Script exits immediately — watcher dies with process
while ($true) { Start-Sleep -Seconds 60 }   # ✅ Keep alive loop

# ❌ Event scriptblock can't access outer variables directly
# ✅ Use $script: scope or pass via -MessageData
Register-ObjectEvent -InputObject $w -EventName Changed -MessageData $HarvestScript `
    -Action {
        $scriptPath = $Event.MessageData
        Start-Process pwsh -WindowStyle Hidden -ArgumentList "... $scriptPath ..."
    }
```

---

## ConvertFrom-Json Depth Issues

```powershell
# ❌ Default depth is 1024 in PS7 but ConvertTo-Json default is 2 — nested objects become strings
$obj | ConvertTo-Json | ConvertFrom-Json   # loses deep structure

# ✅ Always specify depth for nested structures
$obj | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10
```

---

## AddRange Type Mismatch (List<T>)

```powershell
# ❌ Recursive function returns System.Object[], AddRange<PSCustomObject> rejects it
$list.AddRange((Get-Children -Node $child))

# ✅ Iterate and Add individually
foreach ($item in (Get-Children -Node $child)) {
    $list.Add($item)
}
```
