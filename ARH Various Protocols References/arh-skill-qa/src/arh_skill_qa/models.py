from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class Finding:
    severity: str
    id: str
    file: str
    message: str
    agent_action: str

    def to_dict(self) -> dict[str, str]:
        return {
            "severity": self.severity,
            "id": self.id,
            "file": self.file,
            "message": self.message,
            "agent_action": self.agent_action,
        }


@dataclass
class SkillReport:
    skill_path: Path
    name: str | None = None
    status: str = "ok"
    score: int = 100
    metrics: dict[str, Any] = field(default_factory=dict)
    scores: dict[str, int] = field(default_factory=dict)
    findings: list[Finding] = field(default_factory=list)
    amend_plan: list[str] = field(default_factory=list)

    def add(self, severity: str, finding_id: str, file: str, message: str, action: str) -> None:
        self.findings.append(Finding(severity, finding_id, file, message, action))

    def finalize(self) -> None:
        if any(f.severity == "error" for f in self.findings):
            self.status = "error"
        elif any(f.severity == "warn" for f in self.findings):
            self.status = "warn"
        else:
            self.status = "ok"

        penalty = 0
        for finding in self.findings:
            penalty += 18 if finding.severity == "error" else 6
        self.score = max(0, 100 - penalty)

        self.amend_plan = [
            f.agent_action for f in self.findings if f.severity in {"error", "warn"}
        ][:12]

    def to_dict(self) -> dict[str, Any]:
        return {
            "skill_path": str(self.skill_path),
            "name": self.name,
            "status": self.status,
            "score": self.score,
            "metrics": self.metrics,
            "scores": self.scores,
            "findings": [f.to_dict() for f in self.findings],
            "amend_plan": self.amend_plan,
        }
