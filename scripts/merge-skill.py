#!/usr/bin/env python3
"""
Merge two SKILL.md files by preserving local content and appending external strengths.

Output:
  - merged markdown file
  - merge report markdown
"""

from __future__ import annotations

import argparse
import hashlib
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Sequence, Tuple


HEADING_RE = re.compile(r"^(#{1,6})\s+(.*\S)\s*$")


@dataclass
class Section:
    heading: str
    level: int
    key: str
    lines: List[str]

    @property
    def content(self) -> str:
        return "\n".join(self.lines).strip()


def parse_frontmatter_and_body(text: str) -> Tuple[Dict[str, str], str]:
    lines = text.splitlines()
    if len(lines) >= 3 and lines[0].strip() == "---":
        end_idx = -1
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                end_idx = i
                break
        if end_idx != -1:
            fm_raw = lines[1:end_idx]
            body = "\n".join(lines[end_idx + 1 :]).strip()
            fm = {}
            for ln in fm_raw:
                if ":" not in ln:
                    continue
                k, v = ln.split(":", 1)
                fm[k.strip()] = v.strip()
            return fm, body
    return {}, text.strip()


def normalize_key(s: str) -> str:
    lowered = s.strip().lower()
    lowered = re.sub(r"[`*_~]", "", lowered)
    lowered = re.sub(r"\s+", " ", lowered)
    lowered = re.sub(r"[^0-9a-zA-Z\u4e00-\u9fff ]+", "", lowered)
    return lowered.strip()


def split_sections(body: str) -> Tuple[List[str], List[Section]]:
    if not body.strip():
        return [], []

    lines = body.splitlines()
    preamble: List[str] = []
    sections: List[Section] = []
    current: Section | None = None

    for ln in lines:
        m = HEADING_RE.match(ln)
        if m:
            if current is not None:
                sections.append(current)
            heading = m.group(2).strip()
            level = len(m.group(1))
            current = Section(heading=heading, level=level, key=normalize_key(heading), lines=[ln])
            continue

        if current is None:
            preamble.append(ln)
        else:
            current.lines.append(ln)

    if current is not None:
        sections.append(current)

    return preamble, sections


def unique_union_csv(a: str, b: str) -> str:
    def split_csv(value: str) -> List[str]:
        if not value:
            return []
        return [x.strip() for x in value.split(",") if x.strip()]

    out: List[str] = []
    seen = set()
    for item in split_csv(a) + split_csv(b):
        low = item.lower()
        if low in seen:
            continue
        seen.add(low)
        out.append(item)
    return ", ".join(out)


def make_frontmatter(base: Dict[str, str], incoming: Dict[str, str]) -> Dict[str, str]:
    merged = dict(base)

    if "related-skills" in base or "related-skills" in incoming:
        merged["related-skills"] = unique_union_csv(base.get("related-skills", ""), incoming.get("related-skills", ""))
    if "allowed-tools" in base or "allowed-tools" in incoming:
        merged["allowed-tools"] = unique_union_csv(base.get("allowed-tools", ""), incoming.get("allowed-tools", ""))

    # Keep local identity fields as source of truth, only fill if missing.
    for k, v in incoming.items():
        if k in {"name", "description", "related-skills", "allowed-tools"}:
            continue
        if k not in merged or not merged[k]:
            merged[k] = v

    return merged


def content_fingerprint(text: str) -> str:
    normalized = re.sub(r"\s+", " ", text.strip().lower())
    return hashlib.sha1(normalized.encode("utf-8")).hexdigest()


