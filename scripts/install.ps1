# AI Coding Skills 安装脚本 (Windows PowerShell)
# 支持 Claude Code、OpenAI Codex CLI 和 Gemini CLI
# 用法: 先下载脚本到本地，再执行 powershell -File .\install.ps1

$ErrorActionPreference = "Stop"

# 配置
$RepoUrl = if ($env:SKILLS_REPO) { $env:SKILLS_REPO } else { "https://github.com/biglone/agent-skills.git" }
$SkillsRef = if ($env:SKILLS_REF) { $env:SKILLS_REF } else { "main" }
$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$CodexSkillsDir = Join-Path $env:USERPROFILE ".codex\skills"
$GeminiDefaultSkillsDir = Join-Path $env:USERPROFILE ".gemini\skills"
$GeminiAliasSkillsDir = Join-Path $env:USERPROFILE ".agents\skills"
$GeminiSkillsDir = if ($env:GEMINI_SKILLS_DIR) { $env:GEMINI_SKILLS_DIR } elseif (Test-Path $GeminiAliasSkillsDir) { $GeminiAliasSkillsDir } else { $GeminiDefaultSkillsDir }
$ClaudeWorkflowsDir = Join-Path $env:USERPROFILE ".claude\workflows"
$CodexWorkflowsDir = Join-Path $env:USERPROFILE ".codex\workflows"
$TempDir = Join-Path $env:TEMP "ai-skills-$(Get-Random)"
$Script:InstalledSkills = @{
    "Claude Code" = New-Object System.Collections.Generic.List[string]
    "Codex CLI"   = New-Object System.Collections.Generic.List[string]
    "Gemini CLI"  = New-Object System.Collections.Generic.List[string]
}
$DebugMode = ($env:DEBUG -eq "1" -or $env:DEBUG -eq "true")
$NonInteractive = ($env:NON_INTERACTIVE -eq "1" -or $env:NON_INTERACTIVE -eq "true")
$DryRun = ($env:DRY_RUN -eq "1" -or $env:DRY_RUN -eq "true")
$CodexAutoUpdateSetup = if ($env:CODEX_AUTO_UPDATE_SETUP) { $env:CODEX_AUTO_UPDATE_SETUP } else { "on" }
$CodexAutoUpdateRepo = if ($env:CODEX_AUTO_UPDATE_REPO) { $env:CODEX_AUTO_UPDATE_REPO } else { "" }
$CodexAutoUpdateBranch = if ($env:CODEX_AUTO_UPDATE_BRANCH) { $env:CODEX_AUTO_UPDATE_BRANCH } else { $SkillsRef }
$CodexLocalVersionFile = Join-Path $env:USERPROFILE ".codex\.skills_version"
$CodexAutoUpdateLoader = Join-Path $env:USERPROFILE ".codex\codex-skills-auto-update.ps1"
$Script:AskFallbackWarned = $false
$Script:SkillsManifest = @()
$Script:WorkflowsManifest = @()
$Script:MarketRepoSeedFile = $null
$Script:MergeSkillScriptPath = $null
$Script:PrimaryRepoSlug = $null
$Script:MarketCandidates = New-Object System.Collections.Generic.List[object]
$Script:SkillMarketAllowlistSet = @{}

# Skills Market 配置
$SkillMarketDiscovery = if ($env:SKILL_MARKET_DISCOVERY) { $env:SKILL_MARKET_DISCOVERY.Trim().ToLowerInvariant() } else { "off" }  # off/manifest/github/all
$SkillMarketQueries = if ($env:SKILL_MARKET_QUERIES) { $env:SKILL_MARKET_QUERIES } else { "topic:agent-skills;topic:claude-code-skill;topic:codex-skill;topic:gemini-cli-skill" }
$SkillMarketPerQuery = if ($env:SKILL_MARKET_PER_QUERY) { $env:SKILL_MARKET_PER_QUERY } else { "10" }
$SkillMarketMaxRepos = if ($env:SKILL_MARKET_MAX_REPOS) { $env:SKILL_MARKET_MAX_REPOS } else { "5" }
$SkillMarketMinStars = if ($env:SKILL_MARKET_MIN_STARS) { $env:SKILL_MARKET_MIN_STARS } else { "10" }
$SkillMarketExtraRepos = if ($env:SKILL_MARKET_EXTRA_REPOS) { $env:SKILL_MARKET_EXTRA_REPOS } else { "" }
$SkillMarketAllowlist = if ($env:SKILL_MARKET_ALLOWLIST) { $env:SKILL_MARKET_ALLOWLIST } else { "" }
$SkillMarketConflictMode = if ($env:SKILL_MARKET_CONFLICT_MODE) { $env:SKILL_MARKET_CONFLICT_MODE.Trim().ToLowerInvariant() } else { "skip" } # skip/replace/merge
$SkillMarketSourceMarkFile = if ($env:SKILL_MARKET_SOURCE_MARK_FILE) { $env:SKILL_MARKET_SOURCE_MARK_FILE } else { ".agent-skills-source" }
$SkillMarketMergedFileName = if ($env:SKILL_MARKET_MERGED_FILE_NAME) { $env:SKILL_MARKET_MERGED_FILE_NAME } else { "SKILL.merged.md" }
$SkillMarketMergeReportFileName = if ($env:SKILL_MARKET_MERGE_REPORT_FILE_NAME) { $env:SKILL_MARKET_MERGE_REPORT_FILE_NAME } else { "SKILL.merge-report.md" }
$SkillMarketMergeSourceDir = if ($env:SKILL_MARKET_MERGE_SOURCE_DIR) { $env:SKILL_MARKET_MERGE_SOURCE_DIR } else { ".agent-skills-merge-sources" }
$SkillMarketMergeApplyMode = if ($env:SKILL_MARKET_MERGE_APPLY_MODE) { $env:SKILL_MARKET_MERGE_APPLY_MODE.Trim().ToLowerInvariant() } else { "preview" }
$SkillMarketMergeBackupFileName = if ($env:SKILL_MARKET_MERGE_BACKUP_FILE_NAME) { $env:SKILL_MARKET_MERGE_BACKUP_FILE_NAME } else { "SKILL.pre-merge.backup.md" }
$SkillMarketMergeSourceRetentionCount = if ($env:SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT) { $env:SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT } else { "5" }
$SkillMarketMergeSourceRetentionDays = if ($env:SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS) { $env:SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS } else { "30" }

