# AI Skills 集合

一个可共享的 AI 助手 Skills 仓库，支持 **Claude Code** 和 **OpenAI Codex CLI**，方便团队成员和多设备快速安装使用。

> 📝 仓库已从 `claude-skills` 更名为 `agent-skills`。旧地址会被 GitHub 重定向，建议尽快切换到新地址以避免后续失效。

## 支持的平台

| 平台 | Skills 目录 |
|------|-------------|
| Claude Code | `~/.claude/skills/` |
| OpenAI Codex CLI | `~/.codex/skills/` |

## 包含的 Skills

### 编程开发类

| Skill | 描述 |
|-------|------|
| `code-reviewer` | 代码审查，检查代码质量和最佳实践 |
| `commit-message` | 生成规范的 Git 提交信息 |
| `security-audit` | 安全代码审计，检查常见漏洞 |
| `code-explainer` | 代码解释器，帮助理解代码 |
| `test-generator` | 生成单元测试代码 |
| `refactoring` | 代码重构建议，识别代码异味 |
| `api-designer` | REST/GraphQL API 设计 |
| `doc-generator` | 自动生成代码文档、README |
| `performance-optimizer` | 性能分析和优化建议 |
| `bug-finder` | 调试助手，帮助定位 Bug |
| `regex-helper` | 正则表达式编写和解释 |
| `sql-helper` | SQL 查询编写和优化 |
| `git-helper` | Git 操作指导 |
| `changelog-generator` | 生成 Changelog |
| `pr-description` | 生成 PR 描述 |
| `dependency-analyzer` | 依赖分析和安全检查 |
| `i18n-helper` | 国际化辅助 |
| `migration-helper` | 数据库迁移和框架升级 |
| `requirements-doc` | 需求文档生成器，将简单需求转换为结构化文档和任务列表 |
| `claude-api` | 构建基于 Claude API / Anthropic SDK 的应用与集成 |
| `cloudflared-tunnel` | 在 Linux 上通过 cloudflared tunnel 将本地服务地址绑定域名并快速公网访问 |
| `cloudflared-tunnel-inspector` | 在 Linux 上列出 tunnel 公开服务及其配置映射信息 |
| `mcp-builder` | MCP 服务开发指南，帮助构建高质量 Model Context Protocol 服务 |
| `skill-creator` | 创建、优化并评估 skills，支持基准测试与触发描述改进 |
| `webapp-testing` | 使用 Playwright 测试本地 Web 应用、抓日志与截图 |

### 写作与翻译类

| Skill | 描述 |
|-------|------|
| `technical-writer` | 技术文档写作 |
| `blog-writer` | 博客文章写作 |
| `translator` | 多语言翻译 |
| `email-writer` | 邮件撰写和优化 |
| `internal-comms` | 内部沟通写作助手，适用于状态更新、FAQ、领导汇报等 |
| `presentation-maker` | 演示文稿结构和内容设计 |

### 设计与视觉类

| Skill | 描述 |
|-------|------|
| `algorithmic-art` | 使用 p5.js 和算法美学生成原创生成艺术 |
| `brand-guidelines` | 为产物套用品牌色、字体与视觉规范 |
| `canvas-design` | 创建海报、静态视觉稿、PNG/PDF 设计作品 |
| `frontend-design` | 生成高设计质量的前端页面、组件与 UI |
| `slack-gif-creator` | 生成适合 Slack 使用的动图 GIF |
| `theme-factory` | 为文档、幻灯片、网页等产物生成并应用主题 |
| `web-artifacts-builder` | 构建复杂的单文件 Web artifact，支持 React/Tailwind/shadcn/ui |

### 数据与分析类

| Skill | 描述 |
|-------|------|
| `data-analyzer` | 数据分析和解读 |
| `chart-generator` | 图表生成和可视化 |

### 学习与知识管理类

