# Contributing

This repository is governance material. Changes should be small, reviewable, and backed by conformance checks.

## Required Checks

```powershell
python -B -m py_compile scripts/check_conformance.py
python -B scripts/check_conformance.py . --level 4 --json
Get-ChildItem -LiteralPath schemas -Filter '*.json' | ForEach-Object { python -m json.tool $_.FullName > $null }
```

## Change Rules

- Protocol doctrine changes belong in `UNIVERSAL_BASE_ADAPTER_PROTOCOL.md`.
- Rollout and precedence changes belong in `GOVERNANCE_IMPLEMENTATION_GUIDE.md`.
- Machine-enforced contract changes belong in `schemas/` and `scripts/check_conformance.py`.
- Surface-specific changes belong in `adapters/`.
- Templates must stay lightweight and usable by weaker agents.

If prose and schema disagree, treat it as a governance defect and fix both in the same change.
