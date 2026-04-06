#!/usr/bin/env python3

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from typing import Iterable


SEVERITY_ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3}
TEXT_SUFFIXES = {
    ".md",
    ".txt",
    ".py",
    ".sh",
    ".bash",
    ".zsh",
    ".ps1",
    ".js",
    ".ts",
    ".tsx",
    ".jsx",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
    ".ini",
    ".cfg",
    ".conf",
    ".env",
    ".xml",
    ".html",
    ".css",
    ".csv",
}
MAX_FILE_BYTES = 1_000_000
BIDI_AND_HIDDEN_CHARS = {
    "\u200b",
    "\u200c",
    "\u200d",
    "\u2060",
    "\ufeff",
    "\u202a",
    "\u202b",
    "\u202c",
    "\u202d",
    "\u202e",
    "\u2066",
    "\u2067",
    "\u2068",
    "\u2069",
}


@dataclass
class Finding:
    severity: str
    category: str
    path: str
    line: int | None
    snippet: str
    description: str
    recommendation: str


@dataclass
class RepoSummary:
    source: str
    repo_path: str
    commit: str | None
    layout: str
    skill_count: int
    skills: list[str]
    skill_files: list[str]
    overlapping_skills: list[str]
    new_skills: list[str]
    findings: list[Finding]