# 更新模式 (ask, skip, force)
$UpdateMode = if ($env:UPDATE_MODE) { $env:UPDATE_MODE.Trim().ToLowerInvariant() } else { "force" }

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-DebugInfo { param($Message) if ($DebugMode) { Write-Host "[DEBUG] $Message" -ForegroundColor Cyan } }

function Show-Usage {
    @"
Usage: install.ps1 [options]

Options:
  --non-interactive   Disable prompts and use defaults/env values
  --dry-run           Print planned actions without writing target dirs
  -h, --help          Show this help

Env:
  INSTALL_TARGET            claude | codex | gemini | both | all
  UPDATE_MODE               ask | skip | force
  SKILLS_REPO               Git repository URL
  SKILLS_REF                Branch/tag/commit-ish to install from
  GEMINI_SKILLS_DIR         Override Gemini skills dir (default: ~/.gemini/skills)
  SKILL_MARKET_DISCOVERY    off | manifest | github | all
  SKILL_MARKET_CONFLICT_MODE skip | replace | merge
  SKILL_MARKET_ALLOWLIST    owner/repo,owner/repo
  SKILL_MARKET_MERGE_APPLY_MODE preview | apply
"@ | Write-Host
}

function Parse-Args {
    param([string[]]$ScriptArgs)

    foreach ($Arg in $ScriptArgs) {
        switch ($Arg.ToLowerInvariant()) {
            "--non-interactive" { $script:NonInteractive = $true }
            "--dry-run" { $script:DryRun = $true }
            "-h" {
                Show-Usage
                exit 0
            }
            "--help" {
                Show-Usage
                exit 0
            }
            default {
                throw "未知参数: $Arg"
            }
        }
    }
}

function Test-InteractiveSession {
    try {
        return (-not [Console]::IsInputRedirected) -and (-not [Console]::IsOutputRedirected)
    } catch {
        return $false
    }
}

function Resolve-UpdateMode {
    param([string]$Mode)

    $Normalized = if ([string]::IsNullOrWhiteSpace($Mode)) { "force" } else { $Mode.Trim().ToLowerInvariant() }
    if ($Normalized -notin @("ask", "skip", "force")) {
        throw "UPDATE_MODE 无效: '$Mode'。可选值: ask / skip / force"
    }

    return $Normalized
}

function Resolve-InstallTargetFromEnv {
    if ([string]::IsNullOrWhiteSpace($env:INSTALL_TARGET)) {
        return $null
    }

    return Resolve-InstallTargetValue -Value $env:INSTALL_TARGET
}

function Resolve-InstallTargetValue {
    param([string]$Value)

    $Target = $Value.Trim().ToLowerInvariant()
    switch ($Target) {
        "claude" { return "claude" }
        "codex" { return "codex" }
        "gemini" { return "gemini" }
        "both" { return "both" }
        "all" { return "all" }
        default { throw "INSTALL_TARGET 无效: '$Value'。可选值: claude / codex / gemini / both / all" }
    }
}

function Test-InstallTargetIncludes {
    param(
        [string]$SelectedTarget,
        [string]$Platform
    )

    switch ($SelectedTarget) {
        "all" { return $true }
        "both" { return ($Platform -in @("claude", "codex")) }
        default { return $SelectedTarget -eq $Platform }
    }
}

function Resolve-RepoSlug {
    param([string]$RepoUrlValue)

    if ([string]::IsNullOrWhiteSpace($RepoUrlValue)) {
        return $null
    }

    $Value = $RepoUrlValue.Trim()
    if ($Value -match '^https://github\.com/([^/]+/[^/]+?)(?:\.git)?/?$') {
        return $Matches[1]
    }
    if ($Value -match '^git@github\.com:([^/]+/[^/]+?)(?:\.git)?$') {
        return $Matches[1]
    }
    if ($Value -match '^ssh://git@github\.com/([^/]+/[^/]+?)(?:\.git)?/?$') {
        return $Matches[1]
    }
    if ($Value -match '^[^/\s]+/[^/\s]+$') {
        return $Value
    }

    return $null
}

function Get-ManifestEntries {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "manifest 不存在: $Path"
    }

    $Entries = @()
    foreach ($Line in (Get-Content -Path $Path -Encoding UTF8)) {
        $Item = $Line.Trim()
        if (-not $Item) { continue }
        if ($Item.StartsWith("#")) { continue }
        $Entries += $Item
    }
    return $Entries
}

function Set-Manifests {
    $SkillsManifestPath = Join-Path $TempDir "scripts\manifest\skills.txt"
    $WorkflowsManifestPath = Join-Path $TempDir "scripts\manifest\workflows.txt"

    $Script:SkillsManifest = Get-ManifestEntries -Path $SkillsManifestPath
    if ($Script:SkillsManifest.Count -eq 0) {
        throw "skills manifest 为空"
    }

    if (Test-Path $WorkflowsManifestPath) {
        $Script:WorkflowsManifest = Get-ManifestEntries -Path $WorkflowsManifestPath
    } else {
        Write-Warn "workflows manifest 不存在，跳过 workflows 安装"
        $Script:WorkflowsManifest = @()
    }

    $Script:MarketRepoSeedFile = Join-Path $TempDir "scripts\manifest\market-seed-repos.txt"
    $Script:MergeSkillScriptPath = Join-Path $TempDir "scripts\merge-skill.py"
    if (-not (Test-Path $Script:MergeSkillScriptPath)) {
        $FallbackScript = Join-Path (Get-Location).Path "scripts\merge-skill.py"
        if (Test-Path $FallbackScript) {
            $Script:MergeSkillScriptPath = $FallbackScript
        }
    }
}

function Test-PositiveInteger {
    param([string]$Value)
    return ($Value -match '^[1-9][0-9]*$')
}

function Test-NonNegativeInteger {
    param([string]$Value)
    return ($Value -match '^[0-9]+$')
}

