# 安装/更新参考

README 只保留高频命令。本文档收录固定版本、单平台安装、非交互、`cmd` 兼容、外部 skill 市场同步和完整环境变量说明。

## 基础约定

- 默认仓库：`https://github.com/biglone/agent-skills.git`
- 默认版本引用：`SKILLS_REF=main`
- 安装与更新都按 `scripts/manifest/skills.txt` / `scripts/manifest/workflows.txt` 同步，不会扫描内部目录
- Windows 默认推荐 `PowerShell`；`cmd` 兼容命令见文末

## 安装

### 默认安装

**macOS / Linux**

```bash
curl -fsSL -o /tmp/agent-skills-install.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.sh
bash /tmp/agent-skills-install.sh
```

**Windows (PowerShell)**

```powershell
$script = Join-Path $env:TEMP "agent-skills-install.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.ps1" -OutFile $script
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### 只安装到指定平台

**macOS / Linux**

```bash
curl -fsSL -o /tmp/agent-skills-install.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.sh
INSTALL_TARGET=codex UPDATE_MODE=force NON_INTERACTIVE=1 bash /tmp/agent-skills-install.sh --non-interactive
```

可选值：`claude`、`codex`、`gemini`、`both`、`all`

**Windows (PowerShell)**

```powershell
$script = Join-Path $env:TEMP "agent-skills-install.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.ps1" -OutFile $script
$env:INSTALL_TARGET="codex"
$env:UPDATE_MODE="force"
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### 非交互与 Dry Run

**macOS / Linux**

```bash
curl -fsSL -o /tmp/agent-skills-install.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.sh
NON_INTERACTIVE=1 bash /tmp/agent-skills-install.sh --non-interactive
NON_INTERACTIVE=1 DRY_RUN=1 bash /tmp/agent-skills-install.sh --non-interactive --dry-run
```

**Windows (PowerShell，本地脚本)**

```powershell
.\scripts\install.ps1 --non-interactive
.\scripts\install.ps1 --non-interactive --dry-run
```

### 固定到发布版本

先查看 Releases 或 `git tag`，再把 `<release-tag>` 换成真实存在的 tag。

**macOS / Linux**

```bash
curl -fsSL -o /tmp/agent-skills-install-<release-tag>.sh https://raw.githubusercontent.com/biglone/agent-skills/<release-tag>/scripts/install.sh
SKILLS_REF=<release-tag> UPDATE_MODE=force INSTALL_TARGET=both bash /tmp/agent-skills-install-<release-tag>.sh
```

**Windows (PowerShell)**