PATTERNS = [
    {
        "severity": "critical",
        "category": "remote-code-exec",
        "regex": re.compile(
            r"(" + "cu" + r"rl|wg" + r"et)\b[^\n|]{0,200}\|\s*(bash|sh|zsh|pwsh|python|python3)\b",
            re.IGNORECASE,
        ),
        "description": "Detected remote content piped directly into a shell or interpreter.",
        "recommendation": "Do not execute or import this flow until the remote source is pinned and reviewed.",
    },
    {
        "severity": "high",
        "category": "remote-code-exec",
        "regex": re.compile(r"\b(" + "Invoke" + r"-Expression|I" + r"EX)\b", re.IGNORECASE),
        "description": "Detected PowerShell expression execution.",
        "recommendation": "Inline expression execution should be removed or replaced with reviewed, pinned files.",
    },
    {
        "severity": "high",
        "category": "shell-execution",
        "regex": re.compile(
            r"subprocess\.(run|Popen|call|check_call|check_output)\([^)\n]*shell\s*=\s*True",
            re.IGNORECASE,
        ),
        "description": "Detected Python subprocess with shell=True.",
        "recommendation": "Use argv-based execution and validate all user-controlled inputs.",
    },
    {
        "severity": "high",
        "category": "shell-execution",
        "regex": re.compile(r"\b(os\.system|child_process\.(exec|execSync))\s*\(", re.IGNORECASE),
        "description": "Detected shell execution helper.",
        "recommendation": "Review carefully for command injection and reduce shell usage.",
    },
    {
        "severity": "high",
        "category": "shell-execution",
        "regex": re.compile(r"\b(bash|sh)\s+-c\b|\bcmd\s+/c\b", re.IGNORECASE),
        "description": "Detected shell command string execution.",
        "recommendation": "Prefer direct argv execution or remove the pattern from docs/scripts.",
    },
    {
        "severity": "high",
        "category": "destructive-command",
        "regex": re.compile(
            r"git reset --" + r"hard|git clean -f" + r"dx|\brm\s+-rf\s+(/|\~|\$HOME|\.git|node_modules)|\bmkfs\.",
            re.IGNORECASE,
        ),
        "description": "Detected destructive filesystem or git command.",
        "recommendation": "Require explicit user confirmation and remove unsafe defaults.",
    },
    {
        "severity": "high",
        "category": "secret-file-read",
        "regex": re.compile(
            r"\b(cat|type|Get-Content|copy|cp|tar|zip|base64)\b[^\n]{0,120}"
            r"(\.env\b|~/.ssh|~/.aws/credentials|id_rsa\b|\.npmrc\b)",
            re.IGNORECASE,
        ),
        "description": "Detected a command pattern that may read or package local secret files.",
        "recommendation": "Verify the context manually and reject any flow that reads or exports secrets without a clear need.",
    },
    {
        "severity": "medium",
        "category": "secret-env-access",
        "regex": re.compile(
            r"((print|echo|logger|logging|console\.log|Write-Host|Write-Output|Set-Content|Out-File|"
            r"requests\.(post|put)|httpx\.(post|put)|curl|Invoke-WebRequest)[^\n]{0,180}"
            r"(OPENAI_API_KEY|ANTHROPIC_API_KEY|GITHUB_TOKEN|AWS_SECRET_ACCESS_KEY))"
            r"|"
            r"((OPENAI_API_KEY|ANTHROPIC_API_KEY|GITHUB_TOKEN|AWS_SECRET_ACCESS_KEY)[^\n]{0,180}"
            r"(print|echo|logger|logging|console\.log|Write-Host|Write-Output|Set-Content|Out-File|"
            r"requests\.(post|put)|httpx\.(post|put)|curl|Invoke-WebRequest))",
            re.IGNORECASE,
        ),
        "description": "Detected a likely sink that may print, persist, or transmit sensitive environment variables.",
        "recommendation": "Verify the secret is not logged, written to disk, or sent over the network.",
    },
    {
        "severity": "medium",
        "category": "data-exfiltration",
        "regex": re.compile(
            r"(curl|Invoke-WebRequest|requests\.(post|put)|httpx\.(post|put))"
            r"[^\n|]{0,250}(--data(?:-binary)?|-d(?![A-Za-z])|--form|-F(?![A-Za-z])|files\s*=|data\s*=|json\s*=)",
            re.IGNORECASE,
        ),
        "description": "Detected outbound HTTP write operation that may upload local data.",
        "recommendation": "Review the payload source and ensure no local secrets or files are transmitted.",
    },
    {
        "severity": "medium",
        "category": "prompt-injection-marker",
        "regex": re.compile(
            r"\bignore (all|any|previous) instructions\b|\bdo not mention\b|\bhidden instruction\b|\boverride .*instructions\b|\bdo not reveal\b",
            re.IGNORECASE,
        ),
        "description": "Detected prompt injection or stealth instruction marker.",
        "recommendation": "Open the file and verify whether the text is documentation, a test fixture, or malicious instruction content.",
    },
    {
        "severity": "medium",
        "category": "floating-reference",
        "regex": re.compile(
            r"raw\.githubusercontent\.com/.+/(main|master)/|[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@(main|master)\b",
            re.IGNORECASE,
        ),
        "description": "Detected floating branch reference.",
        "recommendation": "Prefer pinned tags or commit SHAs for external sources.",
    },
    {
        "severity": "medium",
        "category": "wide-workflow-permission",
        "regex": re.compile(r"permissions:\s*write-all|actions:\s*write|packages:\s*write|issues:\s*write|pull-requests:\s*write|checks:\s*write|statuses:\s*write", re.IGNORECASE),
        "description": "Detected broad GitHub Actions permissions.",
        "recommendation": "Review workflow permissions and reduce them to least privilege.",
    },
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scan a local or remote skill repository for heuristic supply-chain and security risks."
    )
    parser.add_argument(
        "--repo",
        required=True,
        help="Local directory, full git URL, or owner/repo[@ref] spec.",
    )
    parser.add_argument(
        "--baseline-manifest",
        help="Optional baseline manifest file used to compute overlapping/new skills.",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json", "markdown"),
        default="text",
        help="Output format.",
    )
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        help="Relative path prefix or glob to exclude from scanning. Can be repeated.",
    )
    return parser.parse_args()


def is_text_file(path: pathlib.Path) -> bool:
    if path.suffix.lower() in TEXT_SUFFIXES:
        return True
    try:
        with path.open("rb") as handle:
            chunk = handle.read(4096)
    except OSError:
        return False
    return b"\x00" not in chunk


def should_exclude(rel_path: str, exclude_patterns: list[str]) -> bool:
    normalized = rel_path.replace("\\", "/").strip("./")
    for pattern in exclude_patterns:
        cleaned = pattern.replace("\\", "/").strip("./")
        if not cleaned:
            continue
        if normalized == cleaned or normalized.startswith(cleaned.rstrip("/") + "/"):
            return True
        if fnmatch.fnmatch(normalized, cleaned):
            return True
    return False