| Skill | 描述 |
|-------|------|
| `concept-explainer` | 概念解释（通俗易懂） |
| `tutorial-creator` | 教程和学习指南创建 |
| `note-taker` | 笔记整理和知识提取 |
| `knowledge-base` | 个人知识库管理 |
| `learning-diagnostics` | 学习诊断和差距评估 |
| `learning-study-coach` | 支持零基础/夯实基础/冲刺复习三档讲解，基于学习计划或教程材料一步一步陪学 |
| `learning-tracker` | 学习进度追踪和计划管理 |
| `quiz-generator` | 学习测验生成和掌握度校验 |
| `review-scheduler` | 复习节奏与周度重规划管理 |

### 个人效率类

| Skill | 描述 |
|-------|------|
| `task-planner` | 任务规划和项目分解 |
| `meeting-notes` | 会议记录和纪要整理 |
| `weekly-review` | 周报生成和周期性回顾 |
| `goal-setter` | 目标设定和拆解（SMART/OKR） |
| `habit-tracker` | 习惯追踪和养成 |
| `decision-maker` | 决策辅助和分析 |

### 职业发展类

| Skill | 描述 |
|-------|------|
| `resume-builder` | 简历撰写和优化 |
| `interview-helper` | 面试准备和模拟 |
| `interviewer` | 面试官面试设计与评估 |
| `career-planner` | 职业规划和发展 |
| `feedback-giver` | 反馈给予和接收 |

### 创意思考类

| Skill | 描述 |
|-------|------|
| `brainstormer` | 头脑风暴和创意发散 |
| `outline-creator` | 大纲创建和结构化 |
| `mind-mapper` | 思维导图和可视化思维 |

### 自动化类

| Skill | 描述 |
|-------|------|
| `autonomous-dev` | 自主开发模式，自动完成从需求到提交的完整流程 |
| `auto-code-pipeline` | 自动代码流水线，lint → test → review 自动执行 |
| `auto-fix-loop` | 自动修复循环，持续修复直到测试/构建通过 |

### 市场审计类

| Skill | 描述 |
|-------|------|
| `skill-market-auditor` | 发现外部 skill 仓库、做供应链/安全审计、输出 add / merge-preview / reject 建议 |

> 已从 `anthropics/skills` 审计引入 12 个 Apache 许可 skills；`docx`、`pdf`、`pptx`、`xlsx` 以及 `doc-coauthoring` 因上游许可限制或许可不明，当前未直接纳入。详见 `THIRD_PARTY_NOTICES.md`。

## Workflows 工作流

工作流将多个相关的 Skills 串联起来，形成完整的工作流程。

| Workflow | 描述 | 包含的 Skills |
|----------|------|--------------|
| `full-auto-development` | **全自动开发工作流** | requirements-doc, task-planner, autonomous-dev, auto-code-pipeline, code-reviewer |
| `code-review-flow` | 代码审查工作流 | code-reviewer, security-audit, bug-finder, refactoring, commit-message, pr-description |
| `feature-development` | 功能开发工作流 | api-designer, doc-generator, test-generator, code-reviewer, changelog-generator, pr-description |
| `content-creation` | 内容创作工作流 | brainstormer, outline-creator, blog-writer, technical-writer, translator |
| `weekly-planning` | 每周规划工作流 | weekly-review, goal-setter, task-planner, habit-tracker, decision-maker |
| `learning-path` | 学习路径闭环工作流 | learning-diagnostics, goal-setter, learning-tracker, concept-explainer, quiz-generator, note-taker, knowledge-base, review-scheduler, tutorial-creator |
| `project-kickoff` | 项目启动工作流 | task-planner, goal-setter, brainstormer, decision-maker, meeting-notes, presentation-maker |

## 📚 完整文档

### 快速开始

