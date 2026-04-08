#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass


DEFAULT_QUERIES = [
    "topic:agent-skills",
    "topic:claude-code-skill",
    "topic:codex-skill",
    "topic:gemini-cli-skill",
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
    source: str


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
        "--seed-file",
        help="Optional file containing seed repositories (one per line).",
    )
    parser.add_argument(
        "--repo",
        action="append",
        dest="repos",
        help="Additional repository spec to include directly. Can be repeated.",
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
        help="Minimum stargazer count to keep in GitHub search output.",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json", "markdown"),
        default="text",
        help="Output format.",
    )
    return parser.parse_args()


def github_headers() -> dict[str, str]:
    headers = {
        "User-Agent": "skill-market-auditor",
        "Accept": "application/vnd.github+json",
    }
    github_token = os.environ.get("GITHUB_TOKEN")
    if github_token:
        headers["Authorization"] = f"Bearer {github_token}"
    return headers


def fetch_json(url: str) -> dict[str, object]:
    req = urllib.request.Request(url, headers=github_headers())
    with urllib.request.urlopen(req, timeout=20) as response:
        return json.load(response)


def load_list_file(path: str | None) -> list[str]:
    if not path:
        return []
    try:
        with open(path, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
    except FileNotFoundError:
        return []

    items: list[str] = []
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        items.append(line)
    return items


def normalize_repo_slug(repo_spec: str) -> str:
    cleaned = repo_spec.strip()
    if not cleaned:
        raise ValueError("empty repo spec")
    cleaned = cleaned.removesuffix(".git")
    cleaned = cleaned.split("@", 1)[0]
    match = re.search(r"github\.com[:/]+([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)", cleaned, re.IGNORECASE)
    if match:
        return match.group(1)
    if re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", cleaned):
        return cleaned
    raise ValueError(f"Unsupported repo spec: {repo_spec}")


def candidate_from_payload(
    item: dict[str, object],
    *,
    query: str,
    source: str,
) -> RepoCandidate:
    return RepoCandidate(
        full_name=str(item["full_name"]),
        html_url=str(item["html_url"]),
        description=str(item.get("description") or ""),
        stargazers_count=int(item.get("stargazers_count") or 0),
        updated_at=str(item.get("updated_at") or ""),
        default_branch=str(item.get("default_branch") or ""),
        topics=[str(topic) for topic in (item.get("topics") or [])],
        query=query,
        source=source,
    )


def fetch_query(query: str, per_query: int) -> list[RepoCandidate]:
    params = {
        "q": query,
        "sort": "stars",
        "order": "desc",
        "per_page": str(per_query),
    }
    url = "https://api.github.com/search/repositories?" + urllib.parse.urlencode(params)
    payload = fetch_json(url)

    items: list[RepoCandidate] = []
    for item in payload.get("items", []):
        if not isinstance(item, dict):
            continue
        items.append(candidate_from_payload(item, query=query, source="github-search"))
    return items


def fetch_repo(repo_spec: str, source: str) -> RepoCandidate:
    slug = normalize_repo_slug(repo_spec)
    url = f"https://api.github.com/repos/{slug}"
    payload = fetch_json(url)
    return candidate_from_payload(payload, query=repo_spec, source=source)


def merge_csv_values(*values: str) -> str:
    merged: list[str] = []
    seen: set[str] = set()
    for value in values:
        for part in value.split(","):
            cleaned = part.strip()
            if not cleaned or cleaned in seen:
                continue
            seen.add(cleaned)
            merged.append(cleaned)
    return ",".join(merged)


def merge_candidates(existing: RepoCandidate, incoming: RepoCandidate) -> RepoCandidate:
    preferred = incoming if incoming.stargazers_count > existing.stargazers_count else existing
    fallback = existing if preferred is incoming else incoming
    return RepoCandidate(
        full_name=preferred.full_name,
        html_url=preferred.html_url or fallback.html_url,
        description=preferred.description or fallback.description,
        stargazers_count=max(existing.stargazers_count, incoming.stargazers_count),
        updated_at=preferred.updated_at or fallback.updated_at,
        default_branch=preferred.default_branch or fallback.default_branch,
        topics=sorted(set(existing.topics + incoming.topics)),
        query=merge_csv_values(existing.query, incoming.query),
        source=merge_csv_values(existing.source, incoming.source),
    )


def dedupe_candidates(candidates: list[RepoCandidate], min_stars: int) -> list[RepoCandidate]:
    deduped: dict[str, RepoCandidate] = {}
    for candidate in candidates:
        if "github-search" in candidate.source.split(",") and candidate.stargazers_count < min_stars:
            if candidate.source == "github-search":
                continue
        current = deduped.get(candidate.full_name.lower())
        if current is None:
            deduped[candidate.full_name.lower()] = candidate
            continue
        deduped[candidate.full_name.lower()] = merge_candidates(current, candidate)
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
                f"  source: {candidate.source}",
                f"  url: {candidate.html_url}",
                f"  stars: {candidate.stargazers_count}",
                f"  updated_at: {candidate.updated_at}",
                f"  default_branch: {candidate.default_branch}",
                f"  query: {candidate.query or '-'}",
                f"  description: {candidate.description or '-'}",
            ]
        )
    return "\n".join(lines)


def render_markdown(candidates: list[RepoCandidate]) -> str:
    lines = [
        "## Marketplace Candidates",
        "",
        "| Repo | Source | Stars | Updated At | Default Branch | Query |",
        "|------|--------|-------|------------|----------------|-------|",
    ]
    for candidate in candidates:
        lines.append(
            f"| [{candidate.full_name}]({candidate.html_url}) | `{candidate.source}` | {candidate.stargazers_count} | {candidate.updated_at} | {candidate.default_branch} | `{candidate.query or '-'}` |"
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

    for repo_spec in load_list_file(args.seed_file):
        try:
            all_candidates.append(fetch_repo(repo_spec, "seed-file"))
        except Exception as exc:
            print(f"seed repo failed: {repo_spec}: {exc}", file=sys.stderr)

    for repo_spec in args.repos or []:
        try:
            all_candidates.append(fetch_repo(repo_spec, "extra-repo"))
        except Exception as exc:
            print(f"extra repo failed: {repo_spec}: {exc}", file=sys.stderr)

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
