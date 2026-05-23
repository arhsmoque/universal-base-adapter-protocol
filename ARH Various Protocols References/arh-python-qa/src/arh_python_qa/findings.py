"""Data models and security taxonomy for findings."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Any, Literal

# Map bandit/ruff security rules to attack classes
SECURITY_CATEGORIES: dict[str, str] = {
    "S608": "SQL Injection",
    "S605": "Command Injection",
    "S607": "Command Injection",
    "S602": "Command Injection",
    "S307": "Remote Code Execution",
    "S102": "Remote Code Execution",
    "S209": "Path Traversal",
    "S105": "Hardcoded Secrets",
    "S106": "Hardcoded Secrets",
    "S107": "Hardcoded Secrets",
    "S301": "Unsafe Deserialization",
    "S506": "Unsafe Deserialization",
    "S324": "Weak Cryptography",
    "S101": "Debug in Production",
    "S108": "Tempfile Race Condition",
    "S103": "Insecure Permissions",
}


@dataclass(frozen=True, slots=True)
class Finding:
    file: str
    line: int
    column: int
    code: str
    message: str
    category: str = ""


@dataclass(frozen=True, slots=True)
class ToolResult:
    tool: str
    cmd: list[str]
    returncode: int
    stdout: str
    stderr: str
    passed: bool
    severity: Literal["ok", "warn", "error"]
    summary: str = ""
    findings: list[Finding] = field(default_factory=list)


@dataclass
class PipelineResult:
    mode: str
    project: str | None
    results: list[ToolResult] = field(default_factory=list)
    overall_severity: Literal["ok", "warn", "error"] = "ok"
    fixable: bool = False


def parse_ruff_json(stdout: str) -> list[Finding]:
    """Parse ruff JSON output into structured findings."""
    findings: list[Finding] = []
    try:
        for line in stdout.strip().splitlines():
            if not line.strip():
                continue
            entry: dict[str, Any] = json.loads(line)
            code = entry.get("code", "")
            finding = Finding(
                file=entry.get("filename", ""),
                line=entry.get("location", {}).get("row", 0),
                column=entry.get("location", {}).get("column", 0),
                code=code,
                message=entry.get("message", ""),
                category=SECURITY_CATEGORIES.get(code, ""),
            )
            findings.append(finding)
    except Exception:
        pass
    return findings
