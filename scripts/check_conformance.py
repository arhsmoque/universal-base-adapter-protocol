#!/usr/bin/env python
"""Dependency-free conformance checker for Universal Base/Adapter Protocol v1.5."""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Any


RISK_CLASSES = {"read_only", "local_mutation", "external_mutation", "destructive", "open_world"}
SURFACES = {"base", "cli", "web", "api", "mcp", "worker", "skill", "docs", "lsp", "sandbox"}
MUTATION_RISKS = {"local_mutation", "external_mutation", "destructive", "open_world"}


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

    if metadata_path and not any(f["severity"] == "error" for f in findings):
        verified_level = 0

    if target_level >= 1:
        if not ((component_dir / "AGENTS.md").exists() or (component_dir / "templates" / "AGENTS.template.md").exists()):
            add(findings, "error", "missing-agents", "No AGENTS.md or AGENTS template was found.", "Add AGENTS.md or templates/AGENTS.template.md.")
        if not has_nonempty(contracts, "output_schema"):
            add(findings, "error", "missing-output-schema", "Level 1 requires a structured output schema.", "Reference result-envelope or a component output schema.")
        if not (has_nonempty(commands, "test") or has_nonempty(commands, "smoke")):
            add(findings, "error", "missing-test-command", "Level 1 requires test or smoke command evidence.", "Add commands.test or commands.smoke.")
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
            if not (schema_dir / schema_name).exists():
                add(findings, "error", f"missing-{schema_name}", f"Level 4 requires {schema_name}.", "Add the schema or record a governed escape hatch.")
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
    args = parser.parse_args()

    component_dir = Path(args.component_dir).resolve()
    result = check(component_dir, args.level)

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
