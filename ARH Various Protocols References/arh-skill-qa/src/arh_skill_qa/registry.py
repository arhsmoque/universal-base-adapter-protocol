from __future__ import annotations

import hashlib
import json
from pathlib import Path

from .analyzer import analyze_skill, discover_skills


def build_registry(skills_root: Path) -> dict[str, object]:
    entries = []
    for skill_path in discover_skills(skills_root):
        report = analyze_skill(skill_path)
        skill_file = skill_path / "SKILL.md"
        digest = hashlib.sha256(skill_file.read_bytes()).hexdigest()[:16]
        entries.append(
            {
                "name": report.name or skill_path.name,
                "path": str(skill_path),
                "status": report.status,
                "score": report.score,
                "estimated_tokens": report.metrics.get("estimated_tokens"),
                "sha256_16": digest,
                "finding_count": len(report.findings),
            }
        )
    return {"skills_root": str(skills_root.resolve()), "count": len(entries), "skills": entries}


def write_registry(skills_root: Path, output: Path) -> None:
    data = build_registry(skills_root)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
