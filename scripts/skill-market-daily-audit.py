#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import subprocess
import tempfile
import time
from collections import Counter
from datetime import datetime
from typing import Any


ROOT_DIR = pathlib.Path(__file__).resolve().parents[1]
VALIDATE_SCRIPT = ROOT_DIR / "scripts" / "validate-skills.sh"
MERGE_SCRIPT = ROOT_DIR / "scripts" / "merge-skill.py"
DISCOVER_SCRIPT = (
    ROOT_DIR / "skills" / "skill-market-auditor" / "scripts" / "discover_market_repos.py"
)
SCAN_SCRIPT = ROOT_DIR / "skills" / "skill-market-auditor" / "scripts" / "scan_skill_repo.py"
ALLOWLIST_FILE = ROOT_DIR / "scripts" / "manifest" / "skill-market-allowlist.txt"
SEED_FILE = ROOT_DIR / "scripts" / "manifest" / "market-seed-repos.txt"
BASELINE_MANIFEST = ROOT_DIR / "scripts" / "manifest" / "skills.txt"
REPORT_ROOT = ROOT_DIR / "reports" / "skill-market"
MATRIX_HELPER = ROOT_DIR / "scripts" / "notify-matrix.py"
SEVERITIES = ("critical", "high", "medium", "low")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Daily report-only audit pipeline for skill marketplace discovery and whitelist repo review."
    )
    parser.add_argument(
        "--report-root",
        default=str(REPORT_ROOT),
        help="Directory used to store generated reports.",
    )
    parser.add_argument(
        "--allowlist-file",
        default=str(ALLOWLIST_FILE),
        help="File containing whitelist repos (one per line).",
    )
    parser.add_argument(
        "--seed-file",
        default=str(SEED_FILE),
        help="File containing seed repos (one per line).",
    )
    parser.add_argument(
        "--per-query",
        type=int,
        default=10,
        help="Number of GitHub candidates fetched per discovery query.",
    )
    parser.add_argument(
        "--min-stars",
        type=int,
        default=10,
        help="Minimum stars kept in discovery results.",
    )
    parser.add_argument(
        "--notify-matrix",
        action="store_true",
        help="Send the full report to Matrix if MATRIX_* env vars are configured.",
    )
    parser.add_argument(
        "--deep-audit-repo",
        action="append",
        dest="deep_audit_repos",
        help="Additional repo spec to deep-audit. Can be repeated.",
    )
    return parser.parse_args()


def load_list_file(path: pathlib.Path) -> list[str]:
    if not path.exists():
        return []
    items: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        items.append(line)
    return items


def normalize_repo_slug(repo_spec: str) -> str:
    cleaned = repo_spec.strip()
    if not cleaned:
        return ""
    cleaned = cleaned.removesuffix(".git")
    cleaned = cleaned.split("@", 1)[0]
    match = re.search(r"github\.com[:/]+([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)", cleaned, re.IGNORECASE)
    if match:
        return match.group(1).lower()
    if re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", cleaned):
        return cleaned.lower()
    raise ValueError(f"Unsupported repo spec: {repo_spec}")


def slug_to_url(repo_spec: str) -> str:
    slug = normalize_repo_slug(repo_spec)
    return f"https://github.com/{slug}.git"


def safe_repo_dirname(repo_spec: str) -> str:
    return normalize_repo_slug(repo_spec).replace("/", "__")


