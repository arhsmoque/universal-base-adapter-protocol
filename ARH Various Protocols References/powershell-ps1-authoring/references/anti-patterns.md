# Anti-Patterns — PowerShell PS1 Catalog

Full catalog of bad patterns and their corrections. Organized by category.

---

## Error Handling

| Anti-Pattern | Correction | Why |
|---|---|---|
| Missing `$ErrorActionPreference = 'Stop'` | Add at top of every script | Default 'Continue' lets errors slip through silently |
| Empty catch block `catch { }` | Log + rethrow or handle | Silent swallowing hides bugs |
| `$?` for native command status | `$LASTEXITCODE -ne 0` | `$?` unreliable for external tools |
| `$_` used 2+ lines after catch open | `$err = $_` immediately | Next cmdlet/expression overwrites `$_` |
| Boolean flag set in catch, checked later | Handle entirely inside catch | Separates cause from effect; error info lost |
| `Try { cmd } catch { $ok = $false }` | `Try { cmd } catch { $err = $_; Write-WARN ...; throw }` | Flag approach loses error context |

---

## Parameters

| Anti-Pattern | Correction | Why |
|---|---|---|
| `[bool]$Flag` | `[switch]$Flag` | Switch doesn't require `$true`/`$false` at callsite; idiomatic |
| `param([string]$Path = ".\")` | `param([string]$Path = $PSScriptRoot)` | Relative defaults break when cwd differs |
| No validation on paths | `[ValidateScript({ Test-Path $_ })]` | Fail fast with clear message |
| No `[ValidateNotNullOrEmpty()]` on Mandatory strings | Add the attribute | Mandatory allows empty string; NullOrEmpty catches it |
| Hardcoded user path in default | `$env:USERPROFILE` or `$env:APPDATA` | Breaks for other users |
| `param()` after `$ErrorActionPreference` line | `param()` must be first non-comment statement | PS requires `param()` before any executable code |

---

## Paths

| Anti-Pattern | Correction | Why |
|---|---|---|
| `$path = ".\subdir\file.json"` | `$path = Join-Path $PSScriptRoot 'subdir\file.json'` | Relative breaks when cwd differs from script |
| String concatenation for paths | `Join-Path $base $sub` | Handles separators, normalizes slashes |
| `Get-Item $path` with wildcard chars in name | `Get-Item -LiteralPath $path` | `[` `]` treated as wildcards in non-literal |
| `C:\Users\smoqu\...` hardcoded | `$env:USERPROFILE` or parameterize | Breaks for other users; breaks in CI |
| `cd $dir; .\script.ps1` | Use `$PSScriptRoot` inside scripts | `cd` changes cwd for caller after script returns |

---

## Output

| Anti-Pattern | Correction | Why |
|---|---|---|
| `Write-Host $dataObject` | `Write-Output $dataObject` | Write-Host goes to info stream, not pipeline |
| `Write-Output "Status: ok"` for console messages | `Write-Host "Status: ok" -ForegroundColor Cyan` | Output messages clutter pipeline capture |
| No `-ForegroundColor` on status messages | Use ARH color helpers | Visually distinguishable at a glance |
| `return @($items)` from function | `return $items` or emit items one-by-one | Wrapping in array creates unwanted nesting |
| `Format-Table` inside function | Return objects; let caller format | Formatting in functions breaks pipeline composition |

---

## Process Spawning

| Anti-Pattern | Correction | Why |
|---|---|---|
| `cmd /c "pwsh -File script.ps1"` | `Start-Process pwsh -WindowStyle Hidden -ArgumentList "..."` | cmd.exe spawns visible window; double-process overhead |
| `Invoke-Expression "& $scriptPath $args"` | `& $scriptPath @argsHash` | Invoke-Expression with dynamic paths is injection risk |
| `Start-Process pwsh -ArgumentList "... $path ..."` (unquoted) | Wrap path in `\`"...\`"` in argument string | Spaces in path break argument parsing |
| No `-WindowStyle Hidden` for background tasks | Always add it | Prevents popup windows for scheduled/triggered tasks |
| Using `.Wait` on fire-and-forget tasks | Drop `-Wait` | Blocks event handler thread; causes debounce failures |

---

## Scope and Variables

| Anti-Pattern | Correction | Why |
|---|---|---|
| `$global:State = 'x'` | `$script:State = 'x'` | Global scope leaks across modules and sessions |
| Variable modified in `ForEach-Object` pipeline | Use `List<T>` + `.Add()` | Pipeline runs in child scope; outer var not updated |
| `$result` read before assigned (strict mode off) | `Set-StrictMode -Version Latest` catches this | Silent `$null` bugs |
| Function defined after its call | Define all functions before entry point | PS parses scripts top-to-bottom; undefined at parse time |

---

## Naming

| Anti-Pattern | Correction | Why |
|---|---|---|
| `function processFiles { }` | `function Invoke-FileProcess { }` | Verb-Noun convention; discoverable; approved verbs |
| `function Do-Stuff { }` | Specific verb: `Invoke-AgentSync` | `Do` is not an approved verb |
| Aliases in scripts: `ls`, `dir`, `%`, `?` | `Get-ChildItem`, `ForEach-Object`, `Where-Object` | Aliases differ by user/OS/profile; scripts must be deterministic |
| `$x`, `$tmp`, `$data` | Meaningful names: `$sessionPath`, `$rawJson` | Unreadable; impossible to audit |
| ALL_CAPS constants | `$MaxRetries`, `$DefaultPort` | PS convention is PascalCase for everything |

---

## Security

| Anti-Pattern | Correction | Why |
|---|---|---|
| `Invoke-Expression $input` | Restructure to direct calls or safe param expansion | Code injection if `$input` is user-controlled |
| `[string]$Password` param | `[SecureString]$Password` or `[PSCredential]$Credential` | Plain string credentials in memory and logs |
| `ConvertTo-SecureString 'pw' -AsPlainText -Force` without warning | Document why, consider a vault | Plaintext in source or logs |
| API keys in script literals | `$env:MY_API_KEY` or read from vault | Keys visible in source control and logs |
| `"$BaseDir\$UserInput"` passed to Get-Content | Validate/sanitize `$UserInput` before path concat | Path traversal: `..\..\sensitive.txt` |

---

## DuckDB-Specific (ARH)

| Anti-Pattern | Correction | Why |
|---|---|---|
| `& duckdb $DB ".read $sqlPath"` (Windows path) | `$fwd = $sqlPath -replace '\\','/'; & duckdb $DB ".read $fwd"` | DuckDB strips backslashes in .read paths |
| One DuckDB call per file in a loop | Batch all inserts in one `.sql` file, one `duckdb` call | Per-call overhead: 299 files = 299 process launches |
| Leaving temp SQL file on failure | `try { } finally { Remove-Item -LiteralPath $sqlPath -EA SilentlyContinue }` | Temp files accumulate; may contain sensitive data |
