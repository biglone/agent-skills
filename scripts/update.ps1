# AI Coding Skills 更新脚本 (Windows PowerShell)
# 支持 Claude Code 和 OpenAI Codex CLI

$ErrorActionPreference = "Stop"

$RepoUrl = if ($env:SKILLS_REPO) { $env:SKILLS_REPO } else { "https://github.com/biglone/agent-skills.git" }
$SkillsRef = if ($env:SKILLS_REF) { $env:SKILLS_REF } else { "main" }
$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$CodexSkillsDir = Join-Path $env:USERPROFILE ".codex\skills"
$ClaudeWorkflowsDir = Join-Path $env:USERPROFILE ".claude\workflows"
$CodexWorkflowsDir = Join-Path $env:USERPROFILE ".codex\workflows"
$TempDir = Join-Path $env:TEMP "ai-skills-$(Get-Random)"
$PruneMode = if ($env:PRUNE_MODE) { $env:PRUNE_MODE.ToLower() } else { "off" }  # on/off
$DebugMode = ($env:DEBUG -eq "1" -or $env:DEBUG -eq "true")
$Script:SkillsManifest = @()
$Script:WorkflowsManifest = @()
$Script:MarketRepoSeedFile = $null
$Script:MergeSkillScriptPath = $null
$Script:PrimaryRepoSlug = $null
$Script:MarketCandidates = New-Object System.Collections.Generic.List[object]
$Script:SkillMarketAllowlistSet = @{}

# Skills Market 配置
$SkillMarketDiscovery = if ($env:SKILL_MARKET_DISCOVERY) { $env:SKILL_MARKET_DISCOVERY.Trim().ToLowerInvariant() } else { "off" }  # off/manifest/github/all
$SkillMarketQueries = if ($env:SKILL_MARKET_QUERIES) { $env:SKILL_MARKET_QUERIES } else { "topic:agent-skills;topic:claude-code-skill;topic:codex-skill" }
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

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-DebugInfo { param($Message) if ($DebugMode) { Write-Host "[DEBUG] $Message" -ForegroundColor Cyan } }

