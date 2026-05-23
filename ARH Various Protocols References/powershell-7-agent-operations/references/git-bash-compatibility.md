# Git Bash Compatibility

Use this reference only when the task explicitly involves Git Bash/MSYS2, Azure Pipelines Bash tasks on Windows, or invoking Windows commands from a Bash-like shell.

## Detection

PowerShell indicators:

```powershell
$PSVersionTable.PSVersion
$env:PSModulePath
$IsWindows
```

Git Bash/MSYS indicators:

```bash
echo "$MSYSTEM"
uname -s
```

Common values: `MINGW64`, `MINGW32`, `MSYS`, `CYGWIN`.

## Path Rules

PowerShell:

```powershell
$env:VAR = "value"
Join-Path $env:USERPROFILE "Downloads"
Test-Path -LiteralPath "D:\00_ARH"
```

Git Bash:

```bash
export VAR=value
cygpath -u "D:\00_ARH"
cygpath -w "/d/00_ARH"
```

## MSYS Path Conversion Traps

Git Bash may rewrite arguments that look like Unix paths. This breaks Windows switches and path lists.

Use:

```bash
export MSYS_NO_PATHCONV=1
```

Or selectively:

```bash
export MSYS2_ARG_CONV_EXCL="*"
```

Do not use Git Bash as the default shell for registry, services, Windows networking, scheduled tasks, or PowerShell module work.

## ARH Defaults

- Windows/system tasks: `pwsh`
- Node/npm under Bash: `npm.cmd`, not `npm`
- Python: `python`, not `python3`
- Direct Windows paths in Bash: quote them and avoid bare backslashes
