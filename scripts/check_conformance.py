#!/usr/bin/env python
"""Dependency-free conformance checker for Universal Base/Adapter Protocol v1.5."""

from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
import time
from pathlib import Path
from typing import Any


RISK_CLASSES = {"read_only", "local_mutation", "external_mutation", "destructive", "open_world"}
SURFACES = {"base", "cli", "web", "api", "mcp", "worker", "skill", "docs", "lsp", "sandbox"}
MUTATION_RISKS = {"local_mutation", "external_mutation", "destructive", "open_world"}
MODIFIER_REQUIRED_RISKS = {"external_mutation", "destructive"}
TELEMETRY_EMITTING_SURFACES = {"cli", "web", "api", "mcp", "worker", "sandbox"}
SCRIPT_EXTENSIONS = {".py", ".ps1", ".sh", ".bash", ".js", ".mjs", ".cjs", ".ts", ".rb", ".pl", ".bat", ".cmd"}
KNOWN_RUNTIMES = {"python", "python3", "pwsh", "powershell", "node", "ruby", "perl", "bash", "sh", "deno", "bun"}


def parse_scalar(value: str) -> Any:
    value = value.strip()
    if value in {"", '""', "''"}:
        return ""
    if value == "true":
        return True
    if value == "false":
        return False
    if value == "null":
        return None
    if value == "[]":
        return []
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [parse_scalar(part.strip()) for part in inner.split(",")]
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    if re.fullmatch(r"-?\d+", value):
        return int(value)
    return value


def read_metadata(path: Path) -> dict[str, Any]:
    data: dict[str, Any] = {}
    current_section: str | None = None
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if not raw.startswith(" ") and ":" in raw:
            key, value = raw.split(":", 1)
            key = key.strip()
            if value.strip() == "":
                current_section = key
                data[current_section] = {}
            else:
                current_section = None
                data[key] = parse_scalar(value)
            continue
        if current_section and raw.startswith("  ") and ":" in raw:
            key, value = raw.strip().split(":", 1)
            section = data.setdefault(current_section, {})
            if isinstance(section, dict):
                section[key.strip()] = parse_scalar(value)
    return data


def add(findings: list[dict[str, str]], severity: str, finding_id: str, message: str, action: str) -> None:
    findings.append(
        {
            "severity": severity,
            "id": finding_id,
            "message": message,
            "agent_action": action,
        }
    )


def has_nonempty(mapping: dict[str, Any], key: str) -> bool:
    value = mapping.get(key)
    return value not in (None, "", [], {})


def find_metadata(component_dir: Path) -> Path | None:
    direct = component_dir / "METADATA.yml"
    if direct.exists():
        return direct
    template = component_dir / "templates" / "METADATA.yml"
    if template.exists():
        return template
    return None


def looks_like_path_token(token: str) -> bool:
    """Heuristic: token is path-like and should be resolved against the component dir."""
    if not token or token.startswith("-"):
        return False
    if token in {".", "..", "/"} or token in KNOWN_RUNTIMES:
        return False
    if token.startswith(("http://", "https://", "file://")):
        return False
    if Path(token).is_absolute():
        return False
    has_separator = "/" in token or "\\" in token
    has_script_ext = Path(token).suffix.lower() in SCRIPT_EXTENSIONS
    return has_separator or has_script_ext


def resolve_command_paths(component_dir: Path, command: str) -> list[tuple[str, bool]]:
    """Return list of (token, exists) for path-like tokens inside a command string."""
    if not command:
        return []
    try:
        tokens = shlex.split(command, posix=False)
    except ValueError:
        tokens = command.split()
    results: list[tuple[str, bool]] = []
    for token in tokens:
        token = token.strip('"').strip("'").rstrip(",;:.")
        if looks_like_path_token(token):
            normalized = token.replace("\\", "/")
            candidate = (component_dir / normalized).resolve()
            results.append((token, candidate.exists()))
    return results


def validate_schema_file(path: Path) -> tuple[bool, str]:
    """Return (ok, error_message) for a JSON Schema file."""
    if not path.exists():
        return False, "missing"
    try:
        text = path.read_text(encoding="utf-8-sig")
        doc = json.loads(text)
    except json.JSONDecodeError as exc:
        return False, f"invalid JSON: {exc.msg} at line {exc.lineno}"
    if not isinstance(doc, dict):
        return False, "root must be a JSON object"
    if doc.get("type") not in {"object", "array"} and "$ref" not in doc and "oneOf" not in doc and "anyOf" not in doc:
        return False, "schema lacks `type`, `$ref`, `oneOf`, or `anyOf`"
    return True, ""


