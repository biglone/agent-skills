# AI Skills 卸载脚本 (Windows PowerShell)
# 支持 Claude Code 和 OpenAI Codex CLI

$ErrorActionPreference = "Stop"

$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$CodexSkillsDir = Join-Path $env:USERPROFILE ".codex\skills"
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

function Select-Target {
    if ($env:UNINSTALL_TARGET) {
        return $env:UNINSTALL_TARGET
    }

    Write-Host ""
    Write-Host "请选择卸载目标:" -ForegroundColor Cyan
    Write-Host "  1) Claude Code"
    Write-Host "  2) OpenAI Codex CLI"
    Write-Host "  3) 两者都卸载"
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
    Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $Target = Select-Target
    $SkillsToRemove = Get-ManifestEntries -FileName "skills.txt"
    $WorkflowsToRemove = Get-ManifestEntries -FileName "workflows.txt"

    if ($SkillsToRemove.Count -eq 0) {
        throw "skills manifest 为空"
    }

    if ($Target -eq "claude" -or $Target -eq "both") {
        Uninstall-FromDir -TargetDir $ClaudeSkillsDir -TargetName "Claude Code" -SkillsToRemove $SkillsToRemove
        Uninstall-WorkflowsFromDir -TargetDir $ClaudeWorkflowsDir -TargetName "Claude Code" -WorkflowsToRemove $WorkflowsToRemove
    }

    if ($Target -eq "codex" -or $Target -eq "both") {
        Uninstall-FromDir -TargetDir $CodexSkillsDir -TargetName "Codex CLI" -SkillsToRemove $SkillsToRemove
        Uninstall-WorkflowsFromDir -TargetDir $CodexWorkflowsDir -TargetName "Codex CLI" -WorkflowsToRemove $WorkflowsToRemove
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