```powershell
$script = Join-Path $env:TEMP "agent-skills-install-<release-tag>.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/<release-tag>/scripts/install.ps1" -OutFile $script
$env:SKILLS_REF="<release-tag>"
$env:UPDATE_MODE="force"
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### 手动安装

**macOS / Linux**

```bash
git clone https://github.com/biglone/agent-skills.git
cp -r agent-skills/skills/* ~/.claude/skills/
cp -r agent-skills/skills/* ~/.codex/skills/
cp -r agent-skills/skills/* ~/.gemini/skills/
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/biglone/agent-skills.git
Copy-Item -Recurse agent-skills\skills\* $env:USERPROFILE\.claude\skills\
Copy-Item -Recurse agent-skills\skills\* $env:USERPROFILE\.codex\skills\
Copy-Item -Recurse agent-skills\skills\* $env:USERPROFILE\.gemini\skills\
```

## 更新

### 默认更新

**macOS / Linux**

```bash
curl -fsSL -o /tmp/agent-skills-update.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/update.sh
bash /tmp/agent-skills-update.sh
```

**Windows (PowerShell)**

```powershell
$script = Join-Path $env:TEMP "agent-skills-update.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/update.ps1" -OutFile $script
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### 只更新指定平台

**macOS / Linux**

```bash
curl -fsSL -o /tmp/agent-skills-update.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/update.sh
UPDATE_TARGET=gemini bash /tmp/agent-skills-update.sh
```

**Windows (PowerShell)**

```powershell
$script = Join-Path $env:TEMP "agent-skills-update.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/update.ps1" -OutFile $script
$env:UPDATE_TARGET="gemini"
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### 清理已下线的 skill / workflow

```bash
curl -fsSL -o /tmp/agent-skills-update.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/update.sh
PRUNE_MODE=on UPDATE_TARGET=both bash /tmp/agent-skills-update.sh
```

### 固定到发布版本

```bash
curl -fsSL -o /tmp/agent-skills-update-<release-tag>.sh https://raw.githubusercontent.com/biglone/agent-skills/<release-tag>/scripts/update.sh
SKILLS_REF=<release-tag> UPDATE_TARGET=both bash /tmp/agent-skills-update-<release-tag>.sh
```

## 卸载

### 默认卸载

**macOS / Linux**

```bash
curl -fsSL -o /tmp/agent-skills-uninstall.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/uninstall.sh
bash /tmp/agent-skills-uninstall.sh
```

**Windows (PowerShell)**

```powershell
$script = Join-Path $env:TEMP "agent-skills-uninstall.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/uninstall.ps1" -OutFile $script
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### 只卸载指定平台

**Windows (PowerShell)**

```powershell
$script = Join-Path $env:TEMP "agent-skills-uninstall.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/uninstall.ps1" -OutFile $script
$env:UNINSTALL_TARGET="gemini"
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

## 外部 Skill Market

默认关闭。只有在你明确需要同步外部仓库时再打开。

### 开启发现并同步

**macOS / Linux**

```bash
curl -fsSL -o /tmp/agent-skills-install.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.sh
SKILL_MARKET_DISCOVERY=github SKILL_MARKET_MAX_REPOS=3 INSTALL_TARGET=both UPDATE_MODE=force \
  bash /tmp/agent-skills-install.sh
```

**Windows (PowerShell)**

```powershell
$script = Join-Path $env:TEMP "agent-skills-install.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.ps1" -OutFile $script
$env:SKILL_MARKET_DISCOVERY="all"
$env:SKILL_MARKET_CONFLICT_MODE="merge"
$env:SKILL_MARKET_EXTRA_REPOS="your-org/skills-repo@<ref>"
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### 常用冲突策略

- `skip`：跳过本地已有同名 skill
- `replace`：直接覆盖同名 skill
- `merge`：生成 `SKILL.merged.md`、`SKILL.merge-report.md` 和外部来源快照

### merge 直接应用到本地

```bash
curl -fsSL -o /tmp/agent-skills-install.sh https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.sh
SKILL_MARKET_DISCOVERY=all \
SKILL_MARKET_ALLOWLIST="your-org/skills-repo,another-org/skills-repo" \
SKILL_MARKET_CONFLICT_MODE=merge \
SKILL_MARKET_MERGE_APPLY_MODE=apply \
INSTALL_TARGET=both UPDATE_MODE=force \
bash /tmp/agent-skills-install.sh
```

## Codex 启动前自动更新

当安装目标包含 Codex（`INSTALL_TARGET=codex`、`both` 或 `all`）时，安装脚本默认会：

1. 写入本地版本文件 `~/.codex/.skills_version`
2. 生成启动器
3. 注入 shell/profile，在执行 `codex` 前检查远端版本并自动更新

相关变量：

- `CODEX_AUTO_UPDATE_SETUP=on|off`
- `CODEX_AUTO_UPDATE_REPO=owner/repo`
- `CODEX_AUTO_UPDATE_BRANCH=<branch-or-tag>`
- 运行时可临时禁用：`CODEX_SKILLS_AUTO_UPDATE=0 codex`

## 环境变量参考

### 通用变量

| 变量 | 适用脚本 | 值 | 说明 |
|------|----------|-----|------|
| `SKILLS_REPO` | install/update | Git URL | 自定义仓库地址 |
| `SKILLS_REF` | install/update | 分支/Tag/提交 | 来源版本，默认 `main` |
| `GEMINI_SKILLS_DIR` | install/update/uninstall | 本地目录路径 | 覆盖 Gemini Skills 目录 |
| `DEBUG` | install/update | `1` / `true` | 输出额外调试日志 |

### install

| 变量 | 值 | 说明 |
|------|-----|------|
| `INSTALL_TARGET` | `claude` / `codex` / `gemini` / `both` / `all` | 安装目标平台 |
| `UPDATE_MODE` | `ask` / `skip` / `force` | 遇到本地已存在 skill 的处理策略 |
| `NON_INTERACTIVE` | `1` / `true` | 非交互模式 |
| `DRY_RUN` | `1` / `true` | 仅打印计划，不写入目标目录 |
| `CODEX_AUTO_UPDATE_SETUP` | `on` / `off` | 是否自动配置 Codex 启动前更新 |
| `CODEX_AUTO_UPDATE_REPO` | `owner/repo` | Codex 自动更新检查仓库 |
| `CODEX_AUTO_UPDATE_BRANCH` | 分支/Tag | Codex 自动更新检查版本引用 |

### update

| 变量 | 值 | 说明 |
|------|-----|------|
| `UPDATE_TARGET` | `claude` / `codex` / `gemini` / `both` / `all` | 更新目标平台 |
| `PRUNE_MODE` | `on` / `off` | 是否清理远端已下线的 skill/workflow |

### uninstall

| 变量 | 值 | 说明 |
|------|-----|------|
| `UNINSTALL_TARGET` | `claude` / `codex` / `gemini` / `both` / `all` | 卸载目标平台 |

### Skill Market

| 变量 | 值 | 说明 |
|------|-----|------|
| `SKILL_MARKET_DISCOVERY` | `off` / `manifest` / `github` / `all` | 是否启用外部 skill 市场发现 |
| `SKILL_MARKET_EXTRA_REPOS` | `owner/repo,owner/repo@branch` | 额外补充仓库 |
| `SKILL_MARKET_ALLOWLIST` | `owner/repo,owner/repo` | 仅允许同步白名单仓库 |
| `SKILL_MARKET_CONFLICT_MODE` | `skip` / `replace` / `merge` | 同名 skill 冲突策略 |
| `SKILL_MARKET_MERGE_APPLY_MODE` | `preview` / `apply` | `merge` 结果是否直接写回本地 |
| `SKILL_MARKET_MERGE_BACKUP_FILE_NAME` | 文件名 | merge apply 时的本地备份文件名 |
| `SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT` | 正整数 | 每个 skill 保留的外部快照数量 |
| `SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS` | 非负整数 | 外部快照按天清理阈值 |
| `SKILL_MARKET_MAX_REPOS` | 正整数 | 最多同步的外部仓库数量 |
| `SKILL_MARKET_MIN_STARS` | 非负整数 | GitHub 发现模式下的最小 star 门槛 |
| `SKILL_MARKET_QUERIES` | `;` 分隔查询 | GitHub 搜索查询 |
| `SKILL_MARKET_PER_QUERY` | 正整数 | 每个 GitHub 查询拉取的候选数量 |
| `GITHUB_TOKEN` | GitHub Token | 提升 GitHub API 速率限制 |

## Windows `cmd` 兼容命令

`cmd` 里不能直接使用 `irm`，请改用 `powershell -Command` 包一层。

### 安装

```cmd
set "SKILLS_REF=main" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-install.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/install.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"
```

### 更新

```cmd
set "SKILLS_REF=main" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-update.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/update.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"
```

### 卸载

```cmd
set "SKILLS_REF=main" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-uninstall.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/uninstall.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"
```