- 📖 [**快速开始指南**](./GETTING_STARTED.md) - 5分钟上手全自动开发
- 🎯 [提示词优化指南](./PROMPT_OPTIMIZATION.md) - 写出更好的需求描述
- 📋 [项目模板](./TEMPLATES.md) - 不同项目类型的配置模板
- 🧩 [新增技能模板命令](./TEMPLATES_NEW_SKILLS.md) - 新引入 skills 的高触发率示例命令
- 🎨 [**技能选择机制**](./SKILL_SELECTION.md) - 如何让 Claude 选择正确的 skill
- 📂 [**工作目录说明**](./WORKING_DIRECTORY.md) - 工作目录和安全范围设置

### 配置和定制

- ⚙️  [**配置指南**](./CONFIG.md) - 自定义工作流行为
- 🔐 安全配置 - 敏感文件保护和危险操作检测（见 autonomous-dev skill 文档）
- 🔧 [Git 工作流集成](./GIT_WORKFLOW.md) - 与 Git 最佳实践结合

### 优化和故障排除

- 🚀 [性能优化指南](./PERFORMANCE.md) - 提升执行速度
- 🔍 [**故障排除指南**](./TROUBLESHOOTING.md) - 解决常见问题
- 📊 性能监控 - 查看执行指标和统计（见配置文档）
- 🚢 [发布检查清单](./RELEASE_CHECKLIST.md) - 发布前版本号、CI 与文档核对

### 核心特性文档

- 📝 **需求文档生成** - 详见 [requirements-doc skill](./skills/requirements-doc/SKILL.md)
- 🤖 **自主开发** - 详见 [autonomous-dev skill](./skills/autonomous-dev/SKILL.md)
- 🔄 **进度记录与恢复** - 断点续传、检查点机制（见 autonomous-dev 文档）
- 🔒 **安全检查机制** - 文件保护、代码扫描（见 autonomous-dev 文档）

## 快速安装

运行安装脚本后，会提示选择安装目标（Claude Code / Codex CLI / 两者都安装）。
安装与更新均按 `scripts/manifest/skills.txt` / `scripts/manifest/workflows.txt` 执行，不会扫描并安装内部目录。

### macOS / Linux

```bash
SKILLS_REF="${SKILLS_REF:-v1.2.0}"
curl -fsSL -o /tmp/agent-skills-install.sh "https://raw.githubusercontent.com/biglone/agent-skills/${SKILLS_REF}/scripts/install.sh"
bash /tmp/agent-skills-install.sh
```

### Windows (PowerShell)

