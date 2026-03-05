#!/usr/bin/env python3
"""Generate a 60-minute interview pack from level template + latest topics."""

from __future__ import annotations

import argparse
import datetime as dt
import re
from pathlib import Path


DOMAIN_LABEL = {"qt": "Qt", "cpp": "C++", "robotics": "Robotics"}
LEVEL_LABEL = {"junior": "Junior", "mid": "Mid", "senior": "Senior"}
HIRE_THRESHOLD = {
    "junior": "Avg >= 3.2 and no core domain < 2",
    "mid": "Avg >= 3.6 and no core domain < 3",
    "senior": "Avg >= 4.0 and system/risk dimension >= 4",
}


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Generate one-hour interview script and scorecard.")
    parser.add_argument("--domain", choices=["qt", "cpp", "robotics"], required=True)
    parser.add_argument("--level", choices=["junior", "mid", "senior"], required=True)
    parser.add_argument("--latest-count", type=int, default=2)
    parser.add_argument(
        "--levels-file",
        type=Path,
        default=root / "references" / "question-bank-levels-template.md",
    )
    parser.add_argument(
        "--latest-file",
        type=Path,
        default=root / "references" / "question-bank-latest.md",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Default: references/interview-pack-<domain>-<level>.md",
    )
    return parser.parse_args()


def extract_section(lines: list[str], heading: str) -> list[str]:
    start = None
    for i, line in enumerate(lines):
        if line.strip() == heading:
            start = i + 1
            break
    if start is None:
        return []

    end = len(lines)
    for j in range(start, len(lines)):
        if lines[j].startswith("## "):
            end = j
            break
    return lines[start:end]


def extract_level_domain_block(levels_text: str, level: str, domain: str) -> dict[str, list[str]]:
    lvl = LEVEL_LABEL[level]
    dom = DOMAIN_LABEL[domain]
    lines = levels_text.splitlines()

    pattern = re.compile(rf"^## \d+\.\d+ {re.escape(lvl)} \({re.escape(dom)}\)$")
    start = None
    for i, line in enumerate(lines):
        if pattern.match(line.strip()):
            start = i + 1
            break
    if start is None:
        raise ValueError(f"Cannot find section for {lvl} ({dom}) in levels template")

    end = len(lines)
    for j in range(start, len(lines)):
        if lines[j].startswith("## "):
            end = j
            break
    block = lines[start:end]

    questions = [re.sub(r"^- Q\d+:\s*", "", ln).strip() for ln in block if re.match(r"^- Q\d+:", ln.strip())]

    follow_ups: list[str] = []
    scoring: list[str] = []
    redlines: list[str] = []
    mode = ""
    for ln in block:
        t = ln.strip()
        if t == "Follow-up:":
            mode = "follow"
            continue
        if t == "Scoring anchors:":
            mode = "score"
            continue
        if t == "Redline:":
            mode = "red"
            continue
        if t.startswith("## "):
            mode = ""
        if t.startswith("- "):
            item = t[2:].strip()
            if mode == "follow":
                follow_ups.append(item)
            elif mode == "score":
                scoring.append(item)
            elif mode == "red":
                redlines.append(item)

    return {"questions": questions, "follow_ups": follow_ups, "scoring": scoring, "redlines": redlines}


def extract_latest_topics(latest_text: str, domain: str, count: int) -> list[tuple[str, str]]:
    lines = latest_text.splitlines()
    heading = f"## {DOMAIN_LABEL[domain]} Latest Topics -> Interview Question Templates"
    section = extract_section(lines, heading)
    if not section:
        return []

    topics: list[tuple[str, str]] = []
    current_title = ""
    for ln in section:
        m_title = re.match(r"^\d+\. Topic:\s*(.+)$", ln.strip())
        if m_title:
            current_title = m_title.group(1).strip()
            continue
        m_link = re.match(r"^- Source:\s*(.+)$", ln.strip())
        if m_link and current_title:
            topics.append((current_title, m_link.group(1).strip()))
            current_title = ""
            if len(topics) >= count:
                break
    return topics


def render_pack(domain: str, level: str, content: dict[str, list[str]], latest_topics: list[tuple[str, str]]) -> str:
    now = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    dom = DOMAIN_LABEL[domain]
    lvl = LEVEL_LABEL[level]

    q1, q2, q3 = (content["questions"] + ["(fill question)"] * 3)[:3]
    follow_lines = content["follow_ups"] or ["(add follow-up)"]
    score_lines = content["scoring"] or ["`3`: baseline correct answer with workable implementation"]
    red_lines = content["redlines"] or ["(define redline behavior)"]

    latest_block = []
    if latest_topics:
        for idx, (title, link) in enumerate(latest_topics, start=1):
            latest_block.append(f"{idx}. {title}")
            latest_block.append(f"   - Source: {link}")
            latest_block.append(f"   - Ask: Based on this topic, explain engineering impact and rollout/testing plan.")
    else:
        latest_block.append("1. No latest topics found. Run `update_question_bank.py` first.")

    return "\n".join(
        [
            f"# 60-Minute Interview Pack ({dom} / {lvl})",
            "",
            f"Generated at (UTC): {now}",
            "Duration: 60 minutes",
            "",
            "## Interview Agenda",
            "",
            "- 0-5 min: warm-up and context alignment",
            f"- 5-35 min: core technical questions ({lvl} level)",
            "- 35-45 min: latest-topic deep dive",
            "- 45-55 min: scenario tradeoff and risk discussion",
            "- 55-60 min: candidate questions and wrap-up",
            "",
            "## Core Questions",
            "",
            f"1. {q1}",
            f"2. {q2}",
            f"3. {q3}",
            "",
            "## Follow-up Script",
            "",
            *[f"- {x}" for x in follow_lines],
            "",
            "## Latest-Topic Deep Dive",
            "",
            *latest_block,
            "",
            "## Scoring Anchors (1-5)",
            "",
            *[f"- {x}" for x in score_lines],
            "",
            "## Redlines",
            "",
            *[f"- {x}" for x in red_lines],
            "",
            "## Scorecard",
            "",
            "| Dimension | Score (1-5) | Evidence |",
            "|-----------|-------------|----------|",
            f"| {dom} fundamentals | | |",
            f"| {dom} practical execution | | |",
            "| System/risk judgment | | |",
            "| Communication clarity | | |",
            "",
            "## Decision Rule",
            "",
            f"- Recommended threshold ({lvl}): {HIRE_THRESHOLD[level]}",
            "- Decision: Hire / Hold / No-hire",
            "- Notes: include 2-3 strongest evidence points",
            "",
        ]
    )


def main() -> int:
    args = parse_args()
    if args.latest_count <= 0:
        raise ValueError("--latest-count must be > 0")

    levels_text = args.levels_file.read_text(encoding="utf-8")
    latest_text = args.latest_file.read_text(encoding="utf-8")

    block = extract_level_domain_block(levels_text, args.level, args.domain)
    latest_topics = extract_latest_topics(latest_text, args.domain, args.latest_count)
    pack = render_pack(args.domain, args.level, block, latest_topics)

    if args.output is None:
        args.output = args.levels_file.parent / f"interview-pack-{args.domain}-{args.level}.md"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(pack, encoding="utf-8")
    print(f"Generated: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
