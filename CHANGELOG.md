# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses semantic versioning for release entries when tagged.

## [Unreleased] - 2026-04-08

### Added
- Added a daily skill marketplace audit workflow that validates the local skill baseline, discovers external marketplace candidates, audits allowlisted repositories, and writes report artifacts.
- Added report-only merge preview support so external skill recommendations can be reviewed without modifying local `skills/` content.
- Added Matrix notification support for sending detailed daily audit reports to a configured Matrix room.
- Added allowlist configuration, report directory documentation, and example `cron` / `systemd` scheduler definitions.
- Added `gemini` and `all` target support for install/update/uninstall scripts across Bash and PowerShell.
- Added Gemini skills directory auto-detection with `~/.gemini/skills` default, `~/.agents/skills` fallback, and `GEMINI_SKILLS_DIR` override.
- Added CI smoke coverage for `claude/codex/gemini/both/all` install targets plus Gemini install/uninstall assertions in E2E.

### Changed
- Improved marketplace discovery by supporting `GITHUB_TOKEN` for GitHub API requests.
- Hardened repository scanning with exclude patterns, partial clone options, retry handling, and timeout controls for larger external repositories.
- Updated daily Matrix notifications to send the detailed audit report body instead of only a compact summary.
- Updated `skill-market-auditor` and repository documentation with the new daily automation workflow.
- Updated default marketplace discovery queries to include `topic:gemini-cli-skill`.
- Enhanced `code-reviewer` skill to support single commit, commit list, commit range, and branch diff reviews with stricter findings-first output rules.

### Fixed
- Fixed Matrix `/send` delivery by using the correct Matrix Client API request method and stronger request headers.
- Fixed Matrix notification status handling so delivery results are preserved in daily reports.
- Fixed local self-audit noise by excluding generated skill-market report artifacts from the local scan.

### Security
- Added a safer report-only supply-chain workflow for external skill marketplace review.
- Restricted deep external audits to the configured allowlist by default.
- Preserved the default no-auto-apply policy so marketplace skills are discovered, audited, and reported before any manual import decision.