```powershell
$ref = if ($env:SKILLS_REF) { $env:SKILLS_REF } else { "v1.2.0" }
$script = Join-Path $env:TEMP "agent-skills-install.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/$ref/scripts/install.ps1" -OutFile $script
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### Windows (cmd)

```cmd
set "SKILLS_REF=v1.2.0" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-install.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/install.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"
```

说明：`irm` 是 PowerShell 的 `Invoke-RestMethod` 别名，在 `cmd` 中不可直接使用。
说明：示例默认使用已发布版本 `v1.2.0`；如果要跟随最新分支，请显式设置 `SKILLS_REF=main`。

### 环境变量配置

通过环境变量控制安装/更新/卸载行为：

| 变量 | 适用脚本 | 值 | 说明 |
|------|----------|-----|------|
| `SKILLS_REPO` | install/update | Git URL | 自定义仓库地址（默认官方仓库） |
| `SKILLS_REF` | install/update | 分支/Tag/提交 | 安装或更新来源版本（默认 `main`，支持发布 Tag） |
| `INSTALL_TARGET` | install | `claude` / `codex` / `both` | 安装目标平台 |
| `UPDATE_MODE` | install | `ask` / `skip` / `force` | 处理本地已存在 skill 的策略 |
| `NON_INTERACTIVE` | install | `1` / `true` | 非交互模式（默认目标 `both`） |
| `DRY_RUN` | install | `1` / `true` | 仅打印计划，不写入目标目录 |
| `CODEX_AUTO_UPDATE_SETUP` | install | `on` / `off` | 是否自动配置 Codex 启动前检查并更新 skills |
| `CODEX_AUTO_UPDATE_REPO` | install | `owner/repo` | Codex 自动更新检查使用的 GitHub 仓库（默认按 `SKILLS_REPO` 推断） |
| `CODEX_AUTO_UPDATE_BRANCH` | install | 分支/Tag | Codex 自动更新检查使用的版本引用（默认跟随 `SKILLS_REF`） |
| `UPDATE_TARGET` | update | `claude` / `codex` / `both` | 更新目标平台 |
| `PRUNE_MODE` | update | `on` / `off` | 是否清理本地已下线的 skill/workflow |
| `SKILL_MARKET_DISCOVERY` | install/update | `off` / `manifest` / `github` / `all` | 是否启用外部 skill 市场发现与同步（默认 `off`） |
| `SKILL_MARKET_EXTRA_REPOS` | install/update | `owner/repo,owner/repo@branch` | 额外补充的仓库列表（逗号分隔） |
| `SKILL_MARKET_ALLOWLIST` | install/update | `owner/repo,owner/repo` | 仅允许同步白名单仓库（空表示不过滤） |
| `SKILL_MARKET_CONFLICT_MODE` | install/update | `skip` / `replace` / `merge` | 遇到同名 skill 的冲突策略（默认 `skip`） |
| `SKILL_MARKET_MERGE_APPLY_MODE` | install/update | `preview` / `apply` | `merge` 冲突策略下，是否将融合结果回写到本地 `SKILL.md`（默认 `preview`） |
| `SKILL_MARKET_MERGE_BACKUP_FILE_NAME` | install/update | 文件名 | `merge + apply` 时，本地 `SKILL.md` 备份文件名（默认 `SKILL.pre-merge.backup.md`） |
| `SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT` | install/update | 正整数 | 每个 skill 保留的外部 source 快照数量（默认 `5`） |
| `SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS` | install/update | 非负整数 | 外部 source 快照按天清理阈值（默认 `30`，`0` 表示不按天清理） |
| `SKILL_MARKET_MAX_REPOS` | install/update | 正整数 | 最多同步的外部仓库数量（默认 `5`） |
| `SKILL_MARKET_MIN_STARS` | install/update | 非负整数 | GitHub 发现模式下的最小 star 门槛（默认 `10`） |
| `SKILL_MARKET_QUERIES` | install/update | `;` 分隔查询 | GitHub 搜索查询（默认按 skill 相关 topic） |
| `SKILL_MARKET_PER_QUERY` | install/update | 正整数 | 每个 GitHub 查询拉取候选数量（默认 `10`） |
| `GITHUB_TOKEN` | install/update | GitHub Token | 提升 GitHub API 速率限制，减少发现失败 |
| `UNINSTALL_TARGET` | uninstall | `claude` / `codex` / `both` | 卸载目标平台 |
| `DEBUG` | install/update | `1` / `true` | 输出额外调试日志（如 clone 源与目标路径） |

## 每日自动审计骨架

本仓库已内置“只出报告、不自动改本地 skills”的日报骨架，用于每天执行：

- 校验当前仓库 `skills/`
- 本仓库自扫
- GitHub marketplace 发现
- seed 仓库并入候选池：`scripts/manifest/market-seed-repos.txt`
- 白名单外部仓库深度审计
- 自动生成 merge preview 报告
- 可选发送 Matrix 详细报告通知

默认白名单文件：

- `scripts/manifest/skill-market-allowlist.txt`

默认 seed 文件：

- `scripts/manifest/market-seed-repos.txt`

当前默认深度审计目标：

- `anthropics/skills`

手动运行：

```bash
./scripts/run-skill-market-daily-audit.sh
```

带 Matrix 通知运行：

```bash
MATRIX_HOMESERVER_URL=https://matrix.example.com \
MATRIX_ACCESS_TOKEN=... \
MATRIX_ROOM_ID='!roomid:example.com' \
./scripts/run-skill-market-daily-audit.sh --notify-matrix
```

报告输出位置：

- `reports/skill-market/latest.md`
- `reports/skill-market/latest.json`
- `reports/skill-market/runs/YYYY-MM-DD/HHMMSS/`

调度示例：

- `ops/cron/skill-market-daily.cron.example`
- `ops/systemd/skill-market-daily-audit.service.example`
- `ops/systemd/skill-market-daily-audit.timer.example`

**UPDATE_MODE 说明（install 脚本）：**
- `force` (默认): 强制更新所有 skill（同名覆盖，无需逐个确认）
- `ask`: 逐个询问是否更新已存在的 skill
- `skip`: 跳过所有已存在的 skill

**PRUNE_MODE 说明（update 脚本）：**
- `off` (默认): 只更新/新增，不删除本地多余目录
- `on`: 同步清理远端已下线的 skill/workflow

**Skills Market 自动发现说明（install/update 脚本）：**
- `SKILL_MARKET_DISCOVERY=off` (默认): 仅同步主仓库（当前行为不变）
- `SKILL_MARKET_DISCOVERY=manifest`: 读取 `scripts/manifest/market-seed-repos.txt` 里的 seed 仓库
- `SKILL_MARKET_DISCOVERY=github`: 从 GitHub 热门仓库自动发现候选 skill 仓库
- `SKILL_MARKET_DISCOVERY=all`: 同时启用 `manifest + github`
- `SKILL_MARKET_EXTRA_REPOS`: 额外强制加入的仓库（支持 `owner/repo@branch`）
- `SKILL_MARKET_ALLOWLIST`: 仅同步白名单仓库（支持 `owner/repo`、GitHub URL；大小写不敏感）
- `SKILL_MARKET_CONFLICT_MODE=skip` (默认): 跳过本地已有同名 skill
- `SKILL_MARKET_CONFLICT_MODE=replace`: 直接覆盖同名 skill
- `SKILL_MARKET_CONFLICT_MODE=merge`: 不覆盖本地，生成融合产物：
  - `SKILL.merged.md`：融合后的建议版本
  - `SKILL.merge-report.md`：融合报告（新增/跳过章节）
  - `.agent-skills-merge-sources/<repo>/`：外部原始 skill 快照
- `SKILL_MARKET_MERGE_APPLY_MODE=preview` (默认): 仅生成融合建议文件，不修改本地 `SKILL.md`
- `SKILL_MARKET_MERGE_APPLY_MODE=apply`: 将融合结果写回本地 `SKILL.md`，并保留 `SKILL_MARKET_MERGE_BACKUP_FILE_NAME` 备份
- `SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT` / `SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS`: 限制外部快照目录数量与天数，自动清理旧快照
- 市场同步写入来源文件 `.agent-skills-source`，后续可对同源 skill 自动更新
- `PRUNE_MODE=on` 时会保留带 `.agent-skills-source` 的 skill，避免发现失败时误删

**Codex 自动更新说明（install 脚本）：**
- `CODEX_AUTO_UPDATE_SETUP=on` (默认): 
  - macOS/Linux: 写入 `~/.codex/codex-skills-auto-update.sh` 并注入 `~/.bashrc` / `~/.zshrc`
  - Windows PowerShell: 写入 `~/.codex/codex-skills-auto-update.ps1` 并注入 PowerShell profile
- `CODEX_AUTO_UPDATE_SETUP=off`: 不自动配置启动前更新
- 运行时可临时禁用：`CODEX_SKILLS_AUTO_UPDATE=0 codex`

**macOS / Linux:**
```bash
# 强制更新所有 skills 到 Claude Code
SKILLS_REF="${SKILLS_REF:-v1.2.0}"
curl -fsSL -o /tmp/agent-skills-install.sh "https://raw.githubusercontent.com/biglone/agent-skills/${SKILLS_REF}/scripts/install.sh"
UPDATE_MODE=force INSTALL_TARGET=claude bash /tmp/agent-skills-install.sh

