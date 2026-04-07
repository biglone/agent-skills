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
from collections import Counter
from dataclasses import asdict, dataclass


IGNORE_DIRS = {
    ".git",
    ".hg",
    ".svn",
    ".next",
    ".nuxt",
    ".turbo",
    ".venv",
    "__pycache__",
    "node_modules",
    "dist",
    "build",
    "coverage",
    "target",
    "vendor",
    "out",
}

MANIFEST_HINTS = {
    "package.json": "node",
    "pnpm-workspace.yaml": "node-workspace",
    "turbo.json": "turbo",
    "nx.json": "nx",
    "tsconfig.json": "typescript",
    "requirements.txt": "python",
    "pyproject.toml": "python",
    "poetry.lock": "python",
    "Pipfile": "python",
    "go.mod": "go",
    "Cargo.toml": "rust",
    "pom.xml": "java",
    "build.gradle": "java-gradle",
    "build.gradle.kts": "java-gradle",
    "settings.gradle": "java-gradle",
    "settings.gradle.kts": "java-gradle",
    "Dockerfile": "docker",
    "docker-compose.yml": "docker-compose",
    "docker-compose.yaml": "docker-compose",
    "Makefile": "make",
    "justfile": "just",
}

ENTRYPOINT_CANDIDATES = [
    "main.py",
    "app.py",
    "manage.py",
    "server.py",
    "main.go",
    "src/main.rs",
    "cmd",
    "src/main.py",
    "src/index.ts",
    "src/index.tsx",
    "src/index.js",
    "src/main.ts",
    "src/main.tsx",
    "src/main.js",
    "src/App.tsx",
    "src/App.jsx",
    "apps",
]

SOURCE_ROOT_HINTS = [
    "src",
    "app",
    "apps",
    "packages",
    "libs",
    "lib",
    "cmd",
    "internal",
    "pkg",
    "server",
    "client",
    "frontend",
    "backend",
    "services",
]

TEST_DIR_HINTS = [
    "test",
    "tests",
    "__tests__",
    "spec",
    "e2e",
    "integration",
]

LANGUAGE_BY_EXTENSION = {
    ".py": "python",
    ".ts": "typescript",
    ".tsx": "typescript",
    ".js": "javascript",
    ".jsx": "javascript",
    ".go": "go",
    ".rs": "rust",
    ".java": "java",
    ".kt": "kotlin",
    ".swift": "swift",
    ".rb": "ruby",
    ".php": "php",
    ".cs": "csharp",
    ".cpp": "cpp",
    ".cc": "cpp",
    ".cxx": "cpp",
    ".c": "c",
    ".h": "c-cpp-header",
    ".hpp": "c-cpp-header",
    ".scala": "scala",
    ".sh": "shell",
    ".bash": "shell",
    ".zsh": "shell",
}


@dataclass
class RepoSnapshot:
    source: str
    repo_path: str
    commit: str | None
    root_files: list[str]
    top_directories: list[str]
    manifests: list[str]
    doc_files: list[str]
    ci_files: list[str]
    entrypoints: list[str]
    source_roots: list[str]
    test_locations: list[str]
    top_languages: list[tuple[str, int]]
    tree_sample: list[str]
    tree_truncated: bool


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create a read-only snapshot of a repository.")
    parser.add_argument("--repo", required=True, help="GitHub URL, owner/repo[@ref], or local path.")
    parser.add_argument("--max-depth", type=int, default=4, help="Max depth for sampled tree output.")
    parser.add_argument("--max-files", type=int, default=200, help="Max tree entries to include.")
    parser.add_argument("--format", choices=("json", "markdown"), default="json", help="Output format.")
    return parser.parse_args()


