# Release Checklist

Use this checklist before creating a tag release (`v*`).

## 1. Update version trigger

Codex auto-update compares local version with:

- `scripts/manifest/version.txt`

When install/update logic or behavior changes, bump this file first.

## 2. Validate locally

Run:

```bash
bash -n scripts/install.sh scripts/update.sh
python3 -m py_compile scripts/merge-skill.py
bash scripts/validate-skills.sh
```

If merge-market logic changed, also run a local smoke test with:

- `SKILL_MARKET_CONFLICT_MODE=merge`
- `SKILL_MARKET_MERGE_APPLY_MODE=preview`
- `SKILL_MARKET_MERGE_APPLY_MODE=apply`

## 3. Ensure required CI checks

In GitHub branch protection (default branch), set these checks as required:

- `Scripts (ubuntu)`
- `Scripts (windows)`
- `E2E (ubuntu-latest)`
- `E2E (macos-latest)`
- `E2E (windows-latest)`
- `validate-skills`

UI path:

- `Settings` -> `Branches` -> `Branch protection rules` -> target branch -> `Require status checks to pass before merging`

## 4. Update docs for operator-facing changes

If you add env vars or behavior changes:

- Update `README.md` env table
- Add default and value range
- Add at least one Linux and one PowerShell example

## 5. Tag and release

After merge to `main`, create tag:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

`publish-release.yml` will create the GitHub release automatically.