# 强制更新到两个平台
UPDATE_MODE=force INSTALL_TARGET=both bash /tmp/agent-skills-install.sh

# 跳过已存在的 skills（静默安装）
UPDATE_MODE=skip INSTALL_TARGET=both bash /tmp/agent-skills-install.sh

# 开启 GitHub 热门仓库自动发现并同步（最多 3 个仓库）
SKILL_MARKET_DISCOVERY=github SKILL_MARKET_MAX_REPOS=3 INSTALL_TARGET=both UPDATE_MODE=force \
  bash /tmp/agent-skills-install.sh

# 仅同步 allowlist 仓库 + merge 后直接应用，并限制快照保留策略
SKILL_MARKET_DISCOVERY=all \
  SKILL_MARKET_ALLOWLIST="your-org/skills-repo,another-org/skills-repo" \
  SKILL_MARKET_CONFLICT_MODE=merge \
  SKILL_MARKET_MERGE_APPLY_MODE=apply \
  SKILL_MARKET_MERGE_BACKUP_FILE_NAME="SKILL.pre-merge.local.md" \
  SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT=8 \
  SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS=45 \
  INSTALL_TARGET=both UPDATE_MODE=force \
  bash /tmp/agent-skills-install.sh
```

**Windows (PowerShell):**
```powershell
# 只安装到 Claude Code
$ref = if ($env:SKILLS_REF) { $env:SKILLS_REF } else { "v1.2.0" }
$script = Join-Path $env:TEMP "agent-skills-install.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/$ref/scripts/install.ps1" -OutFile $script
$env:INSTALL_TARGET="claude"; powershell -NoProfile -ExecutionPolicy Bypass -File $script