function Build-MarketAllowlistSet {
    $Script:SkillMarketAllowlistSet = @{}
    if ([string]::IsNullOrWhiteSpace($SkillMarketAllowlist)) { return }

    foreach ($Item in ($SkillMarketAllowlist -split '[,;\r\n\t]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        $Slug = Resolve-RepoSlug -RepoUrlValue $Item
        if (-not $Slug) {
            Write-Warn "[market] allowlist 项无效，已忽略: $Item"
            continue
        }
        $Script:SkillMarketAllowlistSet[$Slug.ToLowerInvariant()] = $true
    }
}

function Validate-MarketConfig {
    switch ($SkillMarketDiscovery) {
        "off" { }
        "manifest" { }
        "github" { }
        "all" { }
        default { throw "SKILL_MARKET_DISCOVERY 无效: '$SkillMarketDiscovery'。可选值: off / manifest / github / all" }
    }

    switch ($SkillMarketConflictMode) {
        "skip" { }
        "replace" { }
        "merge" { }
        default { throw "SKILL_MARKET_CONFLICT_MODE 无效: '$SkillMarketConflictMode'。可选值: skip / replace / merge" }
    }

    switch ($SkillMarketMergeApplyMode) {
        "preview" { }
        "apply" { }
        default { throw "SKILL_MARKET_MERGE_APPLY_MODE 无效: '$SkillMarketMergeApplyMode'。可选值: preview / apply" }
    }

    if (-not (Test-PositiveInteger -Value $SkillMarketPerQuery)) {
        throw "SKILL_MARKET_PER_QUERY 必须是正整数（当前: $SkillMarketPerQuery）"
    }
    if (-not (Test-PositiveInteger -Value $SkillMarketMaxRepos)) {
        throw "SKILL_MARKET_MAX_REPOS 必须是正整数（当前: $SkillMarketMaxRepos）"
    }
    if (-not (Test-NonNegativeInteger -Value $SkillMarketMinStars)) {
        throw "SKILL_MARKET_MIN_STARS 必须是非负整数（当前: $SkillMarketMinStars）"
    }
    if (-not (Test-PositiveInteger -Value $SkillMarketMergeSourceRetentionCount)) {
        throw "SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT 必须是正整数（当前: $SkillMarketMergeSourceRetentionCount）"
    }
    if (-not (Test-NonNegativeInteger -Value $SkillMarketMergeSourceRetentionDays)) {
        throw "SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS 必须是非负整数（当前: $SkillMarketMergeSourceRetentionDays）"
    }

    $script:SkillMarketPerQueryInt = [int]$SkillMarketPerQuery
    $script:SkillMarketMaxReposInt = [int]$SkillMarketMaxRepos
    $script:SkillMarketMinStarsInt = [int]$SkillMarketMinStars
    $script:SkillMarketMergeSourceRetentionCountInt = [int]$SkillMarketMergeSourceRetentionCount
    $script:SkillMarketMergeSourceRetentionDaysInt = [int]$SkillMarketMergeSourceRetentionDays
    Build-MarketAllowlistSet
}

function Resolve-RepoSpec {
    param([string]$SpecRaw)

    if ([string]::IsNullOrWhiteSpace($SpecRaw)) { return $null }
    $Spec = $SpecRaw.Trim()
    $Ref = "main"

    if ($Spec -match '^([^/@\s]+/[^/@\s]+)@(.+)$') {
        $Spec = $Matches[1]
        $Ref = $Matches[2]
    }

    $Slug = Resolve-RepoSlug -RepoUrlValue $Spec
    if (-not $Slug) { return $null }

    $CloneUrl = $null
    if ($Spec -match '^https://github\.com/') {
        $CloneUrl = $Spec.TrimEnd("/")
        if (-not $CloneUrl.EndsWith(".git")) { $CloneUrl = "$CloneUrl.git" }
    } elseif ($Spec -match '^git@github\.com:' -or $Spec -match '^ssh://git@github\.com/') {
        $CloneUrl = $Spec
    } else {
        $CloneUrl = "https://github.com/$Slug.git"
    }

    return [PSCustomObject]@{
        Slug     = $Slug
        CloneUrl = $CloneUrl
        Ref      = $Ref
    }
}

function Add-MarketCandidate {
    param(
        [string]$Slug,
        [string]$CloneUrl,
        [string]$Ref,
        [int]$Stars,
        [string]$Source
    )

    if ([string]::IsNullOrWhiteSpace($Slug) -or [string]::IsNullOrWhiteSpace($CloneUrl)) { return }
    $Script:MarketCandidates.Add([PSCustomObject]@{
        Slug     = $Slug
        CloneUrl = $CloneUrl
        Ref      = if ([string]::IsNullOrWhiteSpace($Ref)) { "main" } else { $Ref }
        Stars    = $Stars
        Source   = $Source
    }) | Out-Null
}

function Collect-ManifestMarketCandidates {
    if (-not (Test-Path $Script:MarketRepoSeedFile)) { return }

    foreach ($Line in (Get-Content -Path $Script:MarketRepoSeedFile -Encoding UTF8)) {
        $Item = $Line.Trim()
        if (-not $Item) { continue }
        if ($Item.StartsWith("#")) { continue }

        $Resolved = Resolve-RepoSpec -SpecRaw $Item
        if (-not $Resolved) {
            Write-Warn "[market] 无法识别 seed 仓库: $Item"
            continue
        }
        Add-MarketCandidate -Slug $Resolved.Slug -CloneUrl $Resolved.CloneUrl -Ref $Resolved.Ref -Stars 0 -Source "manifest"
    }
}

function Collect-ExtraMarketCandidates {
    if ([string]::IsNullOrWhiteSpace($SkillMarketExtraRepos)) { return }

    foreach ($Item in ($SkillMarketExtraRepos -split '[,\r\n]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        $Resolved = Resolve-RepoSpec -SpecRaw $Item
        if (-not $Resolved) {
            Write-Warn "[market] 无法识别额外仓库: $Item"
            continue
        }
        Add-MarketCandidate -Slug $Resolved.Slug -CloneUrl $Resolved.CloneUrl -Ref $Resolved.Ref -Stars 0 -Source "extra"
    }
}

function Discover-GitHubMarketCandidates {
    $Queries = $SkillMarketQueries -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if (-not $Queries -or $Queries.Count -eq 0) { return }

    $ParsedCount = 0
    $Headers = @{
        "User-Agent" = "agent-skills-installer"
    }
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        $Headers["Authorization"] = "Bearer $($env:GITHUB_TOKEN)"
    }

    foreach ($Query in $Queries) {
        $Encoded = [System.Uri]::EscapeDataString($Query)
        $ApiUrl = "https://api.github.com/search/repositories?q=$Encoded&sort=stars&order=desc&per_page=$($Script:SkillMarketPerQueryInt)"
        Write-DebugInfo "[market] GitHub 搜索: $Query"

        try {
            $Response = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -TimeoutSec 20
        } catch {
            Write-Warn "[market] GitHub 查询失败: $Query"
            continue
        }

        if (-not $Response -or -not $Response.items) { continue }
        foreach ($Item in $Response.items) {
            if (-not $Item.full_name -or -not $Item.clone_url) { continue }
            $Ref = if ($Item.default_branch) { [string]$Item.default_branch } else { "main" }
            $Stars = if ($null -ne $Item.stargazers_count) { [int]$Item.stargazers_count } else { 0 }
            Add-MarketCandidate -Slug ([string]$Item.full_name) -CloneUrl ([string]$Item.clone_url) -Ref $Ref -Stars $Stars -Source "github"
            $ParsedCount++
        }
    }

    if ($ParsedCount -eq 0) {
        Write-Warn "[market] GitHub 查询无可用结果（可能受 API 频率限制，可设置 GITHUB_TOKEN）"
    }
}

function Finalize-MarketCandidates {
    if ($Script:MarketCandidates.Count -eq 0) { return @() }

    $Best = @{}
    foreach ($Candidate in $Script:MarketCandidates) {
        $Slug = [string]$Candidate.Slug
        if (-not $Slug) { continue }
        $SlugLower = $Slug.ToLowerInvariant()
        if ($Script:SkillMarketAllowlistSet.Count -gt 0 -and -not $Script:SkillMarketAllowlistSet.ContainsKey($SlugLower)) { continue }
        if ($Script:PrimaryRepoSlug -and $Slug -eq $Script:PrimaryRepoSlug) { continue }
        if ($Candidate.Source -eq "github" -and [int]$Candidate.Stars -lt $Script:SkillMarketMinStarsInt) { continue }

        if (-not $Best.ContainsKey($Slug) -or [int]$Candidate.Stars -gt [int]$Best[$Slug].Stars) {
            $Best[$Slug] = $Candidate
        }
    }

    if ($Best.Count -eq 0) { return @() }
    return $Best.Values | Sort-Object { [int]$_.Stars } -Descending | Select-Object -First $Script:SkillMarketMaxReposInt
}

function Collect-MarketRepoCandidates {
    $Script:MarketCandidates.Clear()
    if ($SkillMarketDiscovery -eq "off") { return @() }

    if ($SkillMarketDiscovery -eq "manifest" -or $SkillMarketDiscovery -eq "all") {
        Collect-ManifestMarketCandidates
    }
    if ($SkillMarketDiscovery -eq "github" -or $SkillMarketDiscovery -eq "all") {
        Discover-GitHubMarketCandidates
    }
    Collect-ExtraMarketCandidates
    return @(Finalize-MarketCandidates)
}

function Get-RepoSkillEntries {
    param([string]$RepoDir)

    $ManifestFile = Join-Path $RepoDir "scripts\manifest\skills.txt"
    if (Test-Path $ManifestFile) {
        return @(Get-ManifestEntries -Path $ManifestFile)
    }

    $SkillsDir = Join-Path $RepoDir "skills"
    if (-not (Test-Path $SkillsDir)) { return @() }

    $Entries = New-Object System.Collections.Generic.List[string]
    Get-ChildItem -Path $SkillsDir -Directory | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName "SKILL.md")) {
            $Entries.Add($_.Name) | Out-Null
        }
    }
    return $Entries | Sort-Object
}

