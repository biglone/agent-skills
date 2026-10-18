---
name: frp-ssh-access
description: Configure and verify SSH access to a Raspberry Pi or Linux host through an existing FRP STCP tunnel, including visitor setup on another computer. Use when the user asks to set up or troubleshoot this private FRP-to-SSH path.
allowed-tools: Bash, Read, Write, Edit, Grep
related-skills: bug-finder, security-audit
---

# FRP SSH 接入助手

通过 FRP 的 STCP 私有隧道，让客户端电脑安全地 SSH 访问树莓派或其他 Linux 主机。优先复用已运行的 STCP 服务端代理，在需要访问的电脑上配置 FRP visitor 和 SSH 别名；不要为了完成访问而把 SSH 原始端口直接暴露到公网。

## 先检查现状

- 确认客户端和目标设备的操作系统、CPU 架构、FRP 版本、SSH 用户名、隧道类型和当前端口。
- 检查现有 SSH 别名、FRP 配置、进程或服务、端口占用和目标主机可达性。把配置里的现有值当作线索，先验证再使用。
- 如果目标设备的 STCP 服务端代理已经运行，通常只需在新客户端配置 visitor 和 SSH；除非检查发现服务端有问题，不要改动目标设备或 FRP 服务器。
- 保留无关配置。修改现有文件前先备份，并只增添本任务需要的内容。

## 保护凭据和 SSH 身份

- FRP token、STCP 密钥和 SSH 私钥均为凭据。只在必要时读取，不要输出到聊天、日志、截图、仓库或命令历史。
- 优先通过已认证的 SSH/SCP 通道传输可用的 visitor 配置。如果无法安全取得凭据文件，请说明如何安全放置文件；不要让用户把密钥粘贴到聊天中。
- FRP 配置目录和配置文件应限制为当前用户可访问；在支持权限位的系统上将配置文件设为 `600`。
- 不要把其他电脑的私钥复制过来。使用当前电脑已有且已授权的密钥，或新建密钥并只授权其公钥。
- 保持 SSH 主机密钥校验开启。不要设置 `StrictHostKeyChecking no`。

## 配置 FRP visitor 和 SSH

1. 从现有配置确认 FRP 服务地址、认证方式、代理名、STCP 密钥及 visitor 参数；不要猜测或重置这些值。
2. 安装与客户端操作系统和 CPU 架构匹配、且与现有服务端兼容的 FRP 客户端。下载时优先查阅 FRP 上游发布说明并核对来源。
3. 让 visitor 只绑定本机回环地址 `127.0.0.1`。优先沿用配置的本地端口；若端口已占用，选择空闲端口，并同时更新 visitor 和 SSH 别名。不要停止无关程序。
4. 启动 visitor，确认日志表明 FRP 登录成功且 visitor 已启动。排查日志时确保不打印凭据。
5. 新增专用 SSH 别名，例如 `pi-frp`，将主机指向 `127.0.0.1`，端口指向 visitor 端口，用户名设为目标 Linux 账户，并指定本机 SSH 私钥。
6. 仅在用户需要登录后或开机自动连接时，配置适合当前系统的常驻启动方式（如 macOS LaunchAgent、Linux systemd 服务或 Windows 任务）。记录服务状态和日志查看方法。

## 验证和报告

- 分两层验证：先确认 visitor 正常连接，再通过 SSH 别名确认实际到达预期主机和账户。不要只凭 FRP 登录成功就声称 SSH 已经可用。
- 区分隧道连通问题、SSH 公钥未授权和主机密钥不匹配，并给出对应的最小修复步骤。
- 如果需要首次确认主机密钥，使用可信方式核对指纹；不要关闭校验来绕过提示。
- 最后用简短中文说明配置变更、SSH 命令、自动启动状态、验证结果，以及仍需用户完成的授权步骤。
- 如果缺少必要凭据、网络连接或管理员权限，停在该边界并说明具体下一步，不要不断重试或暴露秘密。
