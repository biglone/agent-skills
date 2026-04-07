---
name: skill-market-auditor
description: 升级与审计当前 Skill 库：从网络 skill marketplace / GitHub topics 发现候选 skills，补全或新增缺失能力，并对外部 skill 仓库做供应链、安全风险与提示注入排查。当用户要求升级当前 skill 库、从 marketplace 补全或新增 skills、扫描外部 skill 仓库安全风险、做 skill 供应链审计时使用。
allowed-tools: Read, Grep, Glob, Bash, WebSearch, Write, Edit
related-skills: security-audit, dependency-analyzer, technical-writer, code-reviewer
---

# Skill 市场升级与审计助手

用于升级当前仓库的 Skill 库，并在引入外部 skills 前完成安全排查。

优先复用当前仓库已有约定：

- `skills/<name>/SKILL.md`
- `scripts/manifest/skills.txt`
- `scripts/manifest/market-seed-repos.txt`
- `scripts/manifest/skill-market-allowlist.txt`
- `scripts/validate-skills.sh`
- `scripts/install.sh` / `scripts/update.sh` 中的 `SKILL_MARKET_*` 机制

## 核心原则

- 先盘点本地，再搜索外部 marketplace，最后决定 `add` / `merge-preview` / `replace` / `reject`。
- 外部 skill 一律先审计，禁止“搜到就装”。
- 扫描结果是启发式证据，不等于漏洞定论；高危和关键风险必须人工复核。
- 涉及“今天/最新/最近”的市场信息时，必须记录绝对日期。

## 需要的输入

- 当前 Skill 仓库根目录
- 本地基线清单：`scripts/manifest/skills.txt`
- 可选白名单：允许同步的组织、仓库、发布者
- 可选目标方向：例如补全测试、文档、UI、运维、安全类 skills

## 标准流程

### 1. 盘点本地 Skill 库

1. 读取 `scripts/manifest/skills.txt`，确认已纳管 skills。
2. 列出 `skills/*/SKILL.md`，找出：
   - manifest 中声明但目录缺失的 skill
   - 目录存在但 manifest 未收录的 skill
   - 已存在 `.agent-skills-source` 的外部来源 skill
3. 运行：

```bash
bash scripts/validate-skills.sh
```

4. 汇总当前缺口：
   - 哪些能力缺失
   - 哪些 skill 过于简陋，需要外部补强
   - 哪些已有同名 skill 可能需要 merge

### 2. 发现外部 marketplace 候选

优先使用 WebSearch / GitHub 搜索，不直接执行外部脚本。

优先使用本 skill 自带的发现脚本做第一轮筛选：

```bash
python3 skills/skill-market-auditor/scripts/discover_market_repos.py \
  --query topic:agent-skills \
  --query topic:claude-code-skill \
  --query topic:codex-skill \
  --per-query 10 \
  --min-stars 10 \
  --format markdown
```

首选线索：

- GitHub Topics：`agent-skills`
- GitHub Topics：`claude-code-skill`
- GitHub Topics：`codex-skill`
- 当前仓库已有 seed 清单：`scripts/manifest/market-seed-repos.txt`，其仓库会直接并入发现候选池
- 维护者或官方组织发布的 skills 仓库

筛选标准：

- 仓库近期仍在维护
- Skill 结构清晰，存在 `SKILL.md` 或等价 manifest
- 许可证清晰
- 与当前仓库能力缺口相关
- 发布者可信，优先官方组织、知名维护者、已有白名单仓库

记录每个候选仓库时至少带上：

- 仓库 URL
- 分支 / tag / commit
- 最近更新时间的绝对日期
- stars 或其他活跃度信号
- 拟引入的 skill 名称

发现脚本输出的 `updated_at` 必须按绝对日期记录，不要写“最近更新”。

### 3. 先做安全与供应链审计

对每个候选仓库先运行本 skill 附带的扫描脚本：

```bash
python3 skills/skill-market-auditor/scripts/scan_skill_repo.py \
  --repo https://github.com/owner/repo.git \
  --baseline-manifest scripts/manifest/skills.txt \
  --format markdown
```

本地目录也可直接扫描：

```bash
python3 skills/skill-market-auditor/scripts/scan_skill_repo.py \
  --repo /path/to/cloned/repo \
  --baseline-manifest scripts/manifest/skills.txt
```

重点排查：

