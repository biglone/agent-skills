# 新增 Skills 模板命令

这份文档整理了最近新增技能的高触发率模板命令，适合直接复制后按需修改。

## 通用公式

```text
请使用 <skill名> skill，帮我做 <目标>，输入是 <材料>，约束是 <限制>，输出为 <格式>。
```

建议每次都明确 4 个元素：

- 目标
- 输入
- 约束
- 输出格式

## 推荐优先使用

如果你只想先试最实用的几个，优先从这些开始：

- `claude-api`
- `mcp-builder`
- `webapp-testing`
- `skill-creator`

## 模板列表

### `claude-api`

```text
请使用 claude-api skill，帮我用 Python 写一个 Claude API 流式聊天示例，要求从环境变量读取 API Key，输出可直接运行的完整项目。
```

### `mcp-builder`

```text
请使用 mcp-builder skill，帮我实现一个 GitHub Issues MCP server，要求支持列出 issue、创建 issue、关闭 issue，并给出启动与测试步骤。
```

### `webapp-testing`

```text
请使用 webapp-testing skill，帮我测试本地 http://localhost:3000 的登录流程，验证输入校验、登录成功跳转、失败提示，并输出测试脚本。
```

### `skill-creator`

```text
请使用 skill-creator skill，帮我设计一个用于“代码库升级安全审计”的新 skill，包含触发描述、SKILL.md、测试提示词和评估方法。
```

### `frontend-design`

```text
请使用 frontend-design skill，帮我设计一个高质感 SaaS landing page，要求深色风格、响应式、带定价区和 FAQ，输出 HTML/CSS/JS。
```

### `web-artifacts-builder`

```text
请使用 web-artifacts-builder skill，帮我做一个单文件 Web artifact，用于展示日报数据，要求支持筛选、状态标签和详情弹窗。
```

### `algorithmic-art`

```text
请使用 algorithmic-art skill，帮我生成一幅可调参数的生成艺术作品，主题是“数据流星空”，输出 HTML + JS，并支持随机种子。
```

### `canvas-design`

```text
请使用 canvas-design skill，帮我设计一张活动海报，主题是“AI Skill Market Audit”，尺寸 A4，输出 PNG 和 PDF。
```

### `theme-factory`

```text
请使用 theme-factory skill，帮我给这份技术汇报套一个科技感主题，要求给出配色、字体建议和应用后的文档结构。
```

### `brand-guidelines`

```text
请使用 brand-guidelines skill，帮我把这份产品介绍改成统一品牌风格，要求统一颜色、标题层级和视觉语气。
```

### `internal-comms`

```text
请使用 internal-comms skill，帮我写一份项目 3P 更新，包含 Progress、Plans、Problems，语气简洁适合团队同步。
```

### `slack-gif-creator`

```text
请使用 slack-gif-creator skill，帮我设计一个适合 Slack 的 loading 动图 GIF，尺寸 128x128，风格简洁科技感。
```

## 使用建议

- 最稳的触发方式是直接写出 `请使用 <skill名> skill`
- 如果任务复杂，先写目标，再补输入材料和限制条件
- 如果你要可执行产物，最好明确输出类型，例如 `HTML`、`Markdown`、`Python 项目`、`测试脚本`
- 如果你在本机跑任务，记得补充路径、端口、文件名等上下文

## 相关说明

- 当前这些模板对应的技能已经同步到本机 `Claude Code` 和 `Codex CLI`
- `docx`、`pdf`、`pptx`、`xlsx`、`doc-coauthoring` 当前未纳入本仓库，原因见 `THIRD_PARTY_NOTICES.md`
