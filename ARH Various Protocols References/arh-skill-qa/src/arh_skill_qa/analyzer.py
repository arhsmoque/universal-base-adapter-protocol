from __future__ import annotations

import re
from pathlib import Path

from .models import SkillReport

ALLOWED_TOP_LEVEL = {"SKILL.md", "agents", "scripts", "references", "assets", "evals", "modules"}
GENERATED_NAMES = {"__pycache__", ".pytest_cache", "node_modules", ".venv", "dist", "build"}
Kebab_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


def analyze_skill(skill_path: Path, *, strict_frontmatter: bool = False) -> SkillReport:
    skill_path = skill_path.resolve()
    report = SkillReport(skill_path=skill_path)

    skill_file = skill_path / "SKILL.md"
    if not skill_path.exists():
        report.add("error", "path-missing", str(skill_path), "Skill path does not exist.", "Verify the skill path and rerun.")
        report.finalize()
        return report
    if not skill_file.exists():
        report.add("error", "missing-skill-md", str(skill_path), "No SKILL.md at skill root.", "Create SKILL.md at the skill folder root.")
        report.finalize()
        return report

    text = skill_file.read_text(encoding="utf-8", errors="replace")
    frontmatter, body = _split_frontmatter(text)
    fields = _parse_simple_frontmatter(frontmatter)
    report.name = fields.get("name")

    report.metrics = {
        "body_lines": len(body.splitlines()),
        "skill_md_chars": len(text),
        "estimated_tokens": max(1, len(text) // 4),
        "top_level_files": sorted(p.name for p in skill_path.iterdir()),
    }

    _check_frontmatter(report, skill_path, fields, strict_frontmatter)
    _check_body(report, body)
    _check_trigger(report, fields.get("description", ""))
    _check_resources(report, skill_path, body)
    _check_links(report, skill_path, body)
    _score_dimensions(report, fields, body)

    report.finalize()
    return report


def discover_skills(root: Path) -> list[Path]:
    root = root.resolve()
    if (root / "SKILL.md").exists():
        return [root]
    return sorted(p for p in root.iterdir() if p.is_dir() and (p / "SKILL.md").exists())


def _split_frontmatter(text: str) -> tuple[str, str]:
    if not text.startswith("---"):
        return "", text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return "", text
    return parts[1].strip(), parts[2].lstrip()


def _parse_simple_frontmatter(frontmatter: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    current_key: str | None = None
    for raw_line in frontmatter.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            continue
        if line.startswith((" ", "\t")) and current_key:
            fields[current_key] = (fields[current_key] + " " + line.strip()).strip()
            continue
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value in {">", "|"}:
            value = ""
        fields[key] = value
        current_key = key
    return fields


def _check_frontmatter(
    report: SkillReport, skill_path: Path, fields: dict[str, str], strict_frontmatter: bool
) -> None:
    if not fields:
        report.add("error", "missing-frontmatter", "SKILL.md", "Missing YAML frontmatter.", "Add frontmatter with name and description.")
        return
    name = fields.get("name")
    description = fields.get("description")
    if not name:
        report.add("error", "missing-name", "SKILL.md", "Frontmatter missing name.", "Add name matching the folder in kebab-case.")
    elif not Kebab_RE.match(name):
        report.add("error", "invalid-name", "SKILL.md", f"Skill name is not kebab-case: {name}", "Rename the skill using kebab-case.")
    elif name != skill_path.name:
        report.add("warn", "folder-name-mismatch", "SKILL.md", f"Frontmatter name '{name}' differs from folder '{skill_path.name}'.", "Align folder name and frontmatter name unless this is an intentional migration.")
    if not description:
        report.add("error", "missing-description", "SKILL.md", "Frontmatter missing description.", "Add a trigger-oriented description.")
    elif len(description) < 80:
        report.add("warn", "short-description", "SKILL.md", "Description may be too short to trigger reliably.", "Expand description with what the skill does and when to use it.")

    extra = sorted(set(fields) - {"name", "description"})
    if extra and strict_frontmatter:
        report.add("error", "extra-frontmatter", "SKILL.md", f"Extra frontmatter fields: {', '.join(extra)}", "Remove extra fields for strict import compatibility.")
    elif extra:
        report.add("warn", "extra-frontmatter", "SKILL.md", f"Extra frontmatter fields: {', '.join(extra)}", "Keep extra fields only if the local runtime consumes them.")


def _check_body(report: SkillReport, body: str) -> None:
    lower = body.lower()
    if not re.search(r"^#\s+", body, flags=re.MULTILINE):
        report.add("warn", "missing-h1", "SKILL.md", "Body has no H1 title.", "Add a clear H1 title matching the skill purpose.")
    if not any(term in lower for term in ["first minute", "quick", "workflow", "algorithm", "steps"]):
        report.add("warn", "no-first-run-path", "SKILL.md", "No obvious first-minute workflow or execution path.", "Add a short first-run workflow another agent can follow.")
    if not any(term in lower for term in ["validate", "verification", "quality gate", "output checklist", "exit code"]):
        report.add("warn", "no-validation-contract", "SKILL.md", "No clear validation/output contract.", "Add validation criteria or an output checklist.")
    if report.metrics["body_lines"] > 500:
        report.add("warn", "large-skill-md", "SKILL.md", "SKILL.md body exceeds 500 lines.", "Move detailed variants into references and keep SKILL.md operational.")
    if report.metrics["estimated_tokens"] > 5000:
        report.add("warn", "high-token-count", "SKILL.md", "Estimated SKILL.md token count is over 5000.", "Refactor heavy detail into references loaded on demand.")


def _check_trigger(report: SkillReport, description: str) -> None:
    lowered = description.lower()
    if "use when" not in lowered and "trigger" not in lowered and "when the user" not in lowered:
        report.add("warn", "weak-trigger-language", "SKILL.md", "Description does not clearly say when to use the skill.", "Rewrite description with concrete trigger phrases and near-miss boundaries.")
    if any(word in lowered for word in ["various", "etc.", "and more"]):
        report.add("warn", "open-ended-trigger", "SKILL.md", "Description uses open-ended trigger language.", "Replace vague trigger words with concrete task phrases.")


def _check_resources(report: SkillReport, skill_path: Path, body: str) -> None:
    names = {p.name for p in skill_path.iterdir()}
    unexpected = sorted(n for n in names - ALLOWED_TOP_LEVEL if not n.startswith("."))
    if unexpected:
        report.add("warn", "unexpected-top-level", str(skill_path), f"Unexpected top-level entries: {', '.join(unexpected)}", "Move support material into references, scripts, assets, agents, or evals.")

    for p in skill_path.rglob("*"):
        if p.name in GENERATED_NAMES:
            report.add("warn", "generated-artifact", str(p), "Generated/cache artifact found inside skill tree.", "Remove generated artifacts from the skill package.")

    body_lower = body.lower()
    for dirname in ("references", "scripts", "assets"):
        directory = skill_path / dirname
        if directory.exists() and dirname not in body_lower:
            report.add("warn", f"unmentioned-{dirname}", str(directory), f"{dirname}/ exists but is not mentioned in SKILL.md.", f"Add a resource map explaining when to use {dirname}/.")
        if directory.exists():
            for child in directory.iterdir():
                if child.is_file() and child.name.lower() not in body_lower:
                    report.add("warn", "unmentioned-resource", str(child), "Bundled resource is not named from SKILL.md.", "Reference this resource from SKILL.md or remove it if obsolete.")


def _check_links(report: SkillReport, skill_path: Path, body: str) -> None:
    for target in LINK_RE.findall(body):
        if target.startswith(("http://", "https://", "#", "mailto:")):
            continue
        clean = target.split("#", 1)[0].strip()
        if not clean:
            continue
        linked = (skill_path / clean).resolve()
        try:
            linked.relative_to(skill_path.resolve())
        except ValueError:
            report.add("warn", "link-outside-skill", "SKILL.md", f"Link points outside skill folder: {target}", "Use a relative bundled resource link or explain the external local dependency.")
            continue
        if not linked.exists():
            report.add("error", "broken-local-link", "SKILL.md", f"Broken local link: {target}", "Fix or remove the broken resource link.")


def _score_dimensions(report: SkillReport, fields: dict[str, str], body: str) -> None:
    lower = body.lower()
    description = fields.get("description", "")
    scores = {
        "import_readiness": 20,
        "description_activation": 20,
        "progressive_disclosure": 20,
        "procedural_specificity": 20,
        "resource_hygiene": 20,
    }

    if any(f.id.startswith(("missing-", "invalid-name", "broken-local-link")) and f.severity == "error" for f in report.findings):
        scores["import_readiness"] = 5
    trigger_markers = ("use when", "triggers on", "trigger", "when the user")
    if len(description) < 80 or not any(marker in description.lower() for marker in trigger_markers):
        scores["description_activation"] = 12
    if report.metrics["estimated_tokens"] > 5000:
        scores["progressive_disclosure"] = 10
    if not any(term in lower for term in ["workflow", "steps", "algorithm", "first minute", "quick rules"]):
        scores["procedural_specificity"] = 10
    if any(f.id in {"unmentioned-resource", "unexpected-top-level", "generated-artifact"} for f in report.findings):
        scores["resource_hygiene"] = 12
    report.scores = scores
