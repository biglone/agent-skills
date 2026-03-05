#!/usr/bin/env python3
"""Generate latest interview question bank topics from public RSS feeds."""

from __future__ import annotations

import argparse
import datetime as dt
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path


FEEDS: dict[str, list[str]] = {
    "qt": [
        "https://www.qt.io/blog/rss.xml",
        "https://www.qt.io/blog",
    ],
    "cpp": [
        "https://isocpp.org/blog/rss",
        "https://www.modernescpp.com/index.php/feed/",
    ],
    "robotics": [
        "https://github.com/ros2/ros2/releases.atom",
        "https://github.com/ros-planning/navigation2/releases.atom",
        "https://discourse.ros.org/latest.rss",
        "http://export.arxiv.org/rss/cs.RO",
    ],
}

DOMAIN_KEYWORDS: dict[str, tuple[str, ...]] = {
    "qt": ("qt", "qml", "qt creator", "signal", "slot", "widgets", "qml"),
    "cpp": ("c++", "cpp", "std::", "template", "ranges", "allocator", "move semantics"),
    "robotics": (
        "ros",
        "robot",
        "robotics",
        "gazebo",
        "nav2",
        "moveit",
        "slam",
        "control",
        "perception",
        "autonomy",
        "simulation",
        "rclcpp",
    ),
}


def fetch_rss_items(url: str, limit: int = 6, timeout: int = 20) -> list[dict[str, str]]:
    req = urllib.request.Request(url, headers={"User-Agent": "agent-skills-question-updater/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = resp.read()

    root = ET.fromstring(data)
    items: list[dict[str, str]] = []

    for item in root.findall(".//item"):
        title = (item.findtext("title") or "").strip()
        link = (item.findtext("link") or "").strip()
        pub = (item.findtext("pubDate") or item.findtext("dc:date") or "").strip()
        if not title:
            continue
        items.append({"title": title, "link": link, "published": pub})
        if len(items) >= limit:
            return items

    # Atom fallback
    atom_entries = root.findall(".//{http://www.w3.org/2005/Atom}entry")
    for entry in atom_entries:
        title = (entry.findtext("{http://www.w3.org/2005/Atom}title") or "").strip()
        link_node = entry.find("{http://www.w3.org/2005/Atom}link")
        link = ""
        if link_node is not None:
            link = (link_node.attrib.get("href") or "").strip()
        pub = (
            entry.findtext("{http://www.w3.org/2005/Atom}updated")
            or entry.findtext("{http://www.w3.org/2005/Atom}published")
            or ""
        ).strip()
        if not title:
            continue
        items.append({"title": title, "link": link, "published": pub})
        if len(items) >= limit:
            break

    return items


def collect_domain_items(domain: str, limit: int) -> tuple[list[dict[str, str]], list[str]]:
    errors: list[str] = []
    for url in FEEDS[domain]:
        try:
            items = fetch_rss_items(url, limit=limit)
            items = filter_domain_items(domain, items)
            if items:
                return items, errors
            errors.append(f"{url}: no items found")
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ET.ParseError) as exc:
            errors.append(f"{url}: {exc}")
    return [], errors


def filter_domain_items(domain: str, items: list[dict[str, str]]) -> list[dict[str, str]]:
    if domain in {"qt", "cpp"}:
        return items
    keywords = DOMAIN_KEYWORDS.get(domain, ())
    if not keywords:
        return items
    filtered: list[dict[str, str]] = []
    for item in items:
        hay = f"{item.get('title', '')}".lower()
        if any(k in hay for k in keywords):
            filtered.append(item)
    return filtered


def build_question_lines(domain_label: str, items: list[dict[str, str]]) -> str:
    if not items:
        return "- No live topics available. Use template fallback and WebSearch for latest updates."

    lines: list[str] = []
    for idx, item in enumerate(items, start=1):
        title = item["title"]
        link = item["link"] or "(no link)"
        pub = item["published"] or "unknown date"
        lines.append(f"{idx}. Topic: {title}")
        lines.append(f"   - Source: {link}")
        lines.append(f"   - Published: {pub}")
        lines.append(
            "   - Question template: "
            f"[{domain_label}] Based on this topic, explain the engineering impact, "
            "propose implementation/testing plan, and state production risks."
        )
        lines.append("   - Follow-up: What tradeoff would you make under a 2-week deadline?")
        lines.append("   - Scoring anchors: correctness / depth / tradeoff / validation")
    return "\n".join(lines)


def render_markdown(max_items: int) -> str:
    now = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    qt_items, qt_errors = collect_domain_items("qt", max_items)
    cpp_items, cpp_errors = collect_domain_items("cpp", max_items)
    robo_items, robo_errors = collect_domain_items("robotics", max_items)

    notes: list[str] = []
    for err in qt_errors + cpp_errors + robo_errors:
        notes.append(f"- {err}")
    notes_text = "\n".join(notes) if notes else "- All configured feeds fetched successfully."

    sections = [
        "# Auto-updated Qt / C++ / Robotics Question Bank",
        "",
        f"Generated at (UTC): {now}",
        f"Max items per domain: {max_items}",
        "",
        "This file is generated by `scripts/update_question_bank.py`.",
        "Do not edit manually.",
        "",
        "## Qt Latest Topics -> Interview Question Templates",
        "",
        build_question_lines("Qt", qt_items),
        "",
        "## C++ Latest Topics -> Interview Question Templates",
        "",
        build_question_lines("C++", cpp_items),
        "",
        "## Robotics Latest Topics -> Interview Question Templates",
        "",
        build_question_lines("Robotics", robo_items),
        "",
        "## Refresh Notes",
        "",
        notes_text,
        "",
    ]
    return "\n".join(sections)


def parse_args() -> argparse.Namespace:
    skill_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Update dynamic question bank from RSS feeds.")
    parser.add_argument("--max-items", type=int, default=6, help="Number of topics per domain.")
    parser.add_argument(
        "--output",
        type=Path,
        default=skill_root / "references" / "question-bank-latest.md",
        help="Output markdown path.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.max_items <= 0:
        raise ValueError("--max-items must be > 0")
    content = render_markdown(args.max_items)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(content, encoding="utf-8")
    print(f"Updated: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