function Get-SkillSourceSlug {
    param([string]$SkillDir)
    $SourceFile = Join-Path $SkillDir $SkillMarketSourceMarkFile
    if (-not (Test-Path $SourceFile)) { return $null }

    foreach ($Line in (Get-Content -Path $SourceFile -Encoding UTF8)) {
        if ($Line -match '^repo_slug=(.+)$') {
            return $Matches[1].Trim()
        }
    }
    return $null
}

function Write-SkillSourceMetadata {
    param(
        [string]$SkillDir,
        [string]$RepoSlug,
        [string]$RepoUrlValue,
        [string]$RepoRef
    )

    $SourceFile = Join-Path $SkillDir $SkillMarketSourceMarkFile
    @(
        "repo_slug=$RepoSlug"
        "repo_url=$RepoUrlValue"
        "repo_ref=$RepoRef"
        "synced_at=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    ) | Set-Content -Path $SourceFile -Encoding UTF8
}

function Sanitize-PathToken {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return "unknown" }
    return ($Value -replace '[^A-Za-z0-9._-]+', '_')
}

function Cleanup-MergeSourceSnapshots {
    param(
        [string]$MergeRoot,
        [int]$MaxCount,
        [int]$MaxDays
    )

    if (-not (Test-Path $MergeRoot)) { return }

    if ($MaxDays -gt 0) {
        $Cutoff = [DateTime]::UtcNow.AddDays(-$MaxDays)
        Get-ChildItem -Path $MergeRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTimeUtc -lt $Cutoff } |
            ForEach-Object {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
    }

    if ($MaxCount -le 0) { return }
    $Dirs = @(Get-ChildItem -Path $MergeRoot -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending)
    if ($Dirs.Count -le $MaxCount) { return }
    $Dirs | Select-Object -Skip $MaxCount | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-MergeScript {
    param([string[]]$Arguments)

    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        & python3 @Arguments
        return $LASTEXITCODE -eq 0
    }
    if (Get-Command python -ErrorAction SilentlyContinue) {
        & python @Arguments
        return $LASTEXITCODE -eq 0
    }
    if (Get-Command py -ErrorAction SilentlyContinue) {
        & py -3 @Arguments
        return $LASTEXITCODE -eq 0
    }
    return $false
}