def merge_body(
    base_body: str,
    incoming_body: str,
    source_slug: str,
) -> Tuple[str, Dict[str, Sequence[str]]]:
    base_preamble, base_sections = split_sections(base_body)
    _, incoming_sections = split_sections(incoming_body)

    base_index = {s.key: s for s in base_sections if s.key}
    base_hashes = {content_fingerprint(s.content) for s in base_sections}

    new_sections: List[Section] = []
    enrich_sections: List[str] = []
    skipped_sections: List[str] = []

    for sec in incoming_sections:
        fp = content_fingerprint(sec.content)
        if fp in base_hashes:
            skipped_sections.append(sec.heading)
            continue

        existing = base_index.get(sec.key)
        if existing is None:
            new_sections.append(sec)
            continue

        # Same topic but different content: include as "补充".
        if len(sec.content) > max(180, int(len(existing.content) * 0.6)):
            enrich_sections.append(sec.content)
        else:
            skipped_sections.append(sec.heading)

    lines: List[str] = []
    lines.extend(base_preamble)
    if base_preamble and base_sections:
        lines.append("")
    for sec in base_sections:
        lines.extend(sec.lines)
        lines.append("")

    if new_sections or enrich_sections:
        if lines and lines[-1] != "":
            lines.append("")
        lines.append("## External Enhancements")
        lines.append(f"> Source: `{source_slug}`")
        lines.append("")

        for sec in new_sections:
            lines.extend(sec.lines)
            lines.append("")

        if enrich_sections:
            lines.append("### Conflict-Aware Supplements")
            lines.append("")
            for idx, content in enumerate(enrich_sections, start=1):
                lines.append(f"#### Supplement {idx}")
                lines.append("")
                lines.extend(content.splitlines())
                lines.append("")

    merged_body = "\n".join(lines).rstrip() + "\n"
    meta = {
        "new_sections": [s.heading for s in new_sections],
        "enrich_count": [str(len(enrich_sections))],
        "skipped_sections": skipped_sections,
    }
    return merged_body, meta


def dump_frontmatter(fm: Dict[str, str]) -> str:
    if not fm:
        return ""
    # stable output order
    preferred = ["name", "description", "allowed-tools", "related-skills"]
    keys = [k for k in preferred if k in fm] + [k for k in fm.keys() if k not in preferred]
    lines = ["---"]
    for k in keys:
        lines.append(f"{k}: {fm[k]}")
    lines.append("---")
    return "\n".join(lines) + "\n\n"


def render_report(
    source_slug: str,
    base_path: Path,
    incoming_path: Path,
    merged_path: Path,
    merged_fm: Dict[str, str],
    meta: Dict[str, Sequence[str]],
) -> str:
    new_sections = list(meta.get("new_sections", []))
    skipped_sections = list(meta.get("skipped_sections", []))
    enrich_count = int((meta.get("enrich_count") or ["0"])[0])

    lines = [
        "# Skill Merge Report",
        "",
        f"- source: `{source_slug}`",
        f"- base: `{base_path}`",
        f"- incoming: `{incoming_path}`",
        f"- merged: `{merged_path}`",
        "",
        "## Frontmatter",
        "",
    ]
    if merged_fm:
        for k, v in merged_fm.items():
            lines.append(f"- {k}: {v}")
    else:
        lines.append("- (none)")

    lines.extend(
        [
            "",
            "## Body Merge Summary",
            "",
            f"- appended new sections: {len(new_sections)}",
            f"- conflict supplements: {enrich_count}",
            f"- skipped as duplicate/noise: {len(skipped_sections)}",
            "",
        ]
    )

    if new_sections:
        lines.append("### Added Sections")
        lines.append("")
        for x in new_sections:
            lines.append(f"- {x}")
        lines.append("")

    if skipped_sections:
        lines.append("### Skipped Sections")
        lines.append("")
        for x in skipped_sections:
            lines.append(f"- {x}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Merge two SKILL markdown files")
    parser.add_argument("--base", required=True, help="existing local SKILL.md path")
    parser.add_argument("--incoming", required=True, help="incoming SKILL.md path")
    parser.add_argument("--output", required=True, help="output merged markdown path")
    parser.add_argument("--report", required=True, help="output merge report path")
    parser.add_argument("--source", required=True, help="source repo slug")
    args = parser.parse_args()

    base_path = Path(args.base)
    incoming_path = Path(args.incoming)
    output_path = Path(args.output)
    report_path = Path(args.report)

    if not base_path.is_file():
        raise SystemExit(f"base file not found: {base_path}")
    if not incoming_path.is_file():
        raise SystemExit(f"incoming file not found: {incoming_path}")

    base_text = base_path.read_text(encoding="utf-8", errors="ignore")
    incoming_text = incoming_path.read_text(encoding="utf-8", errors="ignore")

    base_fm, base_body = parse_frontmatter_and_body(base_text)
    incoming_fm, incoming_body = parse_frontmatter_and_body(incoming_text)

    merged_fm = make_frontmatter(base_fm, incoming_fm)
    merged_body, meta = merge_body(base_body, incoming_body, args.source)

    merged_text = dump_frontmatter(merged_fm) + merged_body
    output_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(merged_text, encoding="utf-8")
    report_path.write_text(
        render_report(
            source_slug=args.source,
            base_path=base_path,
            incoming_path=incoming_path,
            merged_path=output_path,
            merged_fm=merged_fm,
            meta=meta,
        ),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
