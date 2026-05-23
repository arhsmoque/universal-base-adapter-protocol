from __future__ import annotations

import json
from typing import Any

from .models import SkillReport


def render_json(payload: Any) -> None:
    if isinstance(payload, SkillReport):
        payload = payload.to_dict()
    elif isinstance(payload, list):
        payload = [item.to_dict() if isinstance(item, SkillReport) else item for item in payload]
    print(json.dumps(payload, indent=2, ensure_ascii=False))


def render_console(report: SkillReport) -> None:
    print(f"{report.status.upper()} score={report.score} skill={report.name or report.skill_path.name}")
    for finding in report.findings:
        print(f"[{finding.severity}] {finding.id}: {finding.message}")
        print(f"  action: {finding.agent_action}")


def render_markdown(report: SkillReport) -> None:
    print(f"# Skill QA Report: {report.name or report.skill_path.name}")
    print()
    print(f"- Status: `{report.status}`")
    print(f"- Score: `{report.score}`")
    print()
    print("## Findings")
    if not report.findings:
        print()
        print("No findings.")
    for finding in report.findings:
        print()
        print(f"- **{finding.severity.upper()} {finding.id}**")
        print(f"  - File: `{finding.file}`")
        print(f"  - Issue: {finding.message}")
        print(f"  - Agent action: {finding.agent_action}")
    print()
    print("## Amend Plan")
    if not report.amend_plan:
        print()
        print("No amendments needed.")
    for idx, item in enumerate(report.amend_plan, start=1):
        print(f"{idx}. {item}")