function Merge-MarketSkillInPlace {
    param(
        [string]$SkillTarget,
        [string]$IncomingSkill,
        [string]$RepoSlug,
        [string]$RepoUrlValue,
        [string]$RepoRef,
        [string]$TargetName,
        [string]$SkillName
    )

    $BaseSkillFile = Join-Path $SkillTarget "SKILL.md"
    $IncomingSkillFile = Join-Path $IncomingSkill "SKILL.md"
    if (-not (Test-Path $BaseSkillFile)) {
        Write-Warn "[$TargetName][market:$RepoSlug] 无法融合 ${SkillName}：本地缺少 SKILL.md"
        return $false
    }
    if (-not (Test-Path $IncomingSkillFile)) {
        Write-Warn "[$TargetName][market:$RepoSlug] 无法融合 ${SkillName}：外部缺少 SKILL.md"
        return $false
    }
    if (-not (Test-Path $Script:MergeSkillScriptPath)) {
        Write-Warn "[$TargetName][market:$RepoSlug] 无法融合 ${SkillName}：merge 脚本缺失"
        return $false
    }

    $SourceTag = Sanitize-PathToken -Value $RepoSlug
    $MergeSourceRoot = Join-Path $SkillTarget $SkillMarketMergeSourceDir
    $MergeSourceDir = Join-Path $MergeSourceRoot $SourceTag
    $MergeBackupFile = Join-Path $SkillTarget $SkillMarketMergeBackupFileName
    $MergeActionLabel = "已融合"
    if (Test-Path $MergeSourceDir) {
        Remove-Item -Path $MergeSourceDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $MergeSourceRoot -Force | Out-Null
    Copy-Item -Path $IncomingSkill -Destination $MergeSourceDir -Recurse
    Cleanup-MergeSourceSnapshots -MergeRoot $MergeSourceRoot -MaxCount $Script:SkillMarketMergeSourceRetentionCountInt -MaxDays $Script:SkillMarketMergeSourceRetentionDaysInt

    $MergedFile = Join-Path $SkillTarget $SkillMarketMergedFileName
    $ReportFile = Join-Path $SkillTarget $SkillMarketMergeReportFileName
    $Args = @(
        $Script:MergeSkillScriptPath,
        "--base", $BaseSkillFile,
        "--incoming", $IncomingSkillFile,
        "--output", $MergedFile,
        "--report", $ReportFile,
        "--source", $RepoSlug
    )

    if (-not (Invoke-MergeScript -Arguments $Args)) {
        Write-Warn "[$TargetName][market:$RepoSlug] 融合失败: ${SkillName}"
        return $false
    }

    @(
        "repo_slug=$RepoSlug"
        "repo_url=$RepoUrlValue"
        "repo_ref=$RepoRef"
        "merged_at=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        "merged_file=$SkillMarketMergedFileName"
        "report_file=$SkillMarketMergeReportFileName"
        "source_snapshot_dir=$SkillMarketMergeSourceDir/$SourceTag"
        "apply_mode=$SkillMarketMergeApplyMode"
    ) | Set-Content -Path (Join-Path $SkillTarget ".agent-skills-merge-source") -Encoding UTF8

    if ($SkillMarketMergeApplyMode -eq "apply") {
        Copy-Item -Path $BaseSkillFile -Destination $MergeBackupFile -Force
        Copy-Item -Path $MergedFile -Destination $BaseSkillFile -Force
        $MergeActionLabel = "已融合并应用"
    }

    Write-Info "[$TargetName][market:$RepoSlug] ${MergeActionLabel}: ${SkillName} -> $SkillMarketMergedFileName"
    return $true
}

function Install-MarketSkillsFromRepoToDir {
    param(
        [string]$RepoDir,
        [string]$RepoSlug,
        [string]$RepoUrlValue,
        [string]$RepoRef,
        [string]$TargetDir,
        [string]$TargetName
    )

    $SourceDir = Join-Path $RepoDir "skills"
    if (-not (Test-Path $SourceDir)) {
        Write-Warn "[$TargetName][market:$RepoSlug] 未找到 skills 目录，跳过"
        return
    }
    if (-not (Test-Path $TargetDir) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    foreach ($SkillName in (Get-RepoSkillEntries -RepoDir $RepoDir)) {
        $SkillSource = Join-Path $SourceDir $SkillName
        if (-not (Test-Path $SkillSource)) { continue }

        $SkillTarget = Join-Path $TargetDir $SkillName
        $ShouldApply = $false
        $ShouldMerge = $false
        $ActionLabel = "安装"
        $Changed = $false

        if (Test-Path $SkillTarget) {
            $ExistingSlug = Get-SkillSourceSlug -SkillDir $SkillTarget
            if ($ExistingSlug -eq $RepoSlug) {
                if (Test-ShouldUpdate -SkillName $SkillName -TargetName $TargetName) {
                    $ShouldApply = $true
                    $ActionLabel = "更新"
                } else {
                    Write-Warn "[$TargetName][market:$RepoSlug] 跳过: $SkillName"
                }
            } else {
                switch ($SkillMarketConflictMode) {
                    "replace" {
                        if (Test-ShouldUpdate -SkillName $SkillName -TargetName $TargetName) {
                            $ShouldApply = $true
                            $ActionLabel = "覆盖"
                        } else {
                            Write-Warn "[$TargetName][market:$RepoSlug] 跳过冲突 skill: $SkillName"
                        }
                    }
                    "merge" {
                        if (Test-ShouldUpdate -SkillName $SkillName -TargetName $TargetName) {
                            $ShouldMerge = $true
                            $ActionLabel = "融合"
                        } else {
                            Write-Warn "[$TargetName][market:$RepoSlug] 跳过融合 skill: $SkillName"
                        }
                    }
                    default {
                        Write-Warn "[$TargetName][market:$RepoSlug] 跳过冲突 skill: ${SkillName}（已存在且来源不同）"
                    }
                }
            }
        } else {
            $ShouldApply = $true
        }

        if (-not $ShouldApply -and -not $ShouldMerge) { continue }

        if ($DryRun) {
            Write-Info "[DRY-RUN][$TargetName][market:$RepoSlug] 将${ActionLabel}: ${SkillName}"
            $Changed = $true
        } else {
            if ($ShouldMerge) {
                $Changed = Merge-MarketSkillInPlace -SkillTarget $SkillTarget -IncomingSkill $SkillSource -RepoSlug $RepoSlug -RepoUrlValue $RepoUrlValue -RepoRef $RepoRef -TargetName $TargetName -SkillName $SkillName
            } else {
                if (Test-Path $SkillTarget) {
                    Remove-Item -Path $SkillTarget -Recurse -Force
                }
                Copy-Item -Path $SkillSource -Destination $TargetDir -Recurse
                Write-SkillSourceMetadata -SkillDir $SkillTarget -RepoSlug $RepoSlug -RepoUrlValue $RepoUrlValue -RepoRef $RepoRef
                Write-Info "[$TargetName][market:$RepoSlug] 已${ActionLabel}: ${SkillName}"
                $Changed = $true
            }
        }

        if ($Changed) {
            $Script:InstalledSkills[$TargetName].Add($SkillName)
        }
    }
}

function Sync-MarketSkills {
    param([string]$Target)

    if ($SkillMarketDiscovery -eq "off") { return }
    $Candidates = @(Collect-MarketRepoCandidates)
    if (-not $Candidates -or $Candidates.Count -eq 0) {
        Write-Warn "[market] 未发现可同步的外部 skill 仓库"
        return
    }

    Write-Info "[market] 已启用外部 skill 市场同步（mode=$SkillMarketDiscovery）"
    $Index = 0
    foreach ($Candidate in $Candidates) {
        $Index++
        $RepoDir = Join-Path $TempDir ("market-repo-$Index")
        Write-Info "[market] 同步仓库: $($Candidate.Slug) (source=$($Candidate.Source) stars=$($Candidate.Stars) ref=$($Candidate.Ref))"

        $Cloned = $false
        try {
            git clone --depth 1 --branch $Candidate.Ref $Candidate.CloneUrl $RepoDir | Out-Null
            $Cloned = $true
        } catch {
            if (Test-Path $RepoDir) {
                Remove-Item -Path $RepoDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            try {
                git clone --depth 1 $Candidate.CloneUrl $RepoDir | Out-Null
                $Cloned = $true
            } catch {
                Write-Warn "[market] 克隆失败，跳过: $($Candidate.Slug)"
            }
        }
        if (-not $Cloned) { continue }

        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "claude") {
            Install-MarketSkillsFromRepoToDir -RepoDir $RepoDir -RepoSlug $Candidate.Slug -RepoUrlValue $Candidate.CloneUrl -RepoRef $Candidate.Ref -TargetDir $ClaudeSkillsDir -TargetName "Claude Code"
        }
        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "codex") {
            Install-MarketSkillsFromRepoToDir -RepoDir $RepoDir -RepoSlug $Candidate.Slug -RepoUrlValue $Candidate.CloneUrl -RepoRef $Candidate.Ref -TargetDir $CodexSkillsDir -TargetName "Codex CLI"
        }
        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "gemini") {
            Install-MarketSkillsFromRepoToDir -RepoDir $RepoDir -RepoSlug $Candidate.Slug -RepoUrlValue $Candidate.CloneUrl -RepoRef $Candidate.Ref -TargetDir $GeminiSkillsDir -TargetName "Gemini CLI"
        }
    }
}

