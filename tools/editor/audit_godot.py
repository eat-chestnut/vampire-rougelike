#!/usr/bin/env python3
"""Godot project static audit (hard paths, connect duplication risk, per-frame hotspots).

Usage:
  python3 tools/editor/audit_godot.py
  python3 tools/editor/audit_godot.py --report report.txt

Notes:
- Heuristics only (string/regex based). Review findings manually.
"""
from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Tuple

ROOT = Path(__file__).resolve().parents[2]

GD_EXTS = {".gd"}
SCENE_EXTS = {".tscn", ".tres"}

HARD_PATH_RE = re.compile(r"\b(get_node|get_node_or_null)\(\s*\"([^\"]+)\"\s*\)")
DOLLAR_PATH_RE = re.compile(r"\$\"([^\"]+)\"|\$([A-Za-z_][A-Za-z0-9_]*)")
NODEPATH_RE = re.compile(r"NodePath\(\s*\"([^\"]+)\"\s*\)")
CONNECT_RE = re.compile(r"\.connect\(")
FUNC_RE = re.compile(r"^\s*func\s+([A-Za-z0-9_]+)\s*\(")
PROCESS_RE = re.compile(r"^\s*func\s+(_process|_physics_process)\s*\(")

PROCESS_RISK_TOKENS = [
    ("get_nodes_in_group", "group query each frame"),
    ("find_children", "scene tree search each frame"),
    ("instantiate(", "instantiate each frame"),
    ("queue_free(", "queue_free each frame"),
    ("format(", "string formatting each frame"),
    ("str(", "string conversion each frame"),
]

CONNECT_RISK_FUNCS = {"_ready", "_enter_tree", "_process", "_physics_process", "on_spawn"}

@dataclass
class Finding:
    category: str
    path: Path
    line_no: int
    detail: str


def iter_files(root: Path, exts: Iterable[str]) -> Iterable[Path]:
    for base, _, files in os.walk(root):
        # skip .godot and hidden
        if Path(base).name.startswith(".") or "/.godot" in base.replace("\\", "/"):
            continue
        for name in files:
            p = Path(base) / name
            if p.suffix in exts:
                yield p


def scan_hard_paths() -> List[Finding]:
    findings: List[Finding] = []
    for path in iter_files(ROOT, GD_EXTS):
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            for m in HARD_PATH_RE.finditer(line):
                findings.append(Finding(
                    "hard_path",
                    path,
                    i,
                    f"{m.group(1)}(\"{m.group(2)}\")",
                ))
            m2 = DOLLAR_PATH_RE.search(line)
            if m2:
                target = m2.group(1) or m2.group(2)
                findings.append(Finding(
                    "hard_path",
                    path,
                    i,
                    f"$ reference -> {target}",
                ))
    for path in iter_files(ROOT, SCENE_EXTS):
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            m = NODEPATH_RE.search(line)
            if m:
                findings.append(Finding(
                    "nodepath",
                    path,
                    i,
                    f"NodePath(\"{m.group(1)}\")",
                ))
    return findings


def scan_connect_risks() -> List[Finding]:
    findings: List[Finding] = []
    for path in iter_files(ROOT, GD_EXTS):
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue
        current_func = None
        for i, line in enumerate(text.splitlines(), 1):
            m = FUNC_RE.match(line)
            if m:
                current_func = m.group(1)
            if current_func in CONNECT_RISK_FUNCS and ".connect(" in line:
                findings.append(Finding(
                    "connect_risk",
                    path,
                    i,
                    f"connect() inside {current_func}",
                ))
    return findings


def scan_process_hotspots() -> List[Finding]:
    findings: List[Finding] = []
    for path in iter_files(ROOT, GD_EXTS):
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except Exception:
            continue
        in_process = False
        for i, line in enumerate(lines, 1):
            if PROCESS_RE.match(line):
                in_process = True
                continue
            if in_process and line.startswith("func "):
                in_process = False
            if in_process:
                for token, reason in PROCESS_RISK_TOKENS:
                    if token in line:
                        findings.append(Finding(
                            "process_risk",
                            path,
                            i,
                            f"{reason}: {line.strip()}",
                        ))
    return findings


def render(findings: List[Finding]) -> str:
    def fmt(f: Finding) -> str:
        rel = f.path.relative_to(ROOT)
        return f"[{f.category}] {rel}:{f.line_no} -> {f.detail}"

    out: List[str] = []
    out.append("Godot Audit Report")
    out.append(f"Root: {ROOT}")
    out.append("")

    by_cat = {}
    for f in findings:
        by_cat.setdefault(f.category, []).append(f)

    for cat in ("hard_path", "nodepath", "connect_risk", "process_risk"):
        items = by_cat.get(cat, [])
        out.append(f"{cat}: {len(items)}")
        for f in items:
            out.append("  " + fmt(f))
        out.append("")

    return "\n".join(out).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", help="Write report to file")
    args = parser.parse_args()

    findings = []
    findings.extend(scan_hard_paths())
    findings.extend(scan_connect_risks())
    findings.extend(scan_process_hotspots())

    report = render(findings)
    print(report)

    if args.report:
        Path(args.report).write_text(report, encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
