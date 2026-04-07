---
name: github-repo-analyzer
description: 根据 GitHub 仓库 URL、`owner/repo` 或本地目录路径分析项目用途、技术栈、目录结构、核心模块、运行/数据流和学习路径。Use when users ask to understand an unfamiliar codebase, learn a repository's architecture or design ideas, explain a GitHub repo from its URL, analyze a local project folder, or produce an onboarding-style project analysis report.
---

# GitHub 仓库架构分析

用于“给我一个 GitHub 仓库地址或本地项目目录，帮我讲清楚这个项目是做什么的、架构怎么分层、模块如何协作、应该从哪里开始学”这类任务。

默认目标是 **读懂项目**，不是修改项目。

## 适用场景

- 用户提供 GitHub 仓库 URL，希望快速理解项目
- 用户提供本地目录路径，希望快速理解当前项目
- 用户想学习某个开源项目的架构或设计思路
- 用户需要输出项目导读、架构说明、模块职责清单
- 用户希望得到“从哪里开始读源码”的学习顺序

## 默认原则

- 默认只做 **只读分析**
- 默认 **不安装依赖、不运行项目、不执行仓库脚本**
- 默认优先阅读：
  - `README*`
  - 根目录 manifest / build 文件
  - 入口文件
  - `docs/`
  - CI / Docker / 部署配置
- 对大型仓库优先给出高层架构，不做逐文件解释

如果用户明确要求运行、测试或验证行为，再单独执行。

## 推荐流程

### 1. 先做仓库快照

先运行仓库快照脚本：

```bash
python3 skills/github-repo-analyzer/scripts/repo_snapshot.py \
  --repo https://github.com/owner/repo \
  --max-depth 4 \
  --max-files 200 \
  --format markdown
```

支持输入：

- `https://github.com/owner/repo`
- `owner/repo`
- `owner/repo@branch`
- 本地目录路径

### 2. 再打开关键文件

基于快照结果，优先打开：

1. `README*`
2. 根目录依赖与构建文件，例如：
   - `package.json`
   - `pyproject.toml`
   - `requirements.txt`
   - `go.mod`
   - `Cargo.toml`
   - `pom.xml`
   - `build.gradle*`
3. 入口文件与主模块
4. `docs/` 或架构文档
5. `.github/workflows/`、`Dockerfile`、`docker-compose.yml`

### 3. 输出分析时至少覆盖这些问题

- 这个项目解决什么问题
- 技术栈是什么
- 是单体、库、CLI、服务、前后端分离，还是 monorepo
- 顶层目录各自负责什么
- 主要运行入口在哪里
- 请求流 / 数据流 / 任务流如何走
- 测试、构建、发布链路如何组织
- 如果要学习，应该按什么顺序读

## 建议输出结构

```markdown
# 仓库分析报告

## 1. 项目定位
- 仓库地址：
- 主要用途：
- 目标用户：

## 2. 技术栈
- 语言：
- 框架：
- 构建/包管理：
- 部署/CI：

## 3. 顶层结构
| 路径 | 职责 |
|------|------|

## 4. 架构分层
- 表现层：
- 接口层：
- 业务层：
- 数据层：
- 基础设施层：

## 5. 核心模块
- 模块名：
  - 职责：
  - 关键文件：
  - 与其他模块关系：

## 6. 运行流程
- 启动入口：
- 关键调用链：
- 数据流：

## 7. 工程化
- 如何构建：
- 如何测试：
- 如何发布/部署：

## 8. 学习路径
1. 先读：
2. 再读：
3. 最后读：

## 9. 设计亮点与可借鉴思路
- 

## 10. 未解问题 / 建议继续深挖
- 
```

## 分析策略

### 小型仓库

- 可以覆盖更多关键文件
- 适合输出“从入口到实现”的线性讲解

### 中大型仓库

- 先做模块级拆解
- 每层只抓 3–8 个关键目录/文件
- 明确哪些结论是“根据目录与配置推断”

### Monorepo

- 先识别 workspace / app / package 边界
- 区分：
  - 应用层
  - 共享包
  - 基础设施
  - 工具链
- 如果用户没指定重点，先分析主应用和共享核心包

## 安全要求

- 不要执行仓库里的安装脚本、构建脚本或未知二进制
- 不要默认运行 `npm install`、`pip install -r requirements.txt`、`cargo build`、`go test ./...`
- 对不可信仓库，优先通过文本和配置分析得出结论
- 如果必须运行代码验证，先明确告知风险并缩小执行范围

## 常用补充命令

```bash
git -C /path/to/repo log --oneline -n 10
rg --files /path/to/repo | sed -n '1,200p'
find /path/to/repo -maxdepth 2 -type f | sed -n '1,200p'
```

## 输出风格要求

- 优先讲“结构和关系”，不要堆文件名
- 明确区分“事实”与“推断”
- 面向学习者，解释为什么这样分层、这样组织
- 如果仓库很大，主动给出“建议先读哪些文件”
