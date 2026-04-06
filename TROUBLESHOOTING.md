# 故障排除指南

解决使用全自动开发工作流时遇到的常见问题。

## 常见问题分类

- [安装问题](#安装问题)
- [执行问题](#执行问题)
- [恢复问题](#恢复问题)
- [性能问题](#性能问题)
- [错误处理](#错误处理)

---

## 安装问题

### Q1: 安装脚本执行失败

**症状：**
```bash
curl: (7) Failed to connect to raw.githubusercontent.com
```

**解决：**
```bash
# 方式 1：使用代理
export https_proxy=http://your-proxy:port
curl -fsSL -o /tmp/agent-skills-install.sh https://raw.githubusercontent.com/.../install.sh
bash /tmp/agent-skills-install.sh

# 方式 2：手动下载
git clone https://github.com/biglone/agent-skills.git
cd agent-skills
cp -r skills/* ~/.claude/skills/
```

### Q2: Skills 不生效

**症状：** 输入命令后 AI 不识别

**检查：**
```bash
# 1. 确认文件存在
ls ~/.claude/skills/requirements-doc/SKILL.md
ls ~/.claude/workflows/full-auto-development/WORKFLOW.md

# 2. 检查文件格式
cat ~/.claude/skills/requirements-doc/SKILL.md | head -10

# 3. 重启 Claude Code
exit
claude
```

---

## 执行问题

### Q3: 中断后无法恢复

**症状：** 输入"继续"没有反应

**诊断：**
```bash
# 检查进度文件是否存在
ls -la .claude-*.json

# 查看进度文件内容
cat .claude-fulldev.json
```

**解决：**
```bash
# 如果进度文件损坏
rm .claude-fulldev.json
rm .claude-progress.json

# 重新开始任务
```

### Q4: 测试一直失败

**症状：** AI 尝试修复 3 次后放弃

**排查步骤：**
1. 查看错误日志
   ```bash
   cat .claude-dev.log | grep ERROR
   ```

2. 手动运行测试
   ```bash
   npm test
   ```

3. 检查环境
   ```bash
   node --version
   npm --version
   ```

**解决：**
```bash
# 修复问题后继续
"已修复，继续"

# 或跳过测试
"跳过测试继续"

# 或从检查点重试
"从检查点2恢复"
```

### Q5: 生成的代码不符合预期

**原因：**
- 需求描述不够清晰
- 未在确认环节仔细审查
- AI 理解有偏差

**解决：**
```bash
# 方式 1：从检查点重新开始
"查看检查点"
"从检查点1恢复"  # 回到需求分析阶段

# 方式 2：取消重新开始
"取消"
# 重新描述需求，更加具体

# 方式 3：手动修改后继续
# [手动修改代码]
"已修复，继续"
```

---

## 恢复问题

### Q6: 进度文件丢失

**症状：** `.claude-*.json` 文件被删除

**恢复：**
```bash
# 检查是否有日志文件
ls .claude-dev.log

# 如果有日志，可以查看已完成的工作
cat .claude-dev.log

# 无法自动恢复，需要：
# 1. 查看 git status 了解已修改的文件
# 2. 手动创建进度文件（高级）
# 3. 或重新开始任务
```

### Q7: 会话完全断开

**症状：** 重新连接后找不到任何进度信息

**检查：**
```bash
# 1. 确认在正确的目录
pwd

# 2. 查找进度文件
find . -name ".claude-*.json" -type f

# 3. 查看 git 状态
git status
git log -1
```

**解决：**
```bash
# 如果有未提交的代码
git add .
git stash

# 重新开始任务
# AI 会检测已修改的文件并询问是否继续
```

---

## 性能问题

### Q8: 执行速度很慢

**原因分析：**
1. 项目规模大
2. 网络问题
3. 并发任务过多

**优化：**
```json
// .claude-config.json
{
  "advanced": {
    "parallel_execution": false,  // 禁用并行
    "optimize_for_speed": true    // 优化速度
  }
}
```

### Q9: 内存占用过高

**检查：**
```bash
# macOS/Linux
top | grep claude

# Windows
taskmgr
```

**优化：**
```json
{
  "safety": {
    "max_file_size_mb": 5,        // 降低文件大小限制
    "max_files_per_task": 20      // 降低文件数量限制
  },
  "global": {
    "max_concurrent_tasks": 1     // 减少并发
  }
}
```

---

## 错误处理

### Q10: 权限错误

**症状：**
```
Error: EACCES: permission denied
```

**解决：**
```bash
# 检查文件权限
ls -la

# 修复权限
chmod 755 scripts/
chmod 644 src/**/*.js

# 检查目录权限
sudo chown -R $USER:$USER .
```

### Q11: Git 错误

**症状：**
```
fatal: not a git repository
```

**解决：**
```bash
# 初始化 Git 仓库
git init
git add .
git commit -m "Initial commit"

# 然后重新运行
```

### Q12: 依赖安装失败

**症状：**
```
npm ERR! code ENOTFOUND
```

**解决：**
```bash
# 清除缓存
npm cache clean --force

# 切换镜像源
npm config set registry https://registry.npmmirror.com

# 备份当前依赖目录与 lock 文件
mv node_modules "node_modules.bak.$(date +%s)" 2>/dev/null || true
cp package-lock.json "package-lock.json.bak.$(date +%s)" 2>/dev/null || true

# 重新安装
npm install
```

---

## 诊断工具

### 收集诊断信息

```bash
# 运行诊断脚本
cat > diagnose.sh << 'SCRIPT'
#!/bin/bash
echo "=== Agent Skills 诊断信息 ==="
echo "当前目录: $(pwd)"
echo "Git 状态:"
git status --short || echo "不是 Git 仓库"
echo ""
echo "进度文件:"
ls -la .claude-*.json 2>/dev/null || echo "无进度文件"
echo ""
echo "日志文件:"
ls -la .claude-dev.log 2>/dev/null || echo "无日志文件"
echo ""
echo "配置文件:"
ls -la .claude-config.json 2>/dev/null || echo "无配置文件"
echo ""
echo "最近 10 行日志:"
tail -10 .claude-dev.log 2>/dev/null || echo "无日志"
SCRIPT

chmod +x diagnose.sh
./diagnose.sh
```

---

## 获取帮助

### 日志级别

```json
{
  "global": {
    "log_level": "debug"  // 获取更详细的日志
  }
}
```

### 社区支持

- GitHub Issues: https://github.com/biglone/agent-skills/issues
- 提供诊断信息和日志
- 描述复现步骤

---

## 紧急恢复

如果一切都不work，最后的手段：

```bash
# 1. 备份当前工作
cp -r . ../backup-$(date +%Y%m%d-%H%M%S)

# 2. 清理所有 Claude 文件
rm -f .claude-*.json
rm -f .claude-dev.log

# 3. 检查 git 状态
git status

# 4. 如果确认可以丢弃本地修改，再执行一次 Git 恢复命令回退到上次提交
#    先人工确认影响范围，再操作

# 5. 重新安装 skills
curl -fsSL -o /tmp/agent-skills-install.sh https://raw.githubusercontent.com/.../install.sh
UPDATE_MODE=force bash /tmp/agent-skills-install.sh

# 6. 重新开始任务
```
