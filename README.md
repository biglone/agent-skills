# AI Skills 集合

一个可共享的 AI 助手 Skills 仓库，支持 **Claude Code**、**OpenAI Codex CLI** 和 **Gemini CLI**，方便团队成员和多设备快速安装使用。

> 📝 仓库已从 `claude-skills` 更名为 `agent-skills`。旧地址会被 GitHub 重定向，建议尽快切换到新地址以避免后续失效。

## 支持的平台

| 平台 | Skills 目录 |
|------|-------------|
| Claude Code | `~/.claude/skills/` |
| OpenAI Codex CLI | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` 或 `~/.agents/skills/` |

> Gemini CLI 官方支持 `~/.gemini/skills/` 与 `~/.agents/skills/`。本仓库安装脚本默认写入 `~/.gemini/skills/`，若检测到已存在的 `~/.agents/skills/`，会优先使用该别名目录；也可通过 `GEMINI_SKILLS_DIR` 显式覆盖。

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
| `github-repo-analyzer` | 根据 GitHub 仓库地址或本地目录分析项目定位、架构、模块职责与学习路径 |
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
- 📦 [**安装/更新参考**](./INSTALL_REFERENCE.md) - 固定版本、单平台安装、非交互、`cmd` 兼容与环境变量
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

## 安装与更新

README 只保留高频命令。固定版本、单平台安装、非交互、`cmd` 兼容、外部 skill 市场同步和完整环境变量请看 [安装/更新参考](./INSTALL_REFERENCE.md)。

运行安装脚本后，会提示选择安装目标（Claude Code / Codex CLI / Gemini CLI / 多平台组合）。
安装与更新均按 `scripts/manifest/skills.txt` / `scripts/manifest/workflows.txt` 执行，不会扫描并安装内部目录。

### 安装

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

### 更新

首次安装后，日常同步使用 `update` 脚本。

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

### 进一步阅读

- [安装/更新参考](./INSTALL_REFERENCE.md)：固定 tag、单平台安装、卸载、非交互、`cmd` 兼容、Skill Market、完整变量表
- [故障排除指南](./TROUBLESHOOTING.md)：安装失败、路径不生效、网络问题
- [快速开始指南](./GETTING_STARTED.md)：第一次使用后的典型工作流

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
