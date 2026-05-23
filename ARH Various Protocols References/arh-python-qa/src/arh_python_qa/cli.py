"""CLI entry point."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from arh_python_qa.findings import PipelineResult
from arh_python_qa.render import render_console, render_json
from arh_python_qa.runners import (
    run_complexity,
    run_mypy,
    run_pip_audit,
    run_pytest,
    run_ruff_check,
    run_ruff_format_check,
    run_ruff_security,
    run_vulture,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="ARH Python-UV Toolkit Orchestrator")
    parser.add_argument(
        "--mode",
        choices=["design", "audit", "maintenance", "full"],
        default="full",
        help="Pipeline mode to run",
    )
    parser.add_argument("--fix", action="store_true", help="Auto-fix safe issues (ruff only)")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON instead of human output")
    parser.add_argument("--project", type=Path, default=Path.cwd(), help="Project root path")
    args = parser.parse_args()

    project_root = args.project.resolve()
    is_uv = (project_root / "pyproject.toml").exists() and (project_root / "uv.lock").exists()

    if not is_uv and args.mode != "audit":
        print(f"Warning: no uv project detected at {project_root}", file=sys.stderr)

    result = PipelineResult(mode=args.mode, project=str(project_root))
    json_mode = args.json

    if args.mode in ("design", "full"):
        result.results.append(run_ruff_check(project_root, fix=args.fix, json_mode=json_mode))
        result.results.append(run_ruff_format_check(project_root))
        result.results.append(run_mypy(project_root))
        if args.mode == "full":
            result.results.append(run_pytest(project_root))

    if args.mode in ("audit", "full"):
        result.results.append(run_ruff_security(project_root, json_mode=json_mode))
        result.results.append(run_vulture(project_root))
        result.results.append(run_pip_audit(project_root))

    if args.mode in ("maintenance", "full"):
        result.results.append(run_complexity(project_root))
        if args.mode == "maintenance":
            result.results.append(run_vulture(project_root))

    severities = [r.severity for r in result.results]
    if "error" in severities:
        result.overall_severity = "error"
    elif "warn" in severities:
        result.overall_severity = "warn"
    else:
        result.overall_severity = "ok"

    result.fixable = args.fix and any(not r.passed and r.tool == "ruff" for r in result.results)

    if args.json:
        render_json(result)
    else:
        render_console(result)

    if result.overall_severity == "error":
        return 2
    if result.overall_severity == "warn":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