function Is-Truthy {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    switch ($Value.Trim().ToLowerInvariant()) {
        "1" { return $true }
        "true" { return $true }
        "yes" { return $true }
        "on" { return $true }
        default { return $false }
    }
}

function Sync-CodexLocalVersion {
    $VersionFile = Join-Path $TempDir "scripts\manifest\version.txt"
    $Version = ""
    if (Test-Path $VersionFile) {
        $Version = (Get-Content -Path $VersionFile -Raw -Encoding UTF8).Trim()
    }
    if (-not $Version) {
        try {
            $Version = (git -C $TempDir rev-parse --short=12 HEAD).Trim()
        } catch {
            $Version = ""
        }
    }
    if (-not $Version) {
        Write-Warn "[Codex CLI] 无法写入本地 skills 版本（version/commit 均不可用）"
        return
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $CodexLocalVersionFile) -Force | Out-Null
    Set-Content -Path $CodexLocalVersionFile -Value $Version -Encoding UTF8
    Write-Info "[Codex CLI] 已写入本地 skills 版本: $Version"
}

function Upsert-ProfileSourceBlock {
    param([string]$ProfilePath)

    $StartMarker = "# >>> agent-skills codex auto-update >>>"
    $EndMarker = "# <<< agent-skills codex auto-update <<<"
    $SourceLine = '. "$env:USERPROFILE\.codex\codex-skills-auto-update.ps1"'

    New-Item -ItemType Directory -Path (Split-Path -Parent $ProfilePath) -Force | Out-Null
    if (-not (Test-Path $ProfilePath)) {
        New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
    }

    $Content = Get-Content -Path $ProfilePath -Raw -Encoding UTF8
    $Pattern = [Regex]::Escape($StartMarker) + '.*?' + [Regex]::Escape($EndMarker)
    $Block = "$StartMarker`r`n$SourceLine`r`n$EndMarker"

    if ($Content -match $Pattern) {
        $NewContent = [Regex]::Replace($Content, $Pattern, $Block, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    } elseif ([string]::IsNullOrWhiteSpace($Content)) {
        $NewContent = "$Block`r`n"
    } else {
        $NewContent = $Content.TrimEnd() + "`r`n`r`n" + $Block + "`r`n"
    }
    Set-Content -Path $ProfilePath -Value $NewContent -Encoding UTF8
}

function Configure-CodexAutoUpdateLauncher {
    if (-not (Is-Truthy $CodexAutoUpdateSetup)) {
        Write-Info "[Codex CLI] 跳过自动更新配置（CODEX_AUTO_UPDATE_SETUP=$CodexAutoUpdateSetup）"
        return
    }

    $RepoSlug = if ($CodexAutoUpdateRepo) { $CodexAutoUpdateRepo } else { Resolve-RepoSlug -RepoUrlValue $RepoUrl }
    if (-not $RepoSlug) {
        $RepoSlug = "biglone/agent-skills"
        Write-Warn "[Codex CLI] 无法从 SKILLS_REPO 推断 GitHub 仓库，已回退为: $RepoSlug"
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $CodexAutoUpdateLoader) -Force | Out-Null
    $LoaderContent = @"
# Auto-generated by agent-skills/scripts/install.ps1
# Set CODEX_SKILLS_AUTO_UPDATE=0 to disable auto update checks.
if (`$env:CODEX_SKILLS_AUTO_UPDATE -eq "0") {
    return
}

`$repo = "$RepoSlug"
`$ref = "$CodexAutoUpdateBranch"
`$versionUrl = "https://raw.githubusercontent.com/`$repo/`$ref/scripts/manifest/version.txt"
`$installUrl = "https://raw.githubusercontent.com/`$repo/`$ref/scripts/install.ps1"
`$localVersionFile = "$CodexLocalVersionFile"

try {
    `$remoteVersion = (Invoke-RestMethod -Uri `$versionUrl -TimeoutSec 8).ToString().Trim()
} catch {
    `$remoteVersion = ""
}
if (-not `$remoteVersion) {
    return
}

`$localVersion = ""
if (Test-Path `$localVersionFile) {
    `$localVersion = (Get-Content -Path `$localVersionFile -Raw -Encoding UTF8).Trim()
}