- 提示注入 / 工具投毒：覆盖前文指令、隐藏指令、HTML 注释、混淆文本
- 远程代码执行：远程下载后直接交给 shell/解释器执行、PowerShell 表达式执行、`eval`、`os.system`、`shell=True`
- 凭证读取与外传：读取 `.env`、`~/.ssh`、`~/.aws/credentials`、环境变量后再发往外部
- 破坏性命令：批量强删目录、强制重置 Git 历史、`git clean` 清理、磁盘格式化、系统关机重启
- 浮动引用：直接依赖 `main` / `master` 或未固定 commit 的远端脚本
- 路径风险：越界符号链接、可疑可执行文件、二进制投放
- 许可证与来源：无 license、发布者未知、维护状态异常

### 4. 做升级决策

对每个候选按以下四类处理：

- `add`：本地缺失且审计通过，可新增
- `merge-preview`：本地已存在同名或相近 skill，先生成融合建议
- `replace`：确认外部版本显著更好，且本地没有必须保留的定制
- `reject`：存在未解决高危风险、来源不明或维护状态差
- `audit-failed`：仓库抓取、网络或基础设施失败，需重试后再判断是否安全

默认优先 `merge-preview`，不要直接覆盖本地定制。

若当前仓库准备使用内置市场同步机制，再使用这些参数：

- `SKILL_MARKET_DISCOVERY=manifest|github|all`
- `SKILL_MARKET_EXTRA_REPOS=owner/repo,owner/repo@branch`
- `SKILL_MARKET_ALLOWLIST=owner/repo,owner/repo`
- `SKILL_MARKET_CONFLICT_MODE=skip|replace|merge`
- `SKILL_MARKET_MERGE_APPLY_MODE=preview|apply`

### 5. 落地变更

新增或引入 skill 时至少完成：

1. 新建或更新 `skills/<name>/`
2. 更新 `scripts/manifest/skills.txt`
3. 记录来源仓库、ref、审计日期和决策依据
4. 再次运行 `bash scripts/validate-skills.sh`

## 本地日报自动化

如果你的目标是每天自动做“发现 → 审计 → merge preview 报告 → Matrix 通知”，优先复用仓库内置骨架：

```bash
./scripts/run-skill-market-daily-audit.sh
```

可选发送 Matrix 详细报告：

```bash
MATRIX_HOMESERVER_URL=https://matrix.example.com \
MATRIX_ACCESS_TOKEN=... \
MATRIX_ROOM_ID='!roomid:example.com' \
./scripts/run-skill-market-daily-audit.sh --notify-matrix
```

默认行为：

- 只对白名单仓库做深度审计：`scripts/manifest/skill-market-allowlist.txt`
- seed 仓库清单：`scripts/manifest/market-seed-repos.txt`
- 报告写入：`reports/skill-market/`
- 单次运行目录：`reports/skill-market/runs/YYYY-MM-DD/HHMMSS/`
- 只生成 merge preview，不自动改动本地 `skills/`
- Matrix 发送完整报告正文，便于直接查看 `add` / `merge-preview` / `audit-failed` 结论

## 报告模板

```markdown
## Skill 市场升级与安全审计报告

### 1. 本地基线
- 当前 skills 数量:
- manifest 缺口:
- 需要补强的能力:

### 2. 外部候选
| 仓库 | 来源 | 最近更新 | 候选 skill | 结论 |
|------|------|----------|-------------|------|

### 3. 安全发现
- [CRITICAL/HIGH/MEDIUM/LOW] 标题
  - 位置:
  - 描述:
  - 影响:
  - 建议:

### 4. 升级建议
- add:
- merge-preview:
- replace:
- reject:
- audit-failed:
```

## 决策规则

- 只要存在未解释的 `critical` 或 `high` 级发现，默认不引入。
- 扫描命中“提示注入”或“外传凭证”时，必须人工打开原文件复核上下文。
- 如果候选 skill 只是文案补充，而本地实现更完整，优先保留本地版本。
- 如果外部 skill 更完整但来源一般，先把内容放到 merge preview，不要直接 apply。
- 如果审计失败原因是网络、速率限制或仓库暂时不可达，先记为 `audit-failed`，不要直接记成 `reject`。
- 对“最新”市场状态、star、更新时间，一律写成绝对日期。

## 何时不使用这个 skill

- 只是在本地写一个全新 skill，不涉及外部 marketplace 或安全审计
- 只想做普通依赖升级，不涉及 skill 库