# 强制更新所有 skills
$env:UPDATE_MODE="force"; powershell -NoProfile -ExecutionPolicy Bypass -File $script

# 启用市场发现 + 冲突融合（不覆盖本地 SKILL.md）
$env:SKILL_MARKET_DISCOVERY="all"
$env:SKILL_MARKET_CONFLICT_MODE="merge"
$env:SKILL_MARKET_EXTRA_REPOS="your-org/skills-repo@<ref>"
powershell -NoProfile -ExecutionPolicy Bypass -File $script

# allowlist + merge 后直接应用到本地 SKILL.md（保留备份并清理旧快照）
$env:SKILL_MARKET_DISCOVERY="all"
$env:SKILL_MARKET_ALLOWLIST="your-org/skills-repo,another-org/skills-repo"
$env:SKILL_MARKET_CONFLICT_MODE="merge"
$env:SKILL_MARKET_MERGE_APPLY_MODE="apply"
$env:SKILL_MARKET_MERGE_BACKUP_FILE_NAME="SKILL.pre-merge.local.md"
$env:SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT="8"
$env:SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS="45"
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

**Windows (cmd):**
```cmd
:: 只安装到 Claude Code
set "SKILLS_REF=v1.2.0" && set "INSTALL_TARGET=claude" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-install.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/install.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"

:: 强制更新所有 skills
set "SKILLS_REF=v1.2.0" && set "UPDATE_MODE=force" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-install.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/install.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"
```

### 非交互与 Dry Run

**macOS / Linux:**
```bash
# 非交互安装
SKILLS_REF="${SKILLS_REF:-v1.2.0}"
curl -fsSL -o /tmp/agent-skills-install.sh "https://raw.githubusercontent.com/biglone/agent-skills/${SKILLS_REF}/scripts/install.sh"
NON_INTERACTIVE=1 bash /tmp/agent-skills-install.sh

# 仅预览变更（不写入）
NON_INTERACTIVE=1 DRY_RUN=1 bash /tmp/agent-skills-install.sh
```

**Windows PowerShell（本地脚本）:**
```powershell
.\scripts\install.ps1 --non-interactive
.\scripts\install.ps1 --non-interactive --dry-run
```

### 发布版本安装（Tag/Release）

当需要稳定版本时，建议使用发布 Tag 安装/更新（例如 `v1.2.0`）：

