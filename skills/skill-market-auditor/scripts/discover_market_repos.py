#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass


DEFAULT_QUERIES = [
    "topic:agent-skills",
    "topic:claude-code-skill",
    "topic:codex-skill",
]


@dataclass
class RepoCandidate:
    full_name: str
    html_url: str
    description: str
    stargazers_count: int
    updated_at: str
    default_branch: str
    topics: list[str]
    query: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Discover candidate skill marketplace repositories from GitHub search."
    )
    parser.add_argument(
        "--query",
        action="append",
        dest="queries",
        help="GitHub repository search query. Can be passed multiple times.",
    )
    parser.add_argument(
        "--per-query",
        type=int,
        default=10,
        help="Maximum number of repositories fetched per query.",
    )
    parser.add_argument(
        "--min-stars",
        type=int,
        default=10,
        help="Minimum stargazer count to keep in the output.",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json", "markdown"),
        default="text",
        help="Output format.",
    )
    return parser.parse_args()


def fetch_query(query: str, per_query: int) -> list[RepoCandidate]:
    params = {
        "q": query,
        "sort": "stars",
        "order": "desc",
        "per_page": str(per_query),
    }
    url = "https://api.github.com/search/repositories?" + urllib.parse.urlencode(params)
    headers = {
        "User-Agent": "skill-market-auditor",
        "Accept": "application/vnd.github+json",
    }
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=20) as response:
        payload = json.load(response)

    items = []
    for item in payload.get("items", []):
        items.append(
            RepoCandidate(
                full_name=item["full_name"],
                html_url=item["html_url"],
                description=item.get("description") or "",
                stargazers_count=item["stargazers_count"],
                updated_at=item["updated_at"],
                default_branch=item.get("default_branch") or "",
                topics=item.get("topics") or [],
                query=query,
            )
        )
    return items


def dedupe_candidates(candidates: list[RepoCandidate], min_stars: int) -> list[RepoCandidate]:
    deduped: dict[str, RepoCandidate] = {}
    for candidate in candidates:
        if candidate.stargazers_count < min_stars:
            continue
        current = deduped.get(candidate.full_name)
        if current is None or candidate.stargazers_count > current.stargazers_count:
            deduped[candidate.full_name] = candidate
    return sorted(
        deduped.values(),
        key=lambda item: (-item.stargazers_count, item.full_name.lower()),
    )


def render_text(candidates: list[RepoCandidate]) -> str:
    lines = [f"Candidates: {len(candidates)}"]
    for candidate in candidates:
        lines.extend(
            [
                f"- {candidate.full_name}",
                f"  url: {candidate.html_url}",
                f"  stars: {candidate.stargazers_count}",
                f"  updated_at: {candidate.updated_at}",
                f"  default_branch: {candidate.default_branch}",
                f"  query: {candidate.query}",
                f"  description: {candidate.description or '-'}",
            ]
        )
    return "\n".join(lines)


def render_markdown(candidates: list[RepoCandidate]) -> str:
    lines = [
        "## Marketplace Candidates",
        "",
        "| Repo | Stars | Updated At | Default Branch | Query |",
        "|------|-------|------------|----------------|-------|",
    ]
    for candidate in candidates:
        lines.append(
            f"| [{candidate.full_name}]({candidate.html_url}) | {candidate.stargazers_count} | {candidate.updated_at} | {candidate.default_branch} | `{candidate.query}` |"
        )
    return "\n".join(lines)


def render_json(candidates: list[RepoCandidate]) -> str:
    return json.dumps([asdict(candidate) for candidate in candidates], ensure_ascii=False, indent=2)


def main() -> int:
    args = parse_args()
    queries = args.queries or DEFAULT_QUERIES
    all_candidates: list[RepoCandidate] = []

    for query in queries:
        try:
            all_candidates.extend(fetch_query(query, args.per_query))
        except Exception as exc:
            print(f"query failed: {query}: {exc}", file=sys.stderr)

    candidates = dedupe_candidates(all_candidates, args.min_stars)

    if args.format == "json":
        print(render_json(candidates))
    elif args.format == "markdown":
        print(render_markdown(candidates))
    else:
        print(render_text(candidates))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