def iter_repo_files(root: pathlib.Path, exclude_patterns: list[str]) -> Iterable[pathlib.Path]:
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames[:] = [name for name in dirnames if name not in {".git", ".venv", "node_modules", "__pycache__"}]
        base = pathlib.Path(dirpath)
        rel_dir = relative_path(base, root)
        if rel_dir != "." and should_exclude(rel_dir, exclude_patterns):
            dirnames[:] = []
            continue
        dirnames[:] = [
            name
            for name in dirnames
            if not should_exclude(relative_path(base / name, root), exclude_patterns)
        ]
        for filename in filenames:
            path = base / filename
            if should_exclude(relative_path(path, root), exclude_patterns):
                continue
            try:
                if path.stat().st_size > MAX_FILE_BYTES:
                    continue
            except OSError:
                continue
            if is_text_file(path):
                yield path


def normalize_repo_spec(spec: str) -> tuple[str, str | None]:
    if re.match(r"^(https?|git@)", spec):
        return spec, None
    match = re.fullmatch(r"([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)(?:@([A-Za-z0-9._/-]+))?", spec)
    if not match:
        raise ValueError(f"Unsupported repo spec: {spec}")
    slug, ref = match.groups()
    return f"https://github.com/{slug}.git", ref


def clone_if_needed(repo_spec: str) -> tuple[pathlib.Path, str, tempfile.TemporaryDirectory[str] | None]:
    candidate = pathlib.Path(repo_spec)
    if candidate.exists():
        return candidate.resolve(), str(candidate.resolve()), None

    repo_url, ref = normalize_repo_spec(repo_spec)
    temp_dir = tempfile.TemporaryDirectory(prefix="skill-market-audit-")
    clone_dir = pathlib.Path(temp_dir.name) / "repo"
    last_error = "git clone failed"
    for attempt in range(3):
        shutil.rmtree(clone_dir, ignore_errors=True)
        cmd = ["git", "clone", "--depth", "1", "--single-branch", "--filter=blob:none"]
        if ref:
            cmd.extend(["--branch", ref])
        cmd.extend([repo_url, str(clone_dir)])
        try:
            result = subprocess.run(
                cmd,
                check=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=180,
                env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
            )
        except subprocess.TimeoutExpired:
            last_error = f"git clone timed out after 180 seconds for {repo_url}"
            if attempt < 2:
                time.sleep(attempt + 1)
            continue
        if result.returncode == 0:
            return clone_dir, repo_url, temp_dir
        last_error = result.stderr.strip() or result.stdout.strip() or last_error
        if attempt < 2:
            time.sleep(attempt + 1)
    raise RuntimeError(last_error)


def git_head(repo_path: pathlib.Path) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_path), "rev-parse", "HEAD"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    return result.stdout.strip() or None


def load_manifest(path: pathlib.Path | None) -> list[str]:
    if not path or not path.exists():
        return []
    items: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        items.append(line)
    return items


def read_skill_name(skill_md: pathlib.Path) -> str:
    try:
        lines = skill_md.read_text(encoding="utf-8", errors="ignore").splitlines()
    except OSError:
        return skill_md.parent.name

    if not lines or lines[0].strip() != "---":
        return skill_md.parent.name if skill_md.parent != skill_md.parent.parent else skill_md.stem

    for line in lines[1:60]:
        if line.strip() == "---":
            break
        match = re.match(r"^name:\s*(.+?)\s*$", line)
        if match:
            return match.group(1).strip().strip("\"'")
    return skill_md.parent.name if skill_md.parent != skill_md.parent.parent else skill_md.stem


def discover_skills(repo_path: pathlib.Path) -> tuple[str, list[str], list[str]]:
    standard_skill_files = sorted(
        path for path in repo_path.glob("skills/*/SKILL.md") if path.is_file()
    )
    if standard_skill_files:
        skills = [read_skill_name(path) for path in standard_skill_files]
        return "standard-skill-repo", skills, [relative_path(path, repo_path) for path in standard_skill_files]

    root_skill = repo_path / "SKILL.md"
    if root_skill.is_file():
        skill_name = read_skill_name(root_skill)
        return "single-skill-repo", [skill_name], [relative_path(root_skill, repo_path)]

    discovered: list[pathlib.Path] = []
    for path in repo_path.rglob("SKILL.md"):
        rel = relative_path(path, repo_path)
        if rel.startswith(".git/"):
            continue
        discovered.append(path)
    discovered = sorted(set(discovered))
    if discovered:
        skills = [read_skill_name(path) for path in discovered]
        return "catalog-or-nonstandard", skills, [relative_path(path, repo_path) for path in discovered]

    return "no-skill-files-detected", [], []