function Get-ManifestEntriesFromFile {
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
    $SkillsManifestFile = Join-Path $TempDir "scripts\manifest\skills.txt"
    $WorkflowsManifestFile = Join-Path $TempDir "scripts\manifest\workflows.txt"

    $Script:SkillsManifest = Get-ManifestEntriesFromFile -Path $SkillsManifestFile
    if ($Script:SkillsManifest.Count -eq 0) {
        throw "skills manifest 为空"
    }

    if (Test-Path $WorkflowsManifestFile) {
        $Script:WorkflowsManifest = Get-ManifestEntriesFromFile -Path $WorkflowsManifestFile
    } else {
        Write-Warn "workflows manifest 不存在，跳过 workflows 更新"
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

function Test-ManifestContains {
    param([string[]]$Manifest, [string]$Name)
    return $Manifest -contains $Name
}

function Resolve-UpdateTargetFromEnv {
    if ([string]::IsNullOrWhiteSpace($env:UPDATE_TARGET)) {
        return $null
    }

    $Target = $env:UPDATE_TARGET.Trim().ToLowerInvariant()
    switch ($Target) {
        "claude" { return "claude" }
        "codex" { return "codex" }
        "both" { return "both" }
        default { throw "UPDATE_TARGET 无效: '$($env:UPDATE_TARGET)'。可选值: claude / codex / both" }
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
        "User-Agent" = "agent-skills-updater"
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
        return @(Get-ManifestEntriesFromFile -Path $ManifestFile)
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

function Prune-RemovedDirs {
    param($TargetDir, [string[]]$Manifest, $TargetName, $ItemLabel)

    if (-not (Test-Path $TargetDir)) { return }

    Get-ChildItem -Path $TargetDir -Directory | ForEach-Object {
        $Name = $_.Name
        if ($ItemLabel -eq "skill" -and (Test-Path (Join-Path $_.FullName $SkillMarketSourceMarkFile))) {
            return
        }
        if (-not (Test-ManifestContains -Manifest $Manifest -Name $Name)) {
            Remove-Item -Path $_.FullName -Recurse -Force
            Write-Info "[$TargetName] 清理已下线 ${ItemLabel}: $Name"
        }
    }
}

function Select-Target {
    $TargetFromEnv = Resolve-UpdateTargetFromEnv
    if ($TargetFromEnv) {
        return $TargetFromEnv
    }

    Write-Host ""
    Write-Host "请选择更新目标:" -ForegroundColor Cyan
    Write-Host "  1) Claude Code"
    Write-Host "  2) OpenAI Codex CLI"
    Write-Host "  3) 两者都更新"
    Write-Host ""

    $choice = Read-Host "请输入选项 [1-3] (默认: 3)"

    switch ($choice) {
        "1" { return "claude" }
        "2" { return "codex" }
        "3" { return "both" }
        "" { return "both" }
        default { return "both" }
    }
}

function Update-SkillsInDir {
    param($TargetDir, $TargetName, $SourceDir)

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    foreach ($SkillName in $Script:SkillsManifest) {
        $SkillSource = Join-Path $SourceDir $SkillName
        if (-not (Test-Path $SkillSource)) {
            Write-Warn "[$TargetName] manifest 中的 skill 不存在，跳过: $SkillName"
            continue
        }

        $SkillTarget = Join-Path $TargetDir $SkillName
        if (Test-Path $SkillTarget) {
            Remove-Item -Path $SkillTarget -Recurse -Force
            Write-Info "[$TargetName] 更新: $SkillName"
        } else {
            Write-Info "[$TargetName] 新增: $SkillName"
        }
        Copy-Item -Path $SkillSource -Destination $TargetDir -Recurse
    }

    if ($PruneMode -eq "on") {
        Prune-RemovedDirs -TargetDir $TargetDir -Manifest $Script:SkillsManifest -TargetName $TargetName -ItemLabel "skill"
    }
}

function Update-WorkflowsInDir {
    param($TargetDir, $TargetName, $SourceDir)

    if (-not (Test-Path $SourceDir)) {
        Write-Warn "workflows 目录不存在，跳过"
        return
    }

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

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
            Remove-Item -Path $WorkflowTarget -Recurse -Force
            Write-Info "[$TargetName] 更新 workflow: $WorkflowName"
        } else {
            Write-Info "[$TargetName] 新增 workflow: $WorkflowName"
        }
        Copy-Item -Path $WorkflowSource -Destination $TargetDir -Recurse
    }

    if ($PruneMode -eq "on") {
        Prune-RemovedDirs -TargetDir $TargetDir -Manifest $Script:WorkflowsManifest -TargetName $TargetName -ItemLabel "workflow"
    }
}

function Update-MarketSkillsFromRepoToDir {
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
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    foreach ($SkillName in (Get-RepoSkillEntries -RepoDir $RepoDir)) {
        $SkillSource = Join-Path $SourceDir $SkillName
        if (-not (Test-Path $SkillSource)) { continue }

        $SkillTarget = Join-Path $TargetDir $SkillName
        $ShouldApply = $false
        $ShouldMerge = $false
        $ActionLabel = "新增"

        if (Test-Path $SkillTarget) {
            $ExistingSlug = Get-SkillSourceSlug -SkillDir $SkillTarget
            if ($ExistingSlug -eq $RepoSlug) {
                $ShouldApply = $true
                $ActionLabel = "更新"
            } else {
                switch ($SkillMarketConflictMode) {
                    "replace" {
                        $ShouldApply = $true
                        $ActionLabel = "覆盖"
                    }
                    "merge" {
                        $ShouldMerge = $true
                        $ActionLabel = "融合"
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

        if ($ShouldMerge) {
            Merge-MarketSkillInPlace -SkillTarget $SkillTarget -IncomingSkill $SkillSource -RepoSlug $RepoSlug -RepoUrlValue $RepoUrlValue -RepoRef $RepoRef -TargetName $TargetName -SkillName $SkillName | Out-Null
        } else {
            if (Test-Path $SkillTarget) {
                Remove-Item -Path $SkillTarget -Recurse -Force
            }
            Copy-Item -Path $SkillSource -Destination $TargetDir -Recurse
            Write-SkillSourceMetadata -SkillDir $SkillTarget -RepoSlug $RepoSlug -RepoUrlValue $RepoUrlValue -RepoRef $RepoRef
            Write-Info "[$TargetName][market:$RepoSlug] ${ActionLabel}: ${SkillName}"
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

        if ($Target -eq "claude" -or $Target -eq "both") {
            Update-MarketSkillsFromRepoToDir -RepoDir $RepoDir -RepoSlug $Candidate.Slug -RepoUrlValue $Candidate.CloneUrl -RepoRef $Candidate.Ref -TargetDir $ClaudeSkillsDir -TargetName "Claude Code"
        }
        if ($Target -eq "codex" -or $Target -eq "both") {
            Update-MarketSkillsFromRepoToDir -RepoDir $RepoDir -RepoSlug $Candidate.Slug -RepoUrlValue $Candidate.CloneUrl -RepoRef $Candidate.Ref -TargetDir $CodexSkillsDir -TargetName "Codex CLI"
        }
    }
}

function Main {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     AI Coding Skills 更新程序             ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $Succeeded = $false

    try {
        # 检查 Git
        try {
            git --version | Out-Null
        } catch {
            throw "Git 未安装"
        }

        $Target = Select-Target
        Validate-MarketConfig

        if ($PruneMode -ne "on" -and $PruneMode -ne "off") {
            Write-Warn "PRUNE_MODE 仅支持 on/off，当前为 '$PruneMode'，已自动降级为 off"
            $script:PruneMode = "off"
        }

        Write-Info "获取最新 skills..."
        Write-DebugInfo "clone source: $RepoUrl"
        Write-DebugInfo "clone ref: $SkillsRef"
        Write-DebugInfo "clone target: $TempDir"
        try {
            git clone --depth 1 --branch $SkillsRef $RepoUrl $TempDir
        } catch {
            throw "克隆仓库失败"
        }

        $SourceDir = Join-Path $TempDir "skills"
        $WorkflowsSourceDir = Join-Path $TempDir "workflows"
        $Script:PrimaryRepoSlug = Resolve-RepoSlug -RepoUrlValue $RepoUrl
        Set-Manifests

        if ($Target -eq "claude" -or $Target -eq "both") {
            Update-SkillsInDir -TargetDir $ClaudeSkillsDir -TargetName "Claude Code" -SourceDir $SourceDir
            Update-WorkflowsInDir -TargetDir $ClaudeWorkflowsDir -TargetName "Claude Code" -SourceDir $WorkflowsSourceDir
        }

        if ($Target -eq "codex" -or $Target -eq "both") {
            Update-SkillsInDir -TargetDir $CodexSkillsDir -TargetName "Codex CLI" -SourceDir $SourceDir
            Update-WorkflowsInDir -TargetDir $CodexWorkflowsDir -TargetName "Codex CLI" -SourceDir $WorkflowsSourceDir
        }

        Sync-MarketSkills -Target $Target

        $Succeeded = $true
    } finally {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($Succeeded) {
        Write-Host ""
        Write-Info "更新完成! 请重启对应的 AI 编程工具"
    }
}

try {
    Main
} catch {
    Write-Err $_.Exception.Message
    exit 1
}