def normalize_repo_spec(spec: str) -> tuple[str, str | None]:
    cleaned = spec.strip()
    ref = None
    if re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@[^/\s]+", cleaned):
        cleaned, ref = cleaned.split("@", 1)
    if re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", cleaned):
        return f"https://github.com/{cleaned}.git", ref
    if re.fullmatch(r"https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:\.git)?/?", cleaned):
        cleaned = cleaned.rstrip("/")
        if not cleaned.endswith(".git"):
            cleaned = f"{cleaned}.git"
        return cleaned, ref
    raise ValueError(f"Unsupported repo spec: {spec}")


def clone_if_needed(repo_spec: str) -> tuple[pathlib.Path, str, tempfile.TemporaryDirectory[str] | None]:
    candidate = pathlib.Path(repo_spec).expanduser()
    if candidate.exists():
        return candidate.resolve(), str(candidate.resolve()), None

    repo_url, ref = normalize_repo_spec(repo_spec)
    temp_dir = tempfile.TemporaryDirectory(prefix="github-repo-analyzer-")
    clone_dir = pathlib.Path(temp_dir.name) / "repo"
    cmd = [
        "git",
        "clone",
        "--depth",
        "1",
        "--filter=blob:none",
        "--single-branch",
    ]
    if ref:
        cmd.extend(["--branch", ref])
    cmd.extend([repo_url, str(clone_dir)])
    env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
        env=env,
        timeout=180,
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "git clone failed"
        temp_dir.cleanup()
        raise RuntimeError(message)
    return clone_dir, repo_url, temp_dir