def relative_path(path: pathlib.Path, root: pathlib.Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def line_number_for_offset(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def add_finding(findings: list[Finding], finding: Finding) -> None:
    key = (finding.severity, finding.category, finding.path, finding.line, finding.snippet)
    if not hasattr(add_finding, "_seen"):
        add_finding._seen = set()  # type: ignore[attr-defined]
    seen = add_finding._seen  # type: ignore[attr-defined]
    if key not in seen:
        seen.add(key)
        findings.append(finding)


def scan_symlinks(repo_path: pathlib.Path, findings: list[Finding], exclude_patterns: list[str]) -> None:
    for dirpath, dirnames, filenames in os.walk(repo_path, followlinks=False):
        names = list(dirnames) + list(filenames)
        base = pathlib.Path(dirpath)
        for name in names:
            path = base / name
            if should_exclude(relative_path(path, repo_path), exclude_patterns):
                continue
            if not path.is_symlink():
                continue
            try:
                target = path.resolve(strict=False)
            except OSError:
                continue
            if not str(target).startswith(str(repo_path.resolve())):
                add_finding(
                    findings,
                    Finding(
                        severity="high",
                        category="symlink-escape",
                        path=relative_path(path, repo_path),
                        line=None,
                        snippet=str(path.readlink()),
                        description="Detected symlink that resolves outside the repository root.",
                        recommendation="Reject or remove symlinks that escape the repository root before importing the skill.",
                    ),
                )


def scan_file(path: pathlib.Path, repo_path: pathlib.Path, findings: list[Finding]) -> None:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return

    rel_path = relative_path(path, repo_path)
    prompt_scan_suffixes = {".md", ".txt", ".yaml", ".yml", ".json"}

    for char in BIDI_AND_HIDDEN_CHARS:
        index = text.find(char)
        if index != -1:
            add_finding(
                findings,
                Finding(
                    severity="medium",
                    category="hidden-unicode",
                    path=rel_path,
                    line=line_number_for_offset(text, index),
                    snippet=repr(char),
                    description="Detected hidden or bidirectional Unicode control characters.",
                    recommendation="Open the file in a Unicode-aware editor and remove hidden control characters unless explicitly required.",
                ),
            )
            break

    for pattern in PATTERNS:
        if pattern["category"] == "prompt-injection-marker" and path.suffix.lower() not in prompt_scan_suffixes:
            continue
        if pattern["category"] == "wide-workflow-permission" and ".github/workflows/" not in rel_path:
            continue
        if pattern["category"] == "destructive-command" and rel_path == "scripts/validate-skills.sh":
            continue
        for match in pattern["regex"].finditer(text):
            line = line_number_for_offset(text, match.start())
            snippet = match.group(0).strip().replace("\n", " ")
            add_finding(
                findings,
                Finding(
                    severity=pattern["severity"],
                    category=pattern["category"],
                    path=rel_path,
                    line=line,
                    snippet=snippet[:180],
                    description=pattern["description"],
                    recommendation=pattern["recommendation"],
                ),
            )


def repo_has_license(repo_path: pathlib.Path) -> bool:
    for candidate in repo_path.iterdir():
        if candidate.is_file() and candidate.name.lower().startswith("license"):
            return True
    return False


def repo_has_security_policy(repo_path: pathlib.Path) -> bool:
    candidates = [
        repo_path / "SECURITY.md",
        repo_path / ".github" / "SECURITY.md",
    ]
    return any(path.is_file() for path in candidates)


def build_summary(args: argparse.Namespace) -> RepoSummary:
    temp_dir: tempfile.TemporaryDirectory[str] | None = None
    repo_path: pathlib.Path
    source: str
    try:
        repo_path, source, temp_dir = clone_if_needed(args.repo)
        findings: list[Finding] = []
        scan_symlinks(repo_path, findings, args.exclude)
        for path in iter_repo_files(repo_path, args.exclude):
            scan_file(path, repo_path, findings)

        if not repo_has_license(repo_path):
            findings.append(
                Finding(
                    severity="low",
                    category="missing-license",
                    path=".",
                    line=None,
                    snippet="LICENSE",
                    description="Repository does not expose a root license file.",
                    recommendation="Confirm the license before reusing or redistributing marketplace skills.",
                )
            )

        if not repo_has_security_policy(repo_path):
            findings.append(
                Finding(
                    severity="low",
                    category="missing-security-policy",
                    path=".",
                    line=None,
                    snippet="SECURITY.md",
                    description="Repository does not expose a security disclosure policy.",
                    recommendation="Treat incident handling maturity as unknown and prefer repositories with a visible security contact.",
                )
            )

        layout, skills, skill_files = discover_skills(repo_path)
        baseline = load_manifest(pathlib.Path(args.baseline_manifest)) if args.baseline_manifest else []
        baseline_set = set(baseline)
        overlapping = sorted(skill for skill in skills if skill in baseline_set)
        new_skills = sorted(skill for skill in skills if skill not in baseline_set)

        findings.sort(
            key=lambda item: (
                SEVERITY_ORDER.get(item.severity, 99),
                item.path,
                item.line if item.line is not None else -1,
                item.category,
            )
        )

        return RepoSummary(
            source=source,
            repo_path=str(repo_path),
            commit=git_head(repo_path),
            layout=layout,
            skill_count=len(skills),
            skills=skills,
            skill_files=skill_files,
            overlapping_skills=overlapping,
            new_skills=new_skills,
            findings=findings,
        )
    finally:
        if temp_dir is not None:
            temp_dir.cleanup()


def render_text(summary: RepoSummary) -> str:
    lines = [
        f"Source: {summary.source}",
        f"Repo path: {summary.repo_path}",
        f"Commit: {summary.commit or 'unknown'}",
        f"Layout: {summary.layout}",
        f"Skills: {summary.skill_count}",
        f"Skill files: {', '.join(summary.skill_files) or 'none'}",
        f"Overlapping skills: {', '.join(summary.overlapping_skills) or 'none'}",
        f"New skills: {', '.join(summary.new_skills) or 'none'}",
        "",
        f"Findings: {len(summary.findings)}",
    ]
    if not summary.findings:
        lines.append("No heuristic findings.")
        return "\n".join(lines)

    for finding in summary.findings:
        location = f"{finding.path}:{finding.line}" if finding.line else finding.path
        lines.extend(
            [
                f"- [{finding.severity.upper()}] {finding.category} @ {location}",
                f"  snippet: {finding.snippet}",
                f"  why: {finding.description}",
                f"  next: {finding.recommendation}",
            ]
        )
    return "\n".join(lines)


def render_markdown(summary: RepoSummary) -> str:
    lines = [
        "## Skill Repo Audit Summary",
        "",
        f"- Source: `{summary.source}`",
        f"- Repo path: `{summary.repo_path}`",
        f"- Commit: `{summary.commit or 'unknown'}`",
        f"- Layout: `{summary.layout}`",
        f"- Skills: `{summary.skill_count}`",
        f"- Skill files: `{', '.join(summary.skill_files) or 'none'}`",
        f"- Overlapping skills: `{', '.join(summary.overlapping_skills) or 'none'}`",
        f"- New skills: `{', '.join(summary.new_skills) or 'none'}`",
        "",
        "## Findings",
    ]
    if not summary.findings:
        lines.append("")
        lines.append("- No heuristic findings.")
        return "\n".join(lines)

    for finding in summary.findings:
        location = f"{finding.path}:{finding.line}" if finding.line else finding.path
        lines.extend(
            [
                "",
                f"- [{finding.severity.upper()}] `{finding.category}` at `{location}`",
                f"  - Snippet: `{finding.snippet}`",
                f"  - Why: {finding.description}",
                f"  - Recommendation: {finding.recommendation}",
            ]
        )
    return "\n".join(lines)


def render_json(summary: RepoSummary) -> str:
    payload = asdict(summary)
    payload["findings"] = [asdict(item) for item in summary.findings]
    return json.dumps(payload, ensure_ascii=False, indent=2)


def main() -> int:
    args = parse_args()
    try:
        summary = build_summary(args)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"scan failed: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(render_json(summary))
    elif args.format == "markdown":
        print(render_markdown(summary))
    else:
        print(render_text(summary))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