def run_command(
    cmd: list[str],
    *,
    cwd: pathlib.Path,
    env: dict[str, str] | None = None,
    check: bool = False,
    retries: int = 0,
    retry_delay_seconds: float = 2.0,
) -> dict[str, Any]:
    last_payload: dict[str, Any] | None = None
    for attempt in range(retries + 1):
        started_at = datetime.now().astimezone().isoformat(timespec="seconds")
        result = subprocess.run(
            cmd,
            cwd=str(cwd),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        last_payload = {
            "cmd": cmd,
            "cwd": str(cwd),
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "started_at": started_at,
            "finished_at": datetime.now().astimezone().isoformat(timespec="seconds"),
            "attempt": attempt + 1,
        }
        if result.returncode == 0 or attempt >= retries:
            break
        time.sleep(retry_delay_seconds * (attempt + 1))

    assert last_payload is not None
    if check and last_payload["returncode"] != 0:
        raise subprocess.CalledProcessError(
            last_payload["returncode"],
            cmd,
            output=last_payload["stdout"],
            stderr=last_payload["stderr"],
        )
    return last_payload


def write_text(path: pathlib.Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_json(path: pathlib.Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read_json_output(command_result: dict[str, Any], label: str) -> Any:
    try:
        return json.loads(command_result["stdout"] or "null")
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{label} did not return valid JSON: {exc}") from exc


def severity_counts(findings: list[dict[str, Any]]) -> dict[str, int]:
    counts = Counter(finding.get("severity", "unknown") for finding in findings)
    return {severity: int(counts.get(severity, 0)) for severity in SEVERITIES}


def relative_to_repo(path: pathlib.Path) -> str:
    try:
        return str(path.relative_to(ROOT_DIR))
    except ValueError:
        return str(path)


def create_run_dir(report_root: pathlib.Path, generated_at: datetime) -> pathlib.Path:
    date_dir = generated_at.strftime("%Y-%m-%d")
    base_dir = report_root / "runs" / date_dir
    base_name = generated_at.strftime("%H%M%S")
    candidate = base_dir / base_name
    suffix = 1
    while candidate.exists():
        candidate = base_dir / f"{base_name}-{suffix:02d}"
        suffix += 1
    candidate.mkdir(parents=True, exist_ok=False)
    return candidate


def current_skill_count() -> int:
    return len(load_list_file(BASELINE_MANIFEST))


def clone_repo(repo_spec: str, target_dir: pathlib.Path) -> pathlib.Path:
    clone_dir = target_dir / safe_repo_dirname(repo_spec)
    ref = None
    if "@" in repo_spec and not repo_spec.startswith("http"):
        ref = repo_spec.split("@", 1)[1].strip()
    last_error = "git clone failed"
    for attempt in range(3):
        if clone_dir.exists():
            shutil.rmtree(clone_dir)
        cmd = [
            "git",
            "clone",
            "--depth",
            "1",
            "--single-branch",
            "--filter=blob:none",
            slug_to_url(repo_spec),
            str(clone_dir),
        ]
        if ref:
            cmd = [
                "git",
                "clone",
                "--depth",
                "1",
                "--single-branch",
                "--filter=blob:none",
                "--branch",
                ref,
                slug_to_url(repo_spec),
                str(clone_dir),
            ]
        try:
            result = subprocess.run(
                cmd,
                cwd=str(ROOT_DIR),
                check=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=180,
                env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
            )
        except subprocess.TimeoutExpired:
            last_error = f"git clone timed out after 180 seconds for {repo_spec}"
            if attempt < 2:
                time.sleep(attempt + 1)
            continue
        if result.returncode == 0:
            return clone_dir
        last_error = result.stderr.strip() or result.stdout.strip() or last_error
        if attempt < 2:
            time.sleep(attempt + 1)
    raise RuntimeError(last_error)


def read_skill_name(skill_md: pathlib.Path) -> str:
    try:
        lines = skill_md.read_text(encoding="utf-8", errors="ignore").splitlines()
    except OSError:
        return skill_md.parent.name
    if not lines or lines[0].strip() != "---":
        return skill_md.parent.name
    for line in lines[1:60]:
        if line.strip() == "---":
            break
        match = re.match(r"^name:\s*(.+?)\s*$", line)
        if match:
            return match.group(1).strip().strip("\"'")
    return skill_md.parent.name


def map_skill_files(repo_path: pathlib.Path) -> dict[str, pathlib.Path]:
    mapping: dict[str, pathlib.Path] = {}
    candidates = list(repo_path.glob("skills/*/SKILL.md"))
    if not candidates and (repo_path / "SKILL.md").is_file():
        candidates = [repo_path / "SKILL.md"]
    if not candidates:
        candidates = list(repo_path.rglob("SKILL.md"))
    for path in sorted(set(candidates)):
        if ".git" in path.parts:
            continue
        mapping[read_skill_name(path)] = path
    return mapping


def build_decision_summary(summary: dict[str, Any]) -> dict[str, Any]:
    counts = severity_counts(summary.get("findings", []))
    blocked = counts["critical"] > 0 or counts["high"] > 0
    overlap = summary.get("overlapping_skills", []) or []
    new_skills = summary.get("new_skills", []) or []
    recommendation = "reject" if blocked else "review"
    if not blocked and overlap:
        recommendation = "merge-preview"
    elif not blocked and new_skills:
        recommendation = "add"
    decisions = {
        "recommendation": recommendation,
        "add": [] if blocked else list(new_skills),
        "merge_preview": [] if blocked else list(overlap),
        "reject": list(sorted(set(overlap + new_skills))) if blocked else [],
        "severity_counts": counts,
    }
    return decisions


def render_findings_summary(counts: dict[str, int]) -> str:
    return " / ".join(f"{severity}={counts[severity]}" for severity in SEVERITIES)


def build_matrix_message(report_md_content: str, latest_report_path: pathlib.Path) -> str:
    content = report_md_content.rstrip()
    marker = "\n## Matrix Notification\n"
    if marker in content:
        content = content.split(marker, 1)[0].rstrip()
    return "\n".join(
        [
            content,
            "",
            "## Delivery",
            "",
            f"- Report file: `{relative_to_repo(latest_report_path)}`",
            "- Delivery mode: `full-report`",
        ]
    ).rstrip() + "\n"


def send_matrix_notification(message: str, run_dir: pathlib.Path) -> dict[str, Any]:
    message_path = run_dir / "artifacts" / "matrix.message.txt"
    write_text(message_path, message)
    helper_result = run_command(
        ["python3", str(MATRIX_HELPER), "--message-file", str(message_path)],
        cwd=ROOT_DIR,
        check=False,
        retries=2,
        retry_delay_seconds=3.0,
    )
    write_text(run_dir / "artifacts" / "matrix.stdout.txt", helper_result["stdout"])
    write_text(run_dir / "artifacts" / "matrix.stderr.txt", helper_result["stderr"])
    status = "sent"
    detail = (helper_result["stdout"] or helper_result["stderr"]).strip() or "sent"
    if helper_result["returncode"] == 2:
        status = "skipped"
    elif helper_result["returncode"] != 0:
        status = "failed"
    return {
        "status": status,
        "returncode": helper_result["returncode"],
        "detail": detail,
    }


def generate_merge_previews(
    repo_spec: str,
    audit_summary: dict[str, Any],
    run_dir: pathlib.Path,
) -> list[dict[str, Any]]:
    counts = severity_counts(audit_summary.get("findings", []))
    if counts["critical"] > 0 or counts["high"] > 0:
        return []
    if not audit_summary.get("overlapping_skills"):
        return []

    previews: list[dict[str, Any]] = []
    clone_root = run_dir / "tmp-clones"
    clone_root.mkdir(parents=True, exist_ok=True)
    clone_dir = clone_repo(repo_spec, clone_root)
    external_files = map_skill_files(clone_dir)

    try:
        for skill_name in audit_summary.get("overlapping_skills", []):
            local_skill = ROOT_DIR / "skills" / skill_name / "SKILL.md"
            incoming_skill = external_files.get(skill_name)
            if not local_skill.is_file() or incoming_skill is None or not incoming_skill.is_file():
                continue
            preview_dir = run_dir / "merge-previews" / safe_repo_dirname(repo_spec) / skill_name
            preview_dir.mkdir(parents=True, exist_ok=True)
            incoming_copy = preview_dir / "SKILL.incoming.md"
            merged_path = preview_dir / "SKILL.merged.md"
            report_path = preview_dir / "SKILL.merge-report.md"
            shutil.copy2(incoming_skill, incoming_copy)

            subprocess.run(
                [
                    "python3",
                    str(MERGE_SCRIPT),
                    "--base",
                    str(local_skill),
                    "--incoming",
                    str(incoming_copy),
                    "--output",
                    str(merged_path),
                    "--report",
                    str(report_path),
                    "--source",
                    f"{normalize_repo_slug(repo_spec)}@{audit_summary.get('commit') or 'unknown'}",
                ],
                cwd=str(ROOT_DIR),
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            previews.append(
                {
                    "repo": normalize_repo_slug(repo_spec),
                    "skill": skill_name,
                    "incoming": relative_to_repo(incoming_copy),
                    "merged": relative_to_repo(merged_path),
                    "report": relative_to_repo(report_path),
                }
            )
    finally:
        shutil.rmtree(clone_dir, ignore_errors=True)

    return previews


def render_markdown_report(report: dict[str, Any], latest_report_path: pathlib.Path) -> str:
    local = report["local"]
    lines = [
        "# Skill Market Daily Audit Report",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Repository root: `{relative_to_repo(ROOT_DIR) or '.'}`",
        f"- Mode: `report-only`",
        f"- Allowlist: `{', '.join(report['allowlist']) or 'none'}`",
        f"- Latest report path: `{relative_to_repo(latest_report_path)}`",
        "",
        "## Local Baseline",
        "",
        f"- `validate-skills.sh`: `{local['validate']['status']}`",
        f"- Current manifest skills: `{local['skill_count']}`",
        f"- Local self-audit findings: `{render_findings_summary(local['self_audit']['severity_counts'])}`",
        f"- Local self-audit report: `{local['self_audit']['artifact']}`",
        "",
        "## Marketplace Discovery",
        "",
        f"- Candidate count: `{report['discovery']['candidate_count']}`",
        f"- Seed repos: `{', '.join(report['discovery'].get('seed_repos') or []) or 'none'}`",
        f"- Discovery artifact: `{report['discovery']['artifact']}`",
        "",
        "| Repo | Source | Stars | Updated At | Whitelisted | Outcome |",
        "|------|--------|-------|------------|-------------|---------|",
    ]

    allowlist_set = {item.lower() for item in report["allowlist"]}
    deep_audit_repos = {
        item["repo"].lower(): "audit-failed" if "error" in item else "deep-audited"
        for item in report["deep_audits"]
    }
    for candidate in report["discovery"]["candidates"]:
        repo = candidate["full_name"]
        whitelisted = "yes" if repo.lower() in allowlist_set else "no"
        if repo.lower() in deep_audit_repos:
            outcome = deep_audit_repos[repo.lower()]
        elif whitelisted == "yes":
            outcome = "scheduled"
        else:
            outcome = "discovered-only"
        lines.append(
            f"| `{repo}` | `{candidate.get('source', '-')}` | {candidate['stargazers_count']} | {candidate['updated_at']} | {whitelisted} | {outcome} |"
        )

    if not report["discovery"]["candidates"]:
        lines.append("| `none` | `-` | 0 | - | - | discovery-empty |")

    lines.extend(
        [
            "",
            "## Deep Audits",
            "",
        ]
    )

    if not report["deep_audits"]:
        lines.append("- No whitelist repos were audited in this run.")
    else:
        for item in report["deep_audits"]:
            if "error" in item:
                lines.extend(
                    [
                        f"### `{item['repo']}`",
                        "",
                        f"- Status: `audit-failed`",
                        f"- Error: {item['error']}",
                        f"- Artifact: `{item['artifact']}`",
                        "",
                    ]
                )
                continue
            summary = item["summary"]
            decisions = item["decisions"]
            lines.extend(
                [
                    f"### `{item['repo']}`",
                    "",
                    f"- Commit: `{summary.get('commit') or 'unknown'}`",
                    f"- Layout: `{summary.get('layout')}`",
                    f"- Findings: `{render_findings_summary(decisions['severity_counts'])}`",
                    f"- Overlapping skills: `{', '.join(summary.get('overlapping_skills') or []) or 'none'}`",
                    f"- New skills: `{', '.join(summary.get('new_skills') or []) or 'none'}`",
                    f"- Recommendation: `{decisions['recommendation']}`",
                    f"- Audit artifact: `{item['artifact']}`",
                    "",
                ]
            )

    lines.extend(
        [
            "## Merge Preview Artifacts",
            "",
        ]
    )

    if not report["merge_previews"]:
        lines.append("- No merge-preview artifacts were generated.")
    else:
        lines.append("| Repo | Skill | Merged | Report |")
        lines.append("|------|-------|--------|--------|")
        for preview in report["merge_previews"]:
            lines.append(
                f"| `{preview['repo']}` | `{preview['skill']}` | `{preview['merged']}` | `{preview['report']}` |"
            )

    decisions = report["decisions"]
    lines.extend(
        [
            "",
            "## Decision Summary",
            "",
            f"- add: `{', '.join(decisions['add']) or 'none'}`",
            f"- merge-preview: `{', '.join(decisions['merge_preview']) or 'none'}`",
            f"- reject: `{', '.join(decisions['reject']) or 'none'}`",
            f"- audit-failed: `{', '.join(decisions['audit_failed']) or 'none'}`",
            f"- discovered-only: `{', '.join(decisions['discovered_only']) or 'none'}`",
            "",
        ]
    )
    lines.extend(["## Warnings", ""])
    if not report["warnings"]:
        lines.append("- none")
    else:
        for warning in report["warnings"]:
            lines.append(f"- {warning}")
    lines.extend(
        [
            "",
            "## Matrix Notification",
            "",
            f"- Requested: `{str(report['matrix']['requested']).lower()}`",
            f"- Status: `{report['matrix']['status']}`",
            f"- Detail: {report['matrix']['detail']}",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    args = parse_args()
    generated_at = datetime.now().astimezone()
    report_root = pathlib.Path(args.report_root).resolve()
    run_dir = create_run_dir(report_root, generated_at)
    local_scan_excludes: list[str] = []
    try:
        local_scan_excludes.append(str(report_root.relative_to(ROOT_DIR)).replace("\\", "/"))
    except ValueError:
        pass

    allowlist_specs = load_list_file(pathlib.Path(args.allowlist_file))
    if args.deep_audit_repos:
        allowlist_specs.extend(args.deep_audit_repos)
    allowlist_specs = list(dict.fromkeys(allowlist_specs))
    allowlist_slugs = [normalize_repo_slug(spec) for spec in allowlist_specs]

    report: dict[str, Any] = {
        "generated_at": generated_at.isoformat(timespec="seconds"),
        "status": "ok",
        "allowlist": allowlist_slugs,
        "report_dir": relative_to_repo(run_dir),
        "local": {},
        "discovery": {},
        "deep_audits": [],
        "merge_previews": [],
        "decisions": {
            "add": [],
            "merge_preview": [],
            "reject": [],
            "audit_failed": [],
            "discovered_only": [],
        },
        "matrix": {
            "requested": bool(args.notify_matrix),
            "status": "skipped",
            "detail": "matrix notification not requested",
        },
        "warnings": [],
    }

    validate_result = run_command(["bash", str(VALIDATE_SCRIPT)], cwd=ROOT_DIR, check=False)
    write_text(run_dir / "artifacts" / "validate-skills.stdout.txt", validate_result["stdout"])
    write_text(run_dir / "artifacts" / "validate-skills.stderr.txt", validate_result["stderr"])
    report["local"]["validate"] = {
        "status": "passed" if validate_result["returncode"] == 0 else "failed",
        "returncode": validate_result["returncode"],
        "stdout": relative_to_repo(run_dir / "artifacts" / "validate-skills.stdout.txt"),
        "stderr": relative_to_repo(run_dir / "artifacts" / "validate-skills.stderr.txt"),
    }
    if validate_result["returncode"] != 0:
        report["status"] = "attention"

    local_scan_result = run_command(
        [
            "python3",
            str(SCAN_SCRIPT),
            "--repo",
            ".",
            "--baseline-manifest",
            str(BASELINE_MANIFEST),
            "--format",
            "json",
            *[item for pattern in local_scan_excludes for item in ("--exclude", pattern)],
        ],
        cwd=ROOT_DIR,
        check=True,
    )
    local_scan_summary = read_json_output(local_scan_result, "local self-audit")
    write_json(run_dir / "artifacts" / "local-self-audit.json", local_scan_summary)
    local_counts = severity_counts(local_scan_summary.get("findings", []))
    report["local"]["skill_count"] = current_skill_count()
    report["local"]["self_audit"] = {
        "severity_counts": local_counts,
        "artifact": relative_to_repo(run_dir / "artifacts" / "local-self-audit.json"),
    }
    if local_counts["critical"] > 0 or local_counts["high"] > 0 or local_counts["medium"] > 0:
        report["status"] = "attention"

    discovery_result = run_command(
        [
            "python3",
            str(DISCOVER_SCRIPT),
            "--seed-file",
            str(args.seed_file),
            "--per-query",
            str(args.per_query),
            "--min-stars",
            str(args.min_stars),
            "--format",
            "json",
        ],
        cwd=ROOT_DIR,
        check=False,
        retries=1,
    )
    write_text(run_dir / "artifacts" / "market-discovery.stderr.txt", discovery_result["stderr"])
    discovery_candidates: list[dict[str, Any]] = []
    discovery_artifact = run_dir / "artifacts" / "market-discovery.json"
    if discovery_result["returncode"] == 0:
        discovery_candidates = read_json_output(discovery_result, "market discovery")
        write_json(discovery_artifact, discovery_candidates)
        if discovery_result["stderr"].strip():
            report["status"] = "attention"
            report["warnings"].append("market discovery returned partial stderr output")
    else:
        report["status"] = "attention"
        report["warnings"].append("market discovery command failed")
        discovery_artifact = run_dir / "artifacts" / "market-discovery.stderr.txt"
        write_text(discovery_artifact, discovery_result["stderr"] or discovery_result["stdout"])

    seed_specs = load_list_file(pathlib.Path(args.seed_file))
    seed_slugs = [normalize_repo_slug(spec) for spec in seed_specs]
    report["discovery"] = {
        "candidate_count": len(discovery_candidates),
        "candidates": discovery_candidates,
        "artifact": relative_to_repo(discovery_artifact),
        "seed_repos": seed_slugs,
    }

    discovered_only = sorted(
        {
            candidate["full_name"]
            for candidate in discovery_candidates
            if candidate["full_name"].lower() not in {item.lower() for item in allowlist_slugs}
        }
    )
    report["decisions"]["discovered_only"] = discovered_only

    deep_audit_specs = list(dict.fromkeys(allowlist_specs))
    for repo_spec in deep_audit_specs:
        audit_result = run_command(
            [
                "python3",
                str(SCAN_SCRIPT),
                "--repo",
                repo_spec,
                "--baseline-manifest",
                str(BASELINE_MANIFEST),
                "--format",
                "json",
            ],
            cwd=ROOT_DIR,
            check=False,
            retries=2,
        )
        audit_path = run_dir / "artifacts" / "audits" / f"{safe_repo_dirname(repo_spec)}.json"
        if audit_result["returncode"] != 0:
            write_text(audit_path.with_suffix(".stderr.txt"), audit_result["stderr"])
            report["status"] = "attention"
            report["warnings"].append(f"deep audit failed for {repo_spec}")
            report["deep_audits"].append(
                {
                    "repo": normalize_repo_slug(repo_spec),
                    "artifact": relative_to_repo(audit_path.with_suffix(".stderr.txt")),
                    "error": (audit_result["stderr"] or audit_result["stdout"]).strip() or "unknown error",
                }
            )
            report["decisions"]["audit_failed"].append(normalize_repo_slug(repo_spec))
            continue

        audit_summary = read_json_output(audit_result, f"deep audit {repo_spec}")
        write_json(audit_path, audit_summary)
        decisions = build_decision_summary(audit_summary)
        merge_previews = generate_merge_previews(repo_spec, audit_summary, run_dir)
        report["merge_previews"].extend(merge_previews)
        report["deep_audits"].append(
            {
                "repo": normalize_repo_slug(repo_spec),
                "artifact": relative_to_repo(audit_path),
                "summary": audit_summary,
                "decisions": decisions,
            }
        )
        report["decisions"]["add"].extend(
            f"{normalize_repo_slug(repo_spec)}:{skill}" for skill in decisions["add"]
        )
        report["decisions"]["merge_preview"].extend(
            f"{normalize_repo_slug(repo_spec)}:{skill}" for skill in decisions["merge_preview"]
        )
        report["decisions"]["reject"].extend(
            f"{normalize_repo_slug(repo_spec)}:{skill}" for skill in decisions["reject"]
        )
        if (
            decisions["severity_counts"]["critical"] > 0
            or decisions["severity_counts"]["high"] > 0
            or decisions["severity_counts"]["medium"] > 0
        ):
            report["status"] = "attention"

    for key in ("add", "merge_preview", "reject", "audit_failed", "discovered_only"):
        report["decisions"][key] = sorted(set(report["decisions"][key]))

    summary_json_path = run_dir / "summary.json"
    write_json(summary_json_path, report)
    latest_json_path = pathlib.Path(args.report_root).resolve() / "latest.json"
    shutil.copy2(summary_json_path, latest_json_path)

    report_md_path = run_dir / "report.md"
    latest_md_path = pathlib.Path(args.report_root).resolve() / "latest.md"
    report_md_content = render_markdown_report(report, latest_md_path)
    write_text(report_md_path, report_md_content)
    shutil.copy2(report_md_path, latest_md_path)

    if args.notify_matrix:
        matrix_message = build_matrix_message(report_md_content, latest_md_path)
        matrix_result = send_matrix_notification(matrix_message, run_dir)
        report["matrix"] = {
            "requested": True,
            **matrix_result,
        }
        if report["matrix"]["status"] == "failed":
            report["status"] = "attention"
            report["warnings"].append("matrix notification failed")
        write_json(summary_json_path, report)
        report_md_content = render_markdown_report(report, latest_md_path)
        write_text(report_md_path, report_md_content)
        shutil.copy2(summary_json_path, latest_json_path)
        shutil.copy2(report_md_path, latest_md_path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