```bash
curl -fsSL -o /tmp/agent-skills-install-v1.2.0.sh https://raw.githubusercontent.com/biglone/agent-skills/v1.2.0/scripts/install.sh
SKILLS_REF=v1.2.0 UPDATE_MODE=force INSTALL_TARGET=both bash /tmp/agent-skills-install-v1.2.0.sh
```

```powershell
$script = Join-Path $env:TEMP "agent-skills-install-v1.2.0.ps1"
Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/v1.2.0/scripts/install.ps1 -OutFile $script
$env:SKILLS_REF="v1.2.0"; $env:UPDATE_MODE="force"; powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

### Codex 启动前自动更新（macOS / Linux / Windows PowerShell）

当安装目标包含 Codex（`INSTALL_TARGET=codex` 或 `both`）时，安装脚本会自动：

1. 写入本地版本文件 `~/.codex/.skills_version`
2. 生成启动器（macOS/Linux: `codex-skills-auto-update.sh`；Windows: `codex-skills-auto-update.ps1`）
3. 将启动器注入 shell/profile（幂等覆盖）

之后每次执行 `codex` 都会先检查远端 `scripts/manifest/version.txt`，若版本变化则自动执行远程安装更新。
仓库维护时请同步更新 `scripts/manifest/version.txt`，以触发客户端自动更新。

### 手动安装

**macOS / Linux:**
```bash
git clone https://github.com/biglone/agent-skills.git

