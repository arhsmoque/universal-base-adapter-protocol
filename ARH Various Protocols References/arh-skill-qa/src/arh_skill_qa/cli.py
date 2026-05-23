from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .analyzer import analyze_skill, discover_skills
from .registry import build_registry, write_registry
from .render import render_console, render_json, render_markdown


def main() -> int:
    parser = argparse.ArgumentParser(description="ARH skill quality gate")
    sub = parser.add_subparsers(dest="command", required=True)

    check = sub.add_parser("check", help="Check one skill folder")
    check.add_argument("skill", type=Path)
    check.add_argument("--json", action="store_true")
    check.add_argument("--markdown", action="store_true")
    check.add_argument("--strict-frontmatter", action="store_true")

    check_all = sub.add_parser("check-all", help="Check all direct child skills under a root")
    check_all.add_argument("skills_root", type=Path)
    check_all.add_argument("--json", action="store_true")
    check_all.add_argument("--strict-frontmatter", action="store_true")

    amend = sub.add_parser("amend-plan", help="Emit repair plan for one skill")
    amend.add_argument("skill", type=Path)
    amend.add_argument("--json", action="store_true")

    registry = sub.add_parser("registry", help="Registry operations")
    registry_sub = registry.add_subparsers(dest="registry_command", required=True)
    reg_build = registry_sub.add_parser("build", help="Build compact skill registry")
    reg_build.add_argument("--skills-root", type=Path, required=True)
    reg_build.add_argument("--output", type=Path)
    reg_build.add_argument("--json", action="store_true")

    args = parser.parse_args()

    try:
        if args.command == "check":
            report = analyze_skill(args.skill, strict_frontmatter=args.strict_frontmatter)
            if args.json:
                render_json(report)
            elif args.markdown:
                render_markdown(report)
            else:
                render_console(report)
            return _exit_for_status(report.status)

        if args.command == "check-all":
            reports = [
                analyze_skill(path, strict_frontmatter=args.strict_frontmatter)
                for path in discover_skills(args.skills_root)
            ]
            if args.json:
                render_json(reports)
            else:
                for report in reports:
                    render_console(report)
                    print()
            statuses = [r.status for r in reports]
            return 2 if "error" in statuses else 1 if "warn" in statuses else 0

        if args.command == "amend-plan":
            report = analyze_skill(args.skill)
            payload = {
                "skill": report.name or args.skill.name,
                "status": report.status,
                "score": report.score,
                "amend_plan": report.amend_plan,
            }
            if args.json:
                render_json(payload)
            else:
                for idx, item in enumerate(report.amend_plan, start=1):
                    print(f"{idx}. {item}")
            return _exit_for_status(report.status)

        if args.command == "registry" and args.registry_command == "build":
            data = build_registry(args.skills_root)
            if args.output:
                write_registry(args.skills_root, args.output)
            if args.json or not args.output:
                render_json(data)
            return 0
    except Exception as exc:  # keep CLI failures distinct from skill findings
        print(f"arh-skill-qa failed: {exc}", file=sys.stderr)
        return 3

    return 3


def _exit_for_status(status: str) -> int:
    if status == "error":
        return 2
    if status == "warn":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
