"""Output rendering — console tables and JSON."""
from __future__ import annotations

import json
from dataclasses import asdict
from typing import Any

from arh_python_qa.findings import Finding, PipelineResult


def render_console(result: PipelineResult) -> None:
    try:
        from rich.console import Console
        from rich.table import Table
        console = Console()
    except ImportError:
        _render_plain(result)
        return

    console.print(f"\n[bold]ARH Python Toolkit — {result.mode.upper()} mode[/bold]")
    if result.project:
        console.print(f"Project: {result.project}")

    table = Table(show_header=True, header_style="bold")
    table.add_column("Tool")
    table.add_column("Status")
    table.add_column("Summary")

    for tr in result.results:
        icon = "[green]✓[/green]" if tr.passed else "[red]✗[/red]" if tr.severity == "error" else "[yellow]![/yellow]"
        table.add_row(tr.tool, icon, tr.summary)

    console.print(table)

    security_findings = [f for r in result.results for f in r.findings if f.category]
    if security_findings:
        console.print("\n[bold red]Security Findings by Category[/bold red]")
        cats: dict[str, list[Finding]] = {}
        for f in security_findings:
            cats.setdefault(f.category, []).append(f)
        for cat, items in sorted(cats.items()):
            console.print(f"\n[red]{cat}[/red] ({len(items)})")
            for it in items[:5]:
                console.print(f"  {it.file}:{it.line}  {it.code} {it.message}")
            if len(items) > 5:
                console.print(f"  ... and {len(items) - 5} more")

    color = "green" if result.overall_severity == "ok" else "yellow" if result.overall_severity == "warn" else "red"
    console.print(f"\nOverall: [bold {color}]{result.overall_severity.upper()}[/bold {color}]")


def _render_plain(result: PipelineResult) -> None:
    print(f"\nARH Python Toolkit — {result.mode.upper()} mode")
    if result.project:
        print(f"Project: {result.project}")
    print("-" * 50)
    for tr in result.results:
        icon = "PASS" if tr.passed else "FAIL" if tr.severity == "error" else "WARN"
        print(f"[{icon}] {tr.tool}: {tr.summary}")

    security_findings = [f for r in result.results for f in r.findings if f.category]
    if security_findings:
        print("\nSecurity Findings by Category:")
        cats: dict[str, list[Finding]] = {}
        for f in security_findings:
            cats.setdefault(f.category, []).append(f)
        for cat, items in sorted(cats.items()):
            print(f"\n  {cat} ({len(items)})")
            for it in items[:5]:
                print(f"    {it.file}:{it.line}  {it.code} {it.message}")
            if len(items) > 5:
                print(f"    ... and {len(items) - 5} more")

    print("-" * 50)
    print(f"Overall: {result.overall_severity.upper()}")


def render_json(result: PipelineResult) -> None:
    security_by_category: dict[str, list[dict[str, Any]]] = {}
    for r in result.results:
        for f in r.findings:
            if f.category:
                security_by_category.setdefault(f.category, []).append({
                    "file": f.file,
                    "line": f.line,
                    "column": f.column,
                    "code": f.code,
                    "message": f.message,
                })

    payload = {
        "mode": result.mode,
        "project": str(result.project) if result.project else None,
        "overall_severity": result.overall_severity,
        "fixable": result.fixable,
        "security_by_category": security_by_category,
        "results": [
            {
                "tool": r.tool,
                "cmd": r.cmd,
                "returncode": r.returncode,
                "passed": r.passed,
                "severity": r.severity,
                "summary": r.summary,
                "findings": [asdict(f) for f in r.findings],
            }
            for r in result.results
        ],
    }
    print(json.dumps(payload, indent=2))