# Claude Code
cp -r agent-skills/skills/* ~/.claude/skills/

# Codex CLI
cp -r agent-skills/skills/* ~/.codex/skills/
```

**Windows:**
```powershell
git clone https://github.com/biglone/agent-skills.git

# Claude Code
Copy-Item -Recurse agent-skills\skills\* $env:USERPROFILE\.claude\skills\

# Codex CLI
Copy-Item -Recurse agent-skills\skills\* $env:USERPROFILE\.codex\skills\
```

## 更新 Skills

首次使用请运行安装脚本（`install.sh` / `install.ps1`），`update` 脚本用于已安装后的日常同步更新。

**macOS / Linux:**
```bash
SKILLS_REF="${SKILLS_REF:-v1.2.0}"
curl -fsSL -o /tmp/agent-skills-update.sh "https://raw.githubusercontent.com/biglone/agent-skills/${SKILLS_REF}/scripts/update.sh"
bash /tmp/agent-skills-update.sh
```

**Windows (PowerShell):**
```powershell
$ref = if ($env:SKILLS_REF) { $env:SKILLS_REF } else { "v1.2.0" }
$script = Join-Path $env:TEMP "agent-skills-update.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/$ref/scripts/update.ps1" -OutFile $script
powershell -NoProfile -ExecutionPolicy Bypass -File $script

# 启用市场发现 + 冲突融合
$env:SKILL_MARKET_DISCOVERY="all"
$env:SKILL_MARKET_CONFLICT_MODE="merge"
$env:SKILL_MARKET_EXTRA_REPOS="your-org/skills-repo@<ref>"
$env:UPDATE_TARGET="both"
powershell -NoProfile -ExecutionPolicy Bypass -File $script

# allowlist + merge 后直接应用（带本地备份与快照保留策略）
$env:SKILL_MARKET_DISCOVERY="all"
$env:SKILL_MARKET_ALLOWLIST="your-org/skills-repo,another-org/skills-repo"
$env:SKILL_MARKET_CONFLICT_MODE="merge"
$env:SKILL_MARKET_MERGE_APPLY_MODE="apply"
$env:SKILL_MARKET_MERGE_BACKUP_FILE_NAME="SKILL.pre-merge.local.md"
$env:SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT="8"
$env:SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS="45"
$env:UPDATE_TARGET="both"
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

**Windows (cmd):**
```cmd
set "SKILLS_REF=v1.2.0" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-update.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/update.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"
```

使用发布 Tag 更新（示例）：

```bash
curl -fsSL -o /tmp/agent-skills-update-v1.2.0.sh https://raw.githubusercontent.com/biglone/agent-skills/v1.2.0/scripts/update.sh
SKILLS_REF=v1.2.0 UPDATE_TARGET=both bash /tmp/agent-skills-update-v1.2.0.sh
```

启用外部 skill 市场同步（示例）：

```bash
SKILLS_REF="${SKILLS_REF:-v1.2.0}"
curl -fsSL -o /tmp/agent-skills-update.sh "https://raw.githubusercontent.com/biglone/agent-skills/${SKILLS_REF}/scripts/update.sh"
SKILL_MARKET_DISCOVERY=all \
  SKILL_MARKET_EXTRA_REPOS="your-org/skills-repo,another-org/skills-repo@<ref>" \
  SKILL_MARKET_CONFLICT_MODE=merge \
  UPDATE_TARGET=both \
  bash /tmp/agent-skills-update.sh
```

## 卸载 Skills

**macOS / Linux:**
```bash
SKILLS_REF="${SKILLS_REF:-v1.2.0}"
curl -fsSL -o /tmp/agent-skills-uninstall.sh "https://raw.githubusercontent.com/biglone/agent-skills/${SKILLS_REF}/scripts/uninstall.sh"
bash /tmp/agent-skills-uninstall.sh
```

**Windows (PowerShell):**
```powershell
$ref = if ($env:SKILLS_REF) { $env:SKILLS_REF } else { "v1.2.0" }
$script = Join-Path $env:TEMP "agent-skills-uninstall.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/$ref/scripts/uninstall.ps1" -OutFile $script
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

**Windows (cmd):**
```cmd
set "SKILLS_REF=v1.2.0" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-uninstall.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/uninstall.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"
```

## 目录结构

```
agent-skills/
├── README.md
├── skills/                     # Skills 目录
│   ├── code-reviewer/
│   │   └── SKILL.md
│   ├── commit-message/
│   │   └── SKILL.md
│   ├── ... (49 个 Skills)
│   └── mind-mapper/
│       └── SKILL.md
├── workflows/                  # 工作流目录
│   ├── full-auto-development/
│   │   └── WORKFLOW.md
│   ├── code-review-flow/
│   │   └── WORKFLOW.md
│   ├── feature-development/
│   │   └── WORKFLOW.md
│   ├── content-creation/
│   │   └── WORKFLOW.md
│   ├── weekly-planning/
│   │   └── WORKFLOW.md
│   ├── learning-path/
│   │   └── WORKFLOW.md
│   └── project-kickoff/
│       └── WORKFLOW.md
└── scripts/
    ├── install.sh              # macOS / Linux
    ├── install.ps1             # Windows
    ├── update.sh
    ├── update.ps1
    ├── uninstall.sh
    └── uninstall.ps1
```

## Skill 之间的关联

每个 Skill 都通过 `related-skills` 字段定义了与其他 Skill 的关联关系，让整个技能库形成一个有机的整体：

```yaml
---
name: note-taker
description: 笔记整理和知识提取
allowed-tools: Read
related-skills: knowledge-base, concept-explainer, meeting-notes
---
```

## 添加新的 Skill

1. 在 `skills/` 目录下创建新文件夹
2. 创建 `SKILL.md` 文件，包含必要的 frontmatter:

```markdown
---
name: my-skill
description: 描述这个 skill 的功能和触发条件
allowed-tools: Read, Grep, Glob
related-skills: skill-a, skill-b
---

# Skill 标题

你的 skill 内容...
```

3. 提交并推送到仓库
4. 其他人运行更新脚本即可获取

## 贡献指南

1. Fork 本仓库
2. 创建你的 Skill 分支 (`git checkout -b skill/my-new-skill`)
3. 提交更改 (`git commit -m 'feat: add my-new-skill'`)
4. 推送到分支 (`git push origin skill/my-new-skill`)
5. 创建 Pull Request

## License

MIT
