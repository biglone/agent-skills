# AI Skills 卸载脚本 (Windows PowerShell)
# 支持 Claude Code、OpenAI Codex CLI 和 Gemini CLI

$ErrorActionPreference = "Stop"

$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$CodexSkillsDir = Join-Path $env:USERPROFILE ".codex\skills"
$GeminiDefaultSkillsDir = Join-Path $env:USERPROFILE ".gemini\skills"
$GeminiAliasSkillsDir = Join-Path $env:USERPROFILE ".agents\skills"
$GeminiSkillsDir = if ($env:GEMINI_SKILLS_DIR) { $env:GEMINI_SKILLS_DIR } elseif (Test-Path $GeminiAliasSkillsDir) { $GeminiAliasSkillsDir } else { $GeminiDefaultSkillsDir }
$ClaudeWorkflowsDir = Join-Path $env:USERPROFILE ".claude\workflows"
$CodexWorkflowsDir = Join-Path $env:USERPROFILE ".codex\workflows"
$SkillsRef = if ($env:SKILLS_REF) { $env:SKILLS_REF } else { "main" }
$ManifestBaseUrl = if ($env:MANIFEST_BASE_URL) { $env:MANIFEST_BASE_URL } else { "https://raw.githubusercontent.com/biglone/agent-skills/$SkillsRef/scripts/manifest" }
$ScriptDir = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { "" }

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Get-ManifestEntries {
    param($FileName)

    $LocalPath = if ($ScriptDir) { Join-Path $ScriptDir ("manifest\" + $FileName) } else { "" }
    $Lines = $null

    if ($LocalPath -and (Test-Path $LocalPath)) {
        $Lines = Get-Content $LocalPath
    } else {
        $Url = "$ManifestBaseUrl/$FileName"
        try {
            $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing
            $Lines = $Response.Content -split "`r?`n"
        } catch {
            throw "无法读取 manifest: $FileName"
        }
    }

    $Entries = @()
    foreach ($Line in $Lines) {
        $Item = $Line.Trim()
        if (-not $Item) { continue }
        if ($Item.StartsWith("#")) { continue }
        $Entries += $Item
    }
    return $Entries
}

function Resolve-UninstallTargetValue {
    param([string]$Value)

    $Target = $Value.Trim().ToLowerInvariant()
    switch ($Target) {
        "claude" { return "claude" }
        "codex" { return "codex" }
        "gemini" { return "gemini" }
        "both" { return "both" }
        "all" { return "all" }
        default { throw "UNINSTALL_TARGET 无效: '$Value'。可选值: claude / codex / gemini / both / all" }
    }
}

function Resolve-UninstallTargetFromEnv {
    if ([string]::IsNullOrWhiteSpace($env:UNINSTALL_TARGET)) {
        return $null
    }

    return Resolve-UninstallTargetValue -Value $env:UNINSTALL_TARGET
}

function Test-UninstallTargetIncludes {
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

function Select-Target {
    $TargetFromEnv = Resolve-UninstallTargetFromEnv
    if ($TargetFromEnv) {
        return $TargetFromEnv
    }

    Write-Host ""
    Write-Host "请选择卸载目标:" -ForegroundColor Cyan
    Write-Host "  1) Claude Code"
    Write-Host "  2) OpenAI Codex CLI"
    Write-Host "  3) Gemini CLI"
    Write-Host "  4) Claude Code + Codex CLI"
    Write-Host "  5) 全部卸载"
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

function Uninstall-FromDir {
    param($TargetDir, $TargetName, $SkillsToRemove)

    foreach ($Skill in $SkillsToRemove) {
        $SkillPath = Join-Path $TargetDir $Skill

        if (Test-Path $SkillPath) {
            Remove-Item -Path $SkillPath -Recurse -Force
            Write-Info "[$TargetName] 已卸载: $Skill"
        } else {
            Write-Warn "[$TargetName] Skill '$Skill' 不存在，跳过"
        }
    }
}

function Uninstall-WorkflowsFromDir {
    param($TargetDir, $TargetName, $WorkflowsToRemove)

    foreach ($Workflow in $WorkflowsToRemove) {
        $WorkflowPath = Join-Path $TargetDir $Workflow

        if (Test-Path $WorkflowPath) {
            Remove-Item -Path $WorkflowPath -Recurse -Force
            Write-Info "[$TargetName] 已卸载 workflow: $Workflow"
        } else {
            Write-Warn "[$TargetName] Workflow '$Workflow' 不存在，跳过"
        }
    }
}

function Main {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       AI Skills 卸载程序                  ║" -ForegroundColor Cyan
    Write-Host "║ 支持 Claude Code / Codex / Gemini CLI     ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $Target = Select-Target
    $SkillsToRemove = Get-ManifestEntries -FileName "skills.txt"
    $WorkflowsToRemove = Get-ManifestEntries -FileName "workflows.txt"

    if ($SkillsToRemove.Count -eq 0) {
        throw "skills manifest 为空"
    }

    if (Test-UninstallTargetIncludes -SelectedTarget $Target -Platform "claude") {
        Uninstall-FromDir -TargetDir $ClaudeSkillsDir -TargetName "Claude Code" -SkillsToRemove $SkillsToRemove
        Uninstall-WorkflowsFromDir -TargetDir $ClaudeWorkflowsDir -TargetName "Claude Code" -WorkflowsToRemove $WorkflowsToRemove
    }

    if (Test-UninstallTargetIncludes -SelectedTarget $Target -Platform "codex") {
        Uninstall-FromDir -TargetDir $CodexSkillsDir -TargetName "Codex CLI" -SkillsToRemove $SkillsToRemove
        Uninstall-WorkflowsFromDir -TargetDir $CodexWorkflowsDir -TargetName "Codex CLI" -WorkflowsToRemove $WorkflowsToRemove
    }

    if (Test-UninstallTargetIncludes -SelectedTarget $Target -Platform "gemini") {
        Uninstall-FromDir -TargetDir $GeminiSkillsDir -TargetName "Gemini CLI" -SkillsToRemove $SkillsToRemove
    }

    Write-Host ""
    Write-Info "卸载完成! 请重启对应的 AI 编程工具"
}

try {
    Main
} catch {
    Write-Err $_.Exception.Message
    exit 1
}
