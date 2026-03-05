---
name: interviewer
description: 面试官面试设计与评估。当用户要求设计面试流程、生成面试题、制定评分标准、给出录用建议时使用。
allowed-tools: Read, WebSearch, Bash
related-skills: interview-helper, feedback-giver, decision-maker
---

# 面试官助手

将“聊得不错”转成“可复核、可比较、可决策”的结构化面试结果。

## 核心流程

1. 明确岗位画像：职责、级别、必备项、加分项
2. 设计面试环节：行为面、专业面、情景题、反向提问
3. 统一评分标准：维度、分档、红线、录用门槛
4. 执行面试记录：证据化记录，不凭印象打分
5. 输出决策建议：录用/保留/不通过 + 风险说明

## 面试设计模板

```markdown
# [岗位名称] 面试方案

## 岗位关键信号
- 必备能力：
- 加分能力：
- 红线项：

## 面试轮次
| 轮次 | 目标 | 时长 | 题型 |
|------|------|------|------|
| 初面 | 沟通与基础匹配 | 30min | 行为面 |
| 专业面 | 专业能力验证 | 45min | 案例/实操 |
| 终面 | 价值观与风险评估 | 30min | 情景题 |

## 评分维度（1-5分）
| 维度 | 定义 | 1分表现 | 3分表现 | 5分表现 |
|------|------|---------|---------|---------|
| 专业能力 | | | | |
| 解决问题 | | | | |
| 沟通协作 | | | | |
| 主动性 | | | | |

## 录用规则
- 平均分门槛：>= X
- 必备维度最低分：>= X
- 红线项：一票否决
```

## 提问设计原则

- 同一岗位使用同一题库主干，确保候选人可比较
- 问“行为证据”而不是问“态度口号”
- 每个问题配追问脚本，验证真实性和深度

## 面试记录模板

```markdown
# [候选人] 面试记录

## 问题与证据
| 问题 | 候选人要点 | 证据强度(弱/中/强) | 面试官观察 |
|------|------------|--------------------|------------|
| | | | |

## 评分
| 维度 | 分数(1-5) | 依据 |
|------|-----------|------|
| 专业能力 | | |
| 解决问题 | | |
| 沟通协作 | | |
| 主动性 | | |

## 风险提示
- 风险1：
- 风险2：

## 建议
- 结论：录用 / 保留 / 不通过
- 理由：
- 后续动作（如补面主题）：
```

## 反偏差检查

- 是否过度受首因/近因效应影响
- 是否因表达风格替代了能力判断
- 是否对不同候选人使用了同一标准
- 结论是否有可追溯证据

## Qt/C++/机器人题库（动态更新）

### 目标

- 避免固定题库长期过时
- 优先基于最近技术动态生成面试题
- 保留统一评分锚点，兼顾可比较性

### 推荐流程

1. 先更新最新题库快照（联网）
2. 按岗位级别筛选题目（初级/中级/高级）
3. 生成面试脚本（主问题 + 追问 + 评分点）

### 更新命令

在 `skills/interviewer/` 目录执行：

```bash
python3 scripts/update_question_bank.py
```

可选参数：

```bash
python3 scripts/update_question_bank.py \
  --max-items 8 \
  --output references/question-bank-latest.md
```

### 生成 1 小时面试脚本（推荐）

```bash
python3 scripts/generate_interview_pack.py \
  --domain qt \
  --level mid
```

可选参数：

```bash
python3 scripts/generate_interview_pack.py \
  --domain robotics \
  --level senior \
  --latest-count 3 \
  --output references/interview-pack-robotics-senior.md
```

### 自动刷新（可选）

安装定时任务（默认每 6 小时更新一次）：

```bash
bash scripts/install_refresh_cron.sh
```

自定义频率（CRON 表达式）：

```bash
CRON_SCHEDULE="0 */3 * * *" bash scripts/install_refresh_cron.sh
```

### 题库文件

- 基础模板：`references/question-bank-template.md`
- 分级模板：`references/question-bank-levels-template.md`
- 最新快照：`references/question-bank-latest.md`（脚本自动生成）
- 面试脚本：`references/interview-pack-<domain>-<level>.md`（脚本自动生成）

### 渐进加载（按需读取）

- 要看固定结构和评分规则：读取 `references/question-bank-template.md`
- 要按初级/中级/高级面试：读取 `references/question-bank-levels-template.md`
- 要看最近热点题干：读取 `references/question-bank-latest.md`

### 实时获取策略

- 默认优先使用 `scripts/update_question_bank.py` 的结果
- 如果脚本源站不可达，再使用 `WebSearch` 临时补齐最新话题
- 输出时标注“题库更新时间”和“主题来源链接”