def validate_composite_envelope(component_dir: Path) -> tuple[bool, str]:
    """Composite components must ship examples/envelope.json with steps[].trace_id."""
    candidates = [
        component_dir / "examples" / "envelope.json",
        component_dir / "examples" / "envelope.example.json",
    ]
    path = next((p for p in candidates if p.exists()), None)
    if path is None:
        return False, "no examples/envelope.json found"
    try:
        doc = json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        return False, f"envelope JSON invalid: {exc.msg} at line {exc.lineno}"
    steps = doc.get("steps") if isinstance(doc, dict) else None
    if not isinstance(steps, list) or not steps:
        return False, "envelope is missing a non-empty `steps` array"
    for idx, step in enumerate(steps):
        if not isinstance(step, dict) or not step.get("trace_id"):
            return False, f"steps[{idx}] missing `trace_id`"
    return True, ""


def check(component_dir: Path, target_level: int) -> dict[str, Any]:
    findings: list[dict[str, str]] = []
    evidence: list[dict[str, str]] = []
    verified_level = 0

    metadata_path = find_metadata(component_dir)
    metadata: dict[str, Any] = {}
    if not metadata_path:
        add(findings, "error", "missing-metadata", "METADATA.yml was not found.", "Add METADATA.yml from templates/METADATA.yml.")
    else:
        metadata = read_metadata(metadata_path)
        evidence.append({"type": "metadata", "path": str(metadata_path)})

    required_top = ["component", "version", "schema_version", "protocol", "conformance_level", "surface", "risk_class", "status"]
    for key in required_top:
        if metadata_path and key not in metadata:
            add(findings, "error", f"missing-{key}", f"Metadata is missing `{key}`.", f"Add `{key}` to METADATA.yml.")

    risk_class = str(metadata.get("risk_class", "")).strip()
    surface = str(metadata.get("surface", "")).strip()
    claimed_level = metadata.get("conformance_level", target_level)
    if not isinstance(claimed_level, int):
        claimed_level = target_level

    if risk_class and "|" in risk_class:
        add(findings, "warn", "placeholder-risk-class", "risk_class still contains template enum text.", "Replace it with one concrete risk class.")
    elif risk_class and risk_class not in RISK_CLASSES:
        add(findings, "error", "invalid-risk-class", f"Unknown risk_class `{risk_class}`.", "Use a protocol risk class.")

    if surface and "|" in surface:
        add(findings, "warn", "placeholder-surface", "surface still contains template enum text.", "Replace it with one concrete surface.")
    elif surface and surface not in SURFACES:
        add(findings, "error", "invalid-surface", f"Unknown surface `{surface}`.", "Use a protocol surface.")

    commands = metadata.get("commands", {})
    contracts = metadata.get("contracts", {})
    observability = metadata.get("observability", {})
    housekeeping = metadata.get("housekeeping", {})
    salvage = metadata.get("salvage", {})
    if not isinstance(commands, dict):
        commands = {}
    if not isinstance(contracts, dict):
        contracts = {}
    if not isinstance(observability, dict):
        observability = {}
    if not isinstance(housekeeping, dict):
        housekeeping = {}
    if not isinstance(salvage, dict):
        salvage = {}

    risk_modifiers = metadata.get("risk_modifiers", [])
    if not isinstance(risk_modifiers, list):
        risk_modifiers = []
    if risk_class in MODIFIER_REQUIRED_RISKS and not risk_modifiers:
        add(
            findings,
            "error",
            "missing-risk-modifiers",
            f"risk_class `{risk_class}` requires at least one entry in `risk_modifiers`.",
            "Declare the operational hazards (e.g. secret_bearing, network_access) or record an escape hatch.",
        )

    if metadata_path and not any(f["severity"] == "error" for f in findings):
        verified_level = 0

    if target_level >= 1:
        if not ((component_dir / "AGENTS.md").exists() or (component_dir / "templates" / "AGENTS.template.md").exists()):
            add(findings, "error", "missing-agents", "No AGENTS.md or AGENTS template was found.", "Add AGENTS.md or templates/AGENTS.template.md.")
        if not has_nonempty(contracts, "output_schema"):
            add(findings, "error", "missing-output-schema", "Level 1 requires a structured output schema.", "Reference result-envelope or a component output schema.")
        if not (has_nonempty(commands, "test") or has_nonempty(commands, "smoke")):
            add(findings, "error", "missing-test-command", "Level 1 requires test or smoke command evidence.", "Add commands.test or commands.smoke.")
        for cmd_key in ("test", "smoke", "lint", "dry_run", "replay", "housekeeping"):
            cmd_value = commands.get(cmd_key)
            if not isinstance(cmd_value, str) or not cmd_value.strip():
                continue
            for token, exists in resolve_command_paths(component_dir, cmd_value):
                if not exists:
                    add(
                        findings,
                        "error",
                        f"command-path-missing-{cmd_key}",
                        f"commands.{cmd_key} references `{token}` which does not exist under {component_dir}.",
                        "Fix the path or remove the command from METADATA.yml.",
                    )
        if not any(f["severity"] == "error" for f in findings):
            verified_level = 1

    if target_level >= 2:
        if not has_nonempty(observability, "trace_id"):
            add(findings, "error", "missing-trace-id", "Level 2 requires trace ID support.", "Set observability.trace_id and implement it in adapter outputs.")
        if risk_class in MUTATION_RISKS:
            dry_run = contracts.get("dry_run") is True or has_nonempty(commands, "dry_run")
            if not dry_run:
                add(findings, "error", "missing-dry-run", "Mutation risks require dry-run evidence.", "Add contracts.dry_run true or commands.dry_run.")
            if not has_nonempty(contracts, "idempotency"):
                add(findings, "error", "missing-idempotency", "Mutation risks require idempotency or duplicate-detection notes.", "Add contracts.idempotency.")
        if not any(f["severity"] == "error" for f in findings):
            verified_level = 2

    if target_level >= 3:
        if not has_nonempty(commands, "replay"):
            add(findings, "error", "missing-replay", "Level 3 requires replay support where practical.", "Add commands.replay or a scoped escape hatch.")
        if not has_nonempty(observability, "continuation_packet"):
            add(findings, "error", "missing-continuation", "Level 3 requires continuation behavior.", "Add observability.continuation_packet.")
        if not has_nonempty(commands, "housekeeping") and not has_nonempty(housekeeping, "discovery_pollution_check"):
            add(findings, "error", "missing-housekeeping", "Level 3 requires housekeeping proof.", "Add commands.housekeeping or housekeeping.discovery_pollution_check.")
        if surface in TELEMETRY_EMITTING_SURFACES or observability.get("trace_id") is True:
            if not has_nonempty(observability, "semconv_version"):
                add(
                    findings,
                    "error",
                    "missing-semconv-version",
                    "Level 3 telemetry-emitting components must pin an OpenTelemetry GenAI semconv version.",
                    "Add observability.semconv_version (e.g., \"1.40\") or record an escape hatch.",
                )
        composite_declared = metadata.get("composite") is True
        try:
            tools_count = int(metadata.get("tools_count", 0))
        except (TypeError, ValueError):
            tools_count = 0
        if composite_declared or tools_count > 1:
            ok, message = validate_composite_envelope(component_dir)
            if not ok:
                add(
                    findings,
                    "error",
                    "composite-envelope-invalid",
                    f"Composite component failed envelope audit: {message}.",
                    "Provide examples/envelope.json with a `steps` array; every step must carry a `trace_id`.",
                )
            else:
                evidence.append({"type": "composite-envelope", "path": "examples/envelope.json"})
        if not any(f["severity"] == "error" for f in findings):
            verified_level = 3

    if target_level >= 4:
        schema_dir = component_dir / "schemas"
        required_schemas = [
            "metadata.schema.json",
            "result-envelope.schema.json",
            "spec-packet.schema.json",
            "conformance-linter-output.schema.json",
        ]
        for schema_name in required_schemas:
            ok, message = validate_schema_file(schema_dir / schema_name)
            if not ok:
                add(
                    findings,
                    "error",
                    f"schema-invalid-{schema_name}",
                    f"Level 4 schema `{schema_name}` failed validation: {message}.",
                    "Repair or replace the schema, or record a governed escape hatch.",
                )
            else:
                evidence.append({"type": "schema", "path": f"schemas/{schema_name}"})
        if not has_nonempty(metadata, "owner"):
            add(findings, "error", "missing-owner", "Level 4 requires an owner.", "Add owner to METADATA.yml.")
        if not has_nonempty(metadata, "review_cadence"):
            add(findings, "error", "missing-review-cadence", "Level 4 requires review cadence.", "Add review_cadence to METADATA.yml.")
        if not has_nonempty(salvage, "rollback_path"):
            add(findings, "warn", "missing-rollback-path", "Level 4 should document rollback/removal path.", "Add salvage.rollback_path.")
        if not any(f["severity"] == "error" for f in findings):
            verified_level = 4

    status = "success"
    if any(f["severity"] == "error" for f in findings):
        status = "error"
    elif findings:
        status = "partial_success"

    return {
        "status": status,
        "claimed_level": int(claimed_level) if isinstance(claimed_level, int) else target_level,
        "target_level": target_level,
        "verified_level": verified_level,
        "findings": findings,
        "evidence": evidence,
        "trace_id": f"conf_{int(time.time() * 1000)}",
        "schema_version": "1.0",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Check Universal Base/Adapter Protocol conformance.")
    parser.add_argument("component_dir", nargs="?", default=".", help="Component or protocol package directory.")
    parser.add_argument("--level", type=int, default=1, choices=range(0, 5), help="Target level 0..4.")
    parser.add_argument("--json", action="store_true", help="Emit JSON only.")
    parser.add_argument("--report", type=str, default=None, help="Write conformance-report.json to this path.")
    args = parser.parse_args()

    component_dir = Path(args.component_dir).resolve()
    result = check(component_dir, args.level)

    if args.report:
        report_path = Path(args.report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(result, indent=2), encoding="utf-8")

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"status={result['status']} claimed={result['claimed_level']} verified={result['verified_level']}")
        for finding in result["findings"]:
            print(f"[{finding['severity']}] {finding['id']}: {finding['message']}")

    if any(f["severity"] == "error" for f in result["findings"]):
        return 2
    if result["findings"]:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