if (`$remoteVersion -ne `$localVersion) {
    Write-Host "[skills] update `$localVersion -> `$remoteVersion"
    `$oldUpdateMode = `$env:UPDATE_MODE
    `$oldInstallTarget = `$env:INSTALL_TARGET
    `$oldAutoSetup = `$env:CODEX_AUTO_UPDATE_SETUP
    `$oldSkillsRef = `$env:SKILLS_REF
    try {
        `$env:UPDATE_MODE = "force"
        `$env:INSTALL_TARGET = "codex"
        `$env:CODEX_AUTO_UPDATE_SETUP = "off"
        `$env:SKILLS_REF = `$ref
        `$installTemp = Join-Path `$env:TEMP ("codex-skills-install-" + [System.Guid]::NewGuid().ToString("N") + ".ps1")
        Invoke-WebRequest -Uri `$installUrl -OutFile `$installTemp -TimeoutSec 20
        powershell -NoProfile -ExecutionPolicy Bypass -File `$installTemp
        Set-Content -Path `$localVersionFile -Value `$remoteVersion -Encoding UTF8
    } catch {
        Write-Host "[skills] auto-update failed, continue launching codex" -ForegroundColor Yellow
    } finally {
        if ((Get-Variable installTemp -Scope Local -ErrorAction SilentlyContinue) -and (Test-Path `$installTemp)) {
            Remove-Item `$installTemp -Force -ErrorAction SilentlyContinue
        }
        if (`$null -eq `$oldUpdateMode) { Remove-Item Env:UPDATE_MODE -ErrorAction SilentlyContinue } else { `$env:UPDATE_MODE = `$oldUpdateMode }
        if (`$null -eq `$oldInstallTarget) { Remove-Item Env:INSTALL_TARGET -ErrorAction SilentlyContinue } else { `$env:INSTALL_TARGET = `$oldInstallTarget }
        if (`$null -eq `$oldAutoSetup) { Remove-Item Env:CODEX_AUTO_UPDATE_SETUP -ErrorAction SilentlyContinue } else { `$env:CODEX_AUTO_UPDATE_SETUP = `$oldAutoSetup }
        if (`$null -eq `$oldSkillsRef) { Remove-Item Env:SKILLS_REF -ErrorAction SilentlyContinue } else { `$env:SKILLS_REF = `$oldSkillsRef }
    }
}
"@
    Set-Content -Path $CodexAutoUpdateLoader -Value $LoaderContent -Encoding UTF8

    $ProfileCandidates = @(
        $PROFILE.CurrentUserCurrentHost
        Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
        Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    ) | Select-Object -Unique

    foreach ($ProfilePath in $ProfileCandidates) {
        Upsert-ProfileSourceBlock -ProfilePath $ProfilePath
    }

    Write-Info "[Codex CLI] 已配置 PowerShell 启动时检查 skills 更新"
    Write-Info "[Codex CLI] 配置文件: $CodexAutoUpdateLoader"
}

function Test-Git {
    try {
        git --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Select-Target {
    $TargetFromEnv = Resolve-InstallTargetFromEnv
    if ($TargetFromEnv) {
        return $TargetFromEnv
    }

    if ($NonInteractive) {
        Write-Info "非交互模式：默认安装到两者（INSTALL_TARGET=both）"
        return "both"
    }

    Write-Host ""
    Write-Host "请选择安装目标:" -ForegroundColor Cyan
    Write-Host "  1) Claude Code"
    Write-Host "  2) OpenAI Codex CLI"
    Write-Host "  3) Gemini CLI"
    Write-Host "  4) Claude Code + Codex CLI"
    Write-Host "  5) 全部安装"
    Write-Host ""

    $choice = Read-Host "请输入选项 [1-5] (默认: 4)"

    switch ($choice) {
        "1" { return "claude" }
        "2" { return "codex" }
        "3" { return "gemini" }
        "4" { return "both" }
        "5" { return "all" }
        "" { return "both" }
        default { return "both" }
    }
}

function Test-ShouldUpdate {
    param($SkillName, $TargetName)

    if ($UpdateMode -eq "skip") {
        return $false
    } elseif ($UpdateMode -eq "force") {
        return $true
    }

    # ask 模式：仅在可交互会话中询问，避免 CI / 重定向环境卡住
    if ($NonInteractive -or -not (Test-InteractiveSession)) {
        if (-not $Script:AskFallbackWarned) {
            Write-Warn "非交互环境且 UPDATE_MODE=ask，将按 force 处理"
            $Script:AskFallbackWarned = $true
        }
        return $true
    }

    Write-Host ""
    $answer = Read-Host "[$TargetName] Skill '$SkillName' 已存在，是否更新? [y/N]"

    if ($answer -match "^[Yy]") {
        return $true
    }
    return $false
}

function Install-SkillsToDir {
    param($TargetDir, $TargetName, $SourceDir)

    if (-not (Test-Path $TargetDir)) {
        Write-Info "创建 $TargetName skills 目录: $TargetDir"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        }
    }

    Write-Info "安装 skills 到 $TargetName..."

    foreach ($SkillName in $Script:SkillsManifest) {
        $SkillSource = Join-Path $SourceDir $SkillName
        if (-not (Test-Path $SkillSource)) {
            Write-Warn "[$TargetName] manifest 中的 skill 不存在，跳过: $SkillName"
            continue
        }

        $SkillTarget = Join-Path $TargetDir $SkillName

        if (Test-Path $SkillTarget) {
            if (Test-ShouldUpdate -SkillName $SkillName -TargetName $TargetName) {
                if ($DryRun) {
                    Write-Info "[DRY-RUN][$TargetName] 将更新: $SkillName"
                } else {
                    Remove-Item -Path $SkillTarget -Recurse -Force
                    Copy-Item -Path $SkillSource -Destination $TargetDir -Recurse
                    Write-Info "[$TargetName] 已更新: $SkillName"
                }
                $Script:InstalledSkills[$TargetName].Add($SkillName)
            } else {
                Write-Warn "[$TargetName] 跳过: $SkillName"
            }
        } else {
            if ($DryRun) {
                Write-Info "[DRY-RUN][$TargetName] 将安装: $SkillName"
            } else {
                Copy-Item -Path $SkillSource -Destination $TargetDir -Recurse
                Write-Info "[$TargetName] 已安装: $SkillName"
            }
            $Script:InstalledSkills[$TargetName].Add($SkillName)
        }
    }
}

function Install-WorkflowsToDir {
    param($TargetDir, $TargetName, $SourceDir)

    if (-not (Test-Path $SourceDir)) {
        Write-Warn "workflows 目录不存在，跳过"
        return
    }

    if (-not (Test-Path $TargetDir)) {
        Write-Info "创建 $TargetName workflows 目录: $TargetDir"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        }
    }

    Write-Info "安装 workflows 到 $TargetName..."

    if ($Script:WorkflowsManifest.Count -eq 0) {
        Write-Warn "workflows manifest 为空，跳过"
        return
    }

    foreach ($WorkflowName in $Script:WorkflowsManifest) {
        $WorkflowSource = Join-Path $SourceDir $WorkflowName
        if (-not (Test-Path $WorkflowSource)) {
            Write-Warn "[$TargetName] manifest 中的 workflow 不存在，跳过: $WorkflowName"
            continue
        }

        $WorkflowTarget = Join-Path $TargetDir $WorkflowName

        if (Test-Path $WorkflowTarget) {
            if (Test-ShouldUpdate -SkillName $WorkflowName -TargetName $TargetName) {
                if ($DryRun) {
                    Write-Info "[DRY-RUN][$TargetName] 将更新 workflow: $WorkflowName"
                } else {
                    Remove-Item -Path $WorkflowTarget -Recurse -Force
                    Copy-Item -Path $WorkflowSource -Destination $TargetDir -Recurse
                    Write-Info "[$TargetName] 已更新 workflow: $WorkflowName"
                }
            } else {
                Write-Warn "[$TargetName] 跳过 workflow: $WorkflowName"
            }
        } else {
            if ($DryRun) {
                Write-Info "[DRY-RUN][$TargetName] 将安装 workflow: $WorkflowName"
            } else {
                Copy-Item -Path $WorkflowSource -Destination $TargetDir -Recurse
                Write-Info "[$TargetName] 已安装 workflow: $WorkflowName"
            }
        }
    }
}

