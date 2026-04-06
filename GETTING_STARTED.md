# 快速开始指南

全自动开发工作流的完整使用教程，从安装到实战。

> 仓库已从 `claude-skills` 更名为 `agent-skills`，请使用新地址安装与更新。

## 目录

- [安装](#安装)
- [5分钟快速体验](#5分钟快速体验)
- [完整流程演示](#完整流程演示)
- [常用命令](#常用命令)
- [实战案例](#实战案例)
- [最佳实践](#最佳实践)

---

## 安装

### 方式 1：一键安装（推荐）

**macOS / Linux:**
```bash
SKILLS_REF="${SKILLS_REF:-v1.2.0}"
curl -fsSL -o /tmp/agent-skills-install.sh "https://raw.githubusercontent.com/biglone/agent-skills/${SKILLS_REF}/scripts/install.sh"
bash /tmp/agent-skills-install.sh
```

**Windows (PowerShell):**
```powershell
$ref = if ($env:SKILLS_REF) { $env:SKILLS_REF } else { "v1.2.0" }
$script = Join-Path $env:TEMP "agent-skills-install.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/biglone/agent-skills/$ref/scripts/install.ps1" -OutFile $script
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

**Windows (cmd):**
```cmd
set "SKILLS_REF=v1.2.0" && powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'agent-skills-install.ps1'; Invoke-WebRequest https://raw.githubusercontent.com/biglone/agent-skills/%SKILLS_REF%/scripts/install.ps1 -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p"
```

说明：`irm` 是 PowerShell 命令别名，在 `cmd` 里不能直接执行。
说明：示例默认使用已发布版本 `v1.2.0`；如需跟随最新分支，请显式设置 `SKILLS_REF=main`。

### 方式 2：手动安装

```bash
git clone https://github.com/biglone/agent-skills.git
cd agent-skills

# Claude Code
cp -r skills/* ~/.claude/skills/
cp -r workflows/* ~/.claude/workflows/

# Codex CLI
cp -r skills/* ~/.codex/skills/
cp -r workflows/* ~/.codex/workflows/
```

### 验证安装

```bash
# 在 Claude Code 中
ls ~/.claude/skills/requirements-doc
ls ~/.claude/workflows/full-auto-development

# 应该看到 SKILL.md 和 WORKFLOW.md 文件
```

---

## 5分钟快速体验

### 场景：生成需求文档

**最简单的使用方式 - 只生成文档，不写代码**

```bash
# 1. 启动 Claude Code
claude

# 2. 输入命令
生成需求文档：实现用户登录功能

# 3. AI 会自动生成两个文件
# - REQUIREMENTS.md（详细需求文档）
# - TASK_LIST.md（任务清单）

# 4. 查看生成的文档
cat REQUIREMENTS.md
cat TASK_LIST.md
```

**你会得到：**
- ✅ 结构化的需求文档（11个章节）
- ✅ 详细的任务拆解（按优先级和依赖关系）
- ✅ 技术方案建议
- ✅ 风险识别

**用时：** 约 2-3 分钟

---

## 完整流程演示

### 场景：从需求到代码的完整自动化

**第1步：启动全自动开发**

```bash
# 在 Claude Code 中
全自动开发：实现用户登录注册功能，支持邮箱和手机号
```

**第2步：AI 生成需求文档**

```
AI 会自动：
✅ 分析需求
✅ 生成 REQUIREMENTS.md
✅ 生成 TASK_LIST.md
✅ 展示摘要供你确认
```

**第3步：人工确认（关键！）**

AI 会展示：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 需求文档已生成

功能概述：
  用户登录注册系统，支持邮箱和手机号注册

功能模块划分：
  📱 前端模块：
    • 登录组件 (Login.tsx)
    • 注册组件 (Register.tsx)
    • 验证组件 (Validation.tsx)

  🔧 后端模块：
    • 认证 API (/api/auth)
    • 用户管理 (/api/users)
    • 短信服务 (sms.service.ts)

  🗄️  数据库模块：
    • users 表
    • sessions 表

任务拆解：
  阶段1 (准备): 3 个任务
  阶段2 (开发): 10 个任务
  阶段3 (测试): 3 个任务
  阶段4 (发布): 2 个任务

  总计: 18 个任务
  预估工作量: 3-4 天

请审查后输入"继续开发"开始实现
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**你的选择：**
```bash
# 选项 1：直接开始开发
继续开发

# 选项 2：修改某个部分
修改功能模块  # AI 会重新生成该部分

# 选项 3：查看详细信息
详细说明技术方案

# 选项 4：取消
取消
```

**第4步：AI 自动开发**

一旦你确认，AI 会自动：

```
[阶段 1/5] 📋 读取任务列表
✅ 加载 18 个任务

[阶段 2/5] 💻 代码实现
🔄 任务 1/18: 创建用户类型定义
✅ 创建 src/types/user.ts (32 lines)

🔄 任务 2/18: 实现登录组件
✅ 创建 src/components/Login.tsx (68 lines)

... (继续所有任务)

[阶段 3/5] 🧪 测试验证
🔄 运行测试...
⚠️  2 个测试失败
🔧 自动修复...
✅ 全部测试通过

[阶段 4/5] 🔍 代码审查
✅ 无问题发现

[阶段 5/5] 📝 生成提交
✅ 完成
```

**第5步：查看结果**

```bash
# 查看生成的文件
ls -la src/

# 查看提交
git log -1

# 查看详细日志
cat .claude-dev.log
```

**用时：** 根据项目复杂度，通常 10-30 分钟

---

## 常用命令

### 基础命令

```bash
# 1. 只生成需求文档
"生成需求文档：[功能描述]"
"需求分析：[功能描述]"

# 2. 完整自动开发
"全自动开发：[功能描述]"
"自动完成功能：[功能描述]"

# 3. 从已有需求文档开始开发
"根据 REQUIREMENTS.md 开始开发"
```

### 进度管理

```bash
# 查看当前进度
"当前进度"
"进度如何"
"status"

# 查看详细日志
"查看日志"
"查看完整日志"
"查看错误日志"

# 查看检查点
"查看检查点"
```

### 恢复和继续

```bash
# 从中断恢复
"继续"
"resume"
"继续之前的任务"

# 从检查点恢复
"从检查点3恢复"
"从上个检查点重试"

# 手动修复后继续
"已修复，继续"
```

### 修改和调整

```bash
# 修改需求文档的某个部分
"修改功能模块"
"修改任务列表"
"调整技术方案"

# 查看详细信息
"详细说明技术方案"
"详细说明任务"
```

---

## 实战案例

### 案例 1：简单功能 - Todo List

**需求：**
```bash
全自动开发：实现一个简单的 Todo List，支持添加、删除、标记完成
```

**生成结果：**
- 前端：TodoList 组件、TodoItem 组件
- 状态管理：使用 React Hooks
- 持久化：LocalStorage
- 测试：6 个单元测试

**用时：** 约 8 分钟

---

### 案例 2：中等复杂度 - 博客评论系统

**需求：**
```bash
全自动开发：实现博客评论系统，支持评论、回复、点赞、举报，需要审核机制
```

**生成结果：**
- 前端：评论列表、评论表单、审核面板
- 后端：评论 API、审核 API、通知服务
- 数据库：comments 表、reports 表
- 测试：18 个测试用例

**用时：** 约 25 分钟

**人工确认环节：**
```
AI: 功能模块划分中包含"审核面板"，这是管理员功能吗？

你: 是的，只有管理员可以访问

AI: 了解，我会添加权限检查。继续开发吗？

你: 继续开发
```

---

### 案例 3：复杂功能 - 实时聊天

**需求：**
```bash
全自动开发：实现实时聊天功能，支持一对一聊天、群聊、消息已读状态、在线状态显示
```

**生成结果：**
- 前端：聊天组件、消息列表、输入框、在线状态
- 后端：WebSocket 服务、消息队列、用户在线状态管理
- 数据库：messages 表、conversations 表、participants 表
- 测试：32 个测试用例

**用时：** 约 45 分钟

**遇到的问题：**
```
AI: 测试失败 - WebSocket 连接超时

AI: 已尝试 3 次修复失败，需要人工介入
    建议检查：WebSocket 服务是否启动

你: [启动 WebSocket 服务]
你: 已修复，继续

AI: ✅ 测试通过，继续下一阶段...
```

---

## 最佳实践

### 1. 写出好的需求描述

**✅ 好的需求描述：**
```bash
# 具体、清晰、包含关键细节
"实现用户登录注册功能，支持邮箱和手机号注册，包含找回密码、邮箱验证"

"添加商品评论系统，用户可以评分（1-5星）、评论、上传图片，管理员可以审核"

"实现文件上传功能，支持图片、PDF、文档，最大10MB，需要进度显示和断点续传"
```

**❌ 不够清晰的描述：**
```bash
# 太简单，缺少细节
"做个登录"
"加个评论功能"
"文件上传"
```

### 2. 合理使用确认环节

**应该确认的情况：**
- ✅ 功能模块划分是否合理
- ✅ 技术方案是否符合项目需求
- ✅ 任务拆解粒度是否合适
- ✅ 风险提示是否需要关注

**可以直接继续的情况：**
- ✅ 简单功能，需求明确
- ✅ 对生成的文档很满意
- ✅ 技术栈和项目一致

### 3. 充分利用进度记录

```bash
# 定期查看进度
"当前进度"

# 遇到问题查看日志
"查看错误日志"

# 长时间运行的任务可以中断休息
# 重连后继续即可
"继续"
```

### 4. 处理错误的策略

**自动修复失败时：**
1. 查看错误详情：`"查看错误详情"`
2. 查看完整日志：`"查看完整日志"`
3. 手动修复代码
4. 继续执行：`"已修复，继续"`

**或者从检查点重试：**
```bash
"查看检查点"
"从检查点2恢复"
```

### 5. 安全注意事项

**AI 会自动跳过这些文件：**
- `.env` 文件
- `credentials.json`
- `secrets.*`
- `*.key`

**大规模操作会二次确认：**
- 删除 10+ 个文件
- 修改核心配置文件
- 数据库迁移操作

### 6. 提高成功率的技巧

**技巧 1：分阶段实现**
```bash
# 不要一次性提出太复杂的需求
# 可以分阶段：

第一阶段：
"全自动开发：实现基础的用户登录功能"

第二阶段：
"全自动开发：添加找回密码功能"

第三阶段：
"全自动开发：添加第三方登录（Google、GitHub）"
```

**技巧 2：提供上下文**
```bash
# 如果项目已有特定技术栈或模式
"全自动开发：实现商品评论，使用项目现有的 Redux 状态管理和 Material-UI 组件库"
```

**技巧 3：明确约束条件**
```bash
"全自动开发：实现图片上传，要求支持拖拽上传、预览、压缩，单个文件最大5MB"
```

---

## 配置和自定义

### 创建配置文件（可选）

在项目根目录创建 `.claude-config.json`：

```json
{
  "full_auto_development": {
    "auto_commit": false,
    "max_retries": 3,
    "log_level": "info",
    "excluded_files": [".env", "secrets.json"],
    "custom_commands": {
      "test": "npm test",
      "lint": "eslint .",
      "build": "npm run build"
    }
  }
}
```

---

## 常见问题

### Q1: 中断后如何恢复？

```bash
# 重新连接后直接输入
"继续"

# AI 会自动检测未完成的任务并展示进度
```

### Q2: 生成的代码不满意怎么办？

```bash
# 方式 1：从检查点重新开始
"查看检查点"
"从检查点2恢复"

# 方式 2：手动修改后继续
# [手动修改代码]
"已修复，继续"

# 方式 3：取消重新开始
"取消"
# 然后重新发起，调整需求描述
```

### Q3: 可以只生成文档不写代码吗？

```bash
# 可以，使用需求分析命令
"生成需求文档：[功能描述]"
"需求分析：[功能描述]"

# 生成文档后不输入"继续开发"即可
```

### Q4: 支持哪些编程语言？

目前支持：
- JavaScript / TypeScript
- Python
- Go
- Rust
- Java
- Ruby

AI 会自动检测项目技术栈。

### Q5: 生成的测试覆盖率如何？

通常包括：
- 单元测试（核心功能）
- 集成测试（API 端点）
- 边界情况测试

覆盖率一般在 70-85%。

---

## 下一步

**深入学习：**
- 📖 [配置指南](./CONFIG.md) - 自定义行为
- 🔧 [故障排除](./TROUBLESHOOTING.md) - 解决常见问题
- 🚀 [性能优化](./PERFORMANCE.md) - 提高执行速度
- 💡 [提示词优化](./PROMPT_OPTIMIZATION.md) - 写出更好的需求

**实践项目：**
- 🎯 从简单功能开始（Todo List）
- 🎯 尝试中等复杂度（评论系统）
- 🎯 挑战复杂功能（聊天系统）

**加入社区：**
- 💬 提交 Issue：报告问题或建议
- 🤝 贡献代码：改进 skills 和 workflows
- 📝 分享经验：你的使用案例

---

## 总结

**全自动开发工作流的核心价值：**

1. **节省时间** - 从需求到代码自动化
2. **标准化** - 统一的开发流程和文档格式
3. **可靠性** - 详细的进度记录和错误恢复
4. **可控性** - 人工确认环节确保方向正确

**记住：**
- ✅ 写出清晰具体的需求描述
- ✅ 在确认环节仔细审查
- ✅ 善用进度查询和日志
- ✅ 遇到问题不慌，有完整的恢复机制

现在就开始你的第一个全自动开发任务吧！🚀
