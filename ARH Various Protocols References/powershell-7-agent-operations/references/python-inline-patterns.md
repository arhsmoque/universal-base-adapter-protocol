# Python Inline Patterns for PowerShell 7

When running Python one-liners or short scripts from PowerShell, quote escaping is a recurring trap. This reference shows the safe patterns.

## The Trap

```powershell
# BROKEN: PowerShell strips embedded double quotes before Python sees them
python -c "print('hello')"           # works
python -c "import json; print(json.dumps({'a': 1}))"  # often broken

# BROKEN: Backslash escaping in -c strings
python -c "import duckdb; conn = duckdb.connect(r\"D:\\path\\db.duckdb\")"  # mangled
```

## Safe Pattern 1: Piped Here-String (Recommended)

Use `@'...'@` here-string piped to `python -`:

```powershell
@'
import duckdb
conn = duckdb.connect(r'D:\00_ARH\01_homelab\00-agent-hub\observability\databases\pwsh-guard.duckdb')
rows = conn.execute("SELECT * FROM table WHERE col = 'value'").fetchall()
for r in rows:
    print(r)
'@ | python -
```

Why this works:
- `@'...'@` is a literal here-string: no variable expansion, no escape processing
- The pipe (`|`) feeds the raw text into `python -` (stdin mode)
- Single quotes inside are literal; double quotes inside are literal
- Backslashes are literal (use `r'...'` raw strings in Python for Windows paths)

## Safe Pattern 2: Temp Script File

For complex scripts, write to a temp file:

```powershell
$tmp = [System.IO.Path]::GetTempFileName() + '.py'
@'
import json
print(json.dumps({"status": "ok"}))
'@ | Set-Content -Path $tmp -Encoding UTF8
python $tmp
Remove-Item -Path $tmp
```

## Safe Pattern 3: Single-Line with Single Quotes Only

If the Python code fits on one line and uses no single quotes:

```powershell
python -c 'import json; print(json.dumps([1,2,3]))'
```

Limitation: cannot use single quotes inside the Python string.

## What NOT to Do

| Approach | Why It Fails |
|----------|-------------|
| `python -c "..."` with nested quotes | PowerShell strips `"` before passing to python |
| `python -c '...'"..."'...'` | Mixed quote styles confuse both shells |
| `"python -c \"...\""` | Backtick escaping is shell-dependent and fragile |
| Bash heredoc `<<EOF` in PowerShell | PowerShell does not support `<<` heredoc syntax |

## Quick Reference Card

```powershell
# DuckDB query → use piped here-string
@'
import duckdb
conn = duckdb.connect(r'D:\path\to\db.duckdb')
print(conn.execute("SELECT COUNT(*) FROM t").fetchone()[0])
'@ | python -

# JSON payload → use piped here-string
@'
import json
data = {"key": "value with 'quotes'"}
print(json.dumps(data))
'@ | python -

# One-liner, no quotes needed → use single quotes
python -c 'import sys; print(sys.version)'
```