function Show-Installed {
    param($SkillsDir, $Name)

    if (-not (Test-Path $SkillsDir) -and -not $DryRun) { return }

    Write-Host ""
    Write-Info "$Name 本次安装/更新的 Skills:"
    Write-Host "─────────────────────────────────────────"

    $Changed = $Script:InstalledSkills[$Name] | Sort-Object -Unique
    if (-not $Changed -or $Changed.Count -eq 0) {
        Write-Host "  (无变更)" -ForegroundColor DarkGray
        Write-Host "─────────────────────────────────────────"
        return
    }

    $Changed | ForEach-Object {
        $SkillName = $_
        if ($DryRun) {
            Write-Host "  • $SkillName (planned)" -ForegroundColor White
            return
        }

        $SkillPath = Join-Path $SkillsDir $SkillName
        $SkillFile = Join-Path $SkillPath "SKILL.md"
        if (Test-Path $SkillFile) {
            Write-Host "  • $SkillName" -ForegroundColor White

            # SKILL.md 使用 UTF-8，Windows PowerShell 5.1 默认读取编码会导致中文乱码
            $Content = Get-Content $SkillFile -Raw -Encoding UTF8
            if ($Content -match 'description:\s*(.+)') {
                $Desc = $Matches[1].Trim()
                Write-Host "    $Desc" -ForegroundColor Gray
            }
        }
    }

    Write-Host "─────────────────────────────────────────"
}

function Main {
    param([string[]]$ScriptArgs)

    Parse-Args -ScriptArgs $ScriptArgs

    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     AI Coding Skills 安装程序             ║" -ForegroundColor Cyan
    Write-Host "║ 支持 Claude Code / Codex / Gemini CLI     ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    if ($DryRun) {
        Write-Info "已启用 dry-run：不会写入目标目录"
    }

    $Target = $null
    $Succeeded = $false

    try {
        # 校验并归一化更新策略
        $script:UpdateMode = Resolve-UpdateMode -Mode $UpdateMode
        Validate-MarketConfig

        # 检查 Git
        if (-not (Test-Git)) {
            throw "Git 未安装，请先安装 Git"
        }

        # 选择目标
        $Target = Select-Target

        # 克隆仓库
        Write-Info "克隆 skills 仓库..."
        Write-DebugInfo "clone source: $RepoUrl"
        Write-DebugInfo "clone ref: $SkillsRef"
        Write-DebugInfo "clone target: $TempDir"
        try {
            git clone --depth 1 --branch $SkillsRef $RepoUrl $TempDir | Out-Null
        } catch {
            Write-Warn "按 branch/ref 克隆失败，尝试回退克隆后 checkout: $SkillsRef"
            if (Test-Path $TempDir) {
                Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            try {
                git clone --depth 1 $RepoUrl $TempDir | Out-Null
                if (-not [string]::IsNullOrWhiteSpace($SkillsRef)) {
                    git -C $TempDir checkout $SkillsRef | Out-Null
                }
            } catch {
                throw "克隆仓库失败，请检查仓库地址/引用: $RepoUrl @ $SkillsRef"
            }
        }

        $SourceDir = Join-Path $TempDir "skills"
        $WorkflowsSourceDir = Join-Path $TempDir "workflows"
        $Script:PrimaryRepoSlug = Resolve-RepoSlug -RepoUrlValue $RepoUrl
        Set-Manifests

        if (-not (Test-Path $SourceDir)) {
            throw "skills 目录不存在"
        }

        # 安装 skills
        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "claude") {
            Install-SkillsToDir -TargetDir $ClaudeSkillsDir -TargetName "Claude Code" -SourceDir $SourceDir
            Install-WorkflowsToDir -TargetDir $ClaudeWorkflowsDir -TargetName "Claude Code" -SourceDir $WorkflowsSourceDir
        }

        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "codex") {
            Install-SkillsToDir -TargetDir $CodexSkillsDir -TargetName "Codex CLI" -SourceDir $SourceDir
            Install-WorkflowsToDir -TargetDir $CodexWorkflowsDir -TargetName "Codex CLI" -SourceDir $WorkflowsSourceDir
        }

        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "gemini") {
            Install-SkillsToDir -TargetDir $GeminiSkillsDir -TargetName "Gemini CLI" -SourceDir $SourceDir
        }

        Sync-MarketSkills -Target $Target

        # 显示已安装
        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "claude") {
            Show-Installed -SkillsDir $ClaudeSkillsDir -Name "Claude Code"
        }

        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "codex") {
            Show-Installed -SkillsDir $CodexSkillsDir -Name "Codex CLI"
        }

        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "gemini") {
            Show-Installed -SkillsDir $GeminiSkillsDir -Name "Gemini CLI"
        }

        if (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "codex") {
            if ($DryRun) {
                Write-Info "[DRY-RUN] 跳过写入 Codex 本地版本与自动更新配置"
            } else {
                Sync-CodexLocalVersion
                Configure-CodexAutoUpdateLauncher
            }
        }

        $Succeeded = $true
    } finally {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($Succeeded) {
        Write-Host ""
        Write-Info "安装完成! 请重启对应的 AI 编程工具以加载 Skills"
        if (-not $DryRun -and (Test-InstallTargetIncludes -SelectedTarget $Target -Platform "codex")) {
            Write-Info "Codex 自动更新配置已写入 PowerShell profile，新终端会生效"
        }
    }
}

try {
    Main -ScriptArgs $args
} catch {
    Write-Err $_.Exception.Message
    exit 1
}