def git_head(repo_path: pathlib.Path) -> str | None:
    result = subprocess.run(
        ["git", "-C", str(repo_path), "rev-parse", "HEAD"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def list_root_files(repo_path: pathlib.Path) -> list[str]:
    return sorted(
        item.name
        for item in repo_path.iterdir()
        if item.is_file() and not item.name.startswith(".git")
    )


def list_top_directories(repo_path: pathlib.Path) -> list[str]:
    return sorted(
        item.name
        for item in repo_path.iterdir()
        if item.is_dir() and item.name not in IGNORE_DIRS
    )


def find_named_paths(repo_path: pathlib.Path, names: list[str], max_results: int = 20) -> list[str]:
    found: list[str] = []
    for name in names:
        candidate = repo_path / name
        if candidate.exists():
            found.append(str(candidate.relative_to(repo_path)))
            continue
        for path in repo_path.rglob(name):
            if any(part in IGNORE_DIRS for part in path.parts):
                continue
            found.append(str(path.relative_to(repo_path)))
            if len(found) >= max_results:
                return sorted(set(found))
    return sorted(set(found))


def collect_manifests(repo_path: pathlib.Path) -> list[str]:
    found: list[str] = []
    for rel in MANIFEST_HINTS:
        path = repo_path / rel
        if path.exists():
            found.append(rel)
    workflow_dir = repo_path / ".github" / "workflows"
    if workflow_dir.is_dir():
        found.extend(
            sorted(str(path.relative_to(repo_path)) for path in workflow_dir.glob("*.y*ml"))
        )
    return sorted(set(found))


def collect_docs(repo_path: pathlib.Path) -> list[str]:
    candidates: list[str] = []
    for pattern in ("README*", "docs/*.md", "docs/**/*.md", "*.md"):
        for path in repo_path.glob(pattern):
            if path.is_dir():
                continue
            rel = str(path.relative_to(repo_path))
            if rel.count("/") <= 3:
                candidates.append(rel)
    return sorted(set(candidates))[:30]


def collect_languages(repo_path: pathlib.Path) -> list[tuple[str, int]]:
    counts: Counter[str] = Counter()
    for path in repo_path.rglob("*"):
        if not path.is_file():
            continue
        if any(part in IGNORE_DIRS for part in path.parts):
            continue
        lang = LANGUAGE_BY_EXTENSION.get(path.suffix.lower())
        if lang:
            counts[lang] += 1
    return counts.most_common(8)


def sample_tree(repo_path: pathlib.Path, max_depth: int, max_files: int) -> tuple[list[str], bool]:
    lines: list[str] = []
    truncated = False

    def walk(current: pathlib.Path, depth: int) -> None:
        nonlocal truncated
        if truncated or depth > max_depth:
            return
        try:
            entries = sorted(
                current.iterdir(),
                key=lambda item: (item.is_file(), item.name.lower()),
            )
        except OSError:
            return

        for entry in entries:
            if entry.name in IGNORE_DIRS:
                continue
            rel = entry.relative_to(repo_path)
            prefix = "  " * depth
            label = f"{prefix}{entry.name}/" if entry.is_dir() else f"{prefix}{entry.name}"
            lines.append(str(rel) if depth == 0 else label)
            if len(lines) >= max_files:
                truncated = True
                return
            if entry.is_dir():
                walk(entry, depth + 1)

    walk(repo_path, 0)
    return lines, truncated


def render_markdown(snapshot: RepoSnapshot) -> str:
    lines = [
        "# Repository Snapshot",
        "",
        f"- Source: `{snapshot.source}`",
        f"- Repo path: `{snapshot.repo_path}`",
        f"- Commit: `{snapshot.commit or 'unknown'}`",
        f"- Root files: `{', '.join(snapshot.root_files) or 'none'}`",
        f"- Top directories: `{', '.join(snapshot.top_directories) or 'none'}`",
        f"- Manifests: `{', '.join(snapshot.manifests) or 'none'}`",
        f"- Docs: `{', '.join(snapshot.doc_files) or 'none'}`",
        f"- CI files: `{', '.join(snapshot.ci_files) or 'none'}`",
        f"- Entrypoints: `{', '.join(snapshot.entrypoints) or 'none'}`",
        f"- Source roots: `{', '.join(snapshot.source_roots) or 'none'}`",
        f"- Test locations: `{', '.join(snapshot.test_locations) or 'none'}`",
        f"- Top languages: `{', '.join(f'{name}:{count}' for name, count in snapshot.top_languages) or 'unknown'}`",
        "",
        "## Tree Sample",
        "",
    ]
    lines.extend(f"- `{line}`" for line in snapshot.tree_sample)
    if snapshot.tree_truncated:
        lines.extend(["", "- `(tree truncated)`"])
    return "\n".join(lines) + "\n"


def build_snapshot(repo_spec: str, max_depth: int, max_files: int) -> RepoSnapshot:
    repo_path, source, temp_dir = clone_if_needed(repo_spec)
    try:
        root_files = list_root_files(repo_path)
        top_directories = list_top_directories(repo_path)
        manifests = collect_manifests(repo_path)
        doc_files = collect_docs(repo_path)
        ci_files = sorted(item for item in manifests if item.startswith(".github/workflows/"))
        entrypoints = find_named_paths(repo_path, ENTRYPOINT_CANDIDATES, max_results=20)
        source_roots = [name for name in top_directories if name in SOURCE_ROOT_HINTS]
        test_locations = find_named_paths(repo_path, TEST_DIR_HINTS, max_results=20)
        top_languages = collect_languages(repo_path)
        tree_sample, tree_truncated = sample_tree(repo_path, max_depth=max_depth, max_files=max_files)
        return RepoSnapshot(
            source=source,
            repo_path=str(repo_path),
            commit=git_head(repo_path),
            root_files=root_files,
            top_directories=top_directories,
            manifests=manifests,
            doc_files=doc_files,
            ci_files=ci_files,
            entrypoints=entrypoints,
            source_roots=source_roots,
            test_locations=test_locations,
            top_languages=top_languages,
            tree_sample=tree_sample,
            tree_truncated=tree_truncated,
        )
    finally:
        if temp_dir is not None:
            temp_dir.cleanup()


def main() -> int:
    args = parse_args()
    snapshot = build_snapshot(args.repo, args.max_depth, args.max_files)
    if args.format == "markdown":
        print(render_markdown(snapshot))
    else:
        print(json.dumps(asdict(snapshot), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
