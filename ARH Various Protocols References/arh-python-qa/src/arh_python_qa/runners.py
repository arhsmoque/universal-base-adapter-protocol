"""Tool runners — execute ruff, mypy, pytest, vulture, pip-audit."""
from __future__ import annotations

import subprocess
from pathlib import Path

from arh_python_qa.findings import Finding, ToolResult, parse_ruff_json


def _run(cmd: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=cwd,
        encoding="utf-8",
        errors="replace",
    )


def _detect_uv_project(project_root: Path) -> bool:
    return (project_root / "pyproject.toml").exists() and (project_root / "uv.lock").exists()


def _uv_cmd(tool_args: list[str], project_root: Path) -> list[str]:
    if _detect_uv_project(project_root):
        return ["uv", "run", *tool_args]
    return tool_args


def classify_ruff(
    stdout: str, stderr: str, rc: int, fix_mode: bool, json_mode: bool = False
) -> ToolResult:
    findings: list[Finding] = []
    if json_mode and stdout.strip():
        findings = parse_ruff_json(stdout)
    if rc == 0:
        return ToolResult("ruff", [], rc, stdout, stderr, True, "ok", "No issues", findings)
    lines = [ln for ln in (stdout + stderr).splitlines() if ln.strip()]
    summary = lines[-1] if lines else f"{rc} issues found"
    severity = "warn" if fix_mode else "error"
    return ToolResult("ruff", [], rc, stdout, stderr, False, severity, summary, findings)


def run_ruff_check(project_root: Path, fix: bool = False, json_mode: bool = False) -> ToolResult:
    cmd = _uv_cmd(["ruff", "check", "."], project_root)
    if fix:
        cmd.insert(-1, "--fix")
    if json_mode:
        cmd.insert(-1, "--output-format")
        cmd.insert(-1, "json")
    r = _run(cmd, project_root)
    return classify_ruff(r.stdout, r.stderr, r.returncode, fix, json_mode)


def run_ruff_format_check(project_root: Path) -> ToolResult:
    cmd = _uv_cmd(["ruff", "format", "--check", "."], project_root)
    r = _run(cmd, project_root)
    if r.returncode == 0:
        return ToolResult("ruff-format", cmd, r.returncode, r.stdout, r.stderr, True, "ok", "Formatted")
    return ToolResult("ruff-format", cmd, r.returncode, r.stdout, r.stderr, False, "warn", "Formatting issues")


def run_mypy(project_root: Path) -> ToolResult:
    cmd = _uv_cmd(["mypy", "src/"], project_root)
    r = _run(cmd, project_root)
    if r.returncode == 0:
        return ToolResult("mypy", cmd, r.returncode, r.stdout, r.stderr, True, "ok", "No type errors")
    lines = [ln for ln in (r.stdout + r.stderr).splitlines() if ln.strip()]
    return ToolResult("mypy", cmd, r.returncode, r.stdout, r.stderr, False, "error", f"{len(lines)} type issues")


def run_pytest(project_root: Path) -> ToolResult:
    cmd = _uv_cmd(["pytest"], project_root)
    r = _run(cmd, project_root)
    if r.returncode == 0:
        return ToolResult("pytest", cmd, r.returncode, r.stdout, r.stderr, True, "ok", "All tests passed")
    summary = "Tests failed"
    for line in (r.stdout + r.stderr).splitlines():
        if "failed" in line.lower() or "error" in line.lower():
            summary = line.strip()
            break
    return ToolResult("pytest", cmd, r.returncode, r.stdout, r.stderr, False, "error", summary)


def run_vulture(project_root: Path) -> ToolResult:
    cmd = _uv_cmd(["vulture", "src/", "tests/", "--min-confidence", "80"], project_root)
    r = _run(cmd, project_root)
    if r.returncode == 0:
        return ToolResult("vulture", cmd, r.returncode, r.stdout, r.stderr, True, "ok", "No dead code")
    if r.returncode == 3:
        lines = [ln for ln in r.stdout.splitlines() if ln.strip()]
        return ToolResult("vulture", cmd, r.returncode, r.stdout, r.stderr, False, "warn", f"{len(lines)} dead code items")
    return ToolResult("vulture", cmd, r.returncode, r.stdout, r.stderr, False, "error", f"Exit {r.returncode}")


def run_pip_audit(project_root: Path) -> ToolResult:
    cmd = _uv_cmd(["pip-audit"], project_root)
    r = _run(cmd, project_root)
    if r.returncode == 0:
        return ToolResult("pip-audit", cmd, r.returncode, r.stdout, r.stderr, True, "ok", "No vulnerabilities")
    summary = "Vulnerabilities found"
    for line in (r.stdout + r.stderr).splitlines():
        if "vulnerability" in line.lower() or "cve" in line.lower():
            summary = line.strip()
            break
    severity = "error" if "critical" in (r.stdout + r.stderr).lower() or "high" in (r.stdout + r.stderr).lower() else "warn"
    return ToolResult("pip-audit", cmd, r.returncode, r.stdout, r.stderr, False, severity, summary)


def run_complexity(project_root: Path) -> ToolResult:
    cmd = _uv_cmd(["ruff", "check", "--select", "C901", "."], project_root)
    r = _run(cmd, project_root)
    if r.returncode == 0 and not r.stdout.strip():
        return ToolResult("complexity", cmd, r.returncode, r.stdout, r.stderr, True, "ok", "Complexity OK")
    lines = [ln for ln in (r.stdout + r.stderr).splitlines() if ln.strip()]
    summary = f"{len(lines)} complexity issues" if lines else "Complexity issues found"
    return ToolResult("complexity", cmd, r.returncode, r.stdout, r.stderr, False, "warn", summary)


def run_ruff_security(project_root: Path, json_mode: bool = False) -> ToolResult:
    cmd = _uv_cmd(["ruff", "check", "--select", "S", "."], project_root)
    if json_mode:
        cmd.insert(-1, "--output-format")
        cmd.insert(-1, "json")
    r = _run(cmd, project_root)
    return classify_ruff(r.stdout, r.stderr, r.returncode, fix_mode=False, json_mode=json_mode)
