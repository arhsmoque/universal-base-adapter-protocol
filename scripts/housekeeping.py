#!/usr/bin/env python
"""Remove Python bytecode artifacts from the repository."""
import shutil
from pathlib import Path

root = Path(__file__).parent.parent
removed = []

for p in sorted(root.rglob("__pycache__")):
    shutil.rmtree(p)
    removed.append(str(p))

for p in sorted(root.rglob("*.pyc")):
    p.unlink()
    removed.append(str(p))

for item in removed:
    print(f"removed: {item}")

if not removed:
    print("nothing to remove")
