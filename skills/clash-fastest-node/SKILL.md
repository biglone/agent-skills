---
name: clash-fastest-node
description: Automatically test latency and switch Clash/Mihomo selector groups to the fastest node via local external-controller API. Use whenever users ask for "一键自动选最快节点", "测速并切换", "切到最低延迟节点", "自动换节点", "clash 自动选节点", "自动选最快代理", "switch to fastest Clash node", or slow-proxy troubleshooting.
---

# Clash Fastest Node

## Overview
Use this skill to benchmark all candidates in a Clash/Mihomo selector group and switch to the lowest-latency node safely.

## Workflow
1. Ensure local controller is reachable:
   - `curl -sS http://127.0.0.1:9090/version`
2. Run bundled script:
   - `bash "$HOME/.codex/skills/clash-fastest-node/scripts/switch_fastest_node.sh" --group "🔰 选择节点"`
3. If user wants benchmark only:
   - `bash "$HOME/.codex/skills/clash-fastest-node/scripts/switch_fastest_node.sh" --group "🔰 选择节点" --dry-run`
4. If user wants current selected node only:
   - `bash "$HOME/.codex/skills/clash-fastest-node/scripts/switch_fastest_node.sh" --group "🔰 选择节点" --show-current`

## Script parameters
- `--group`: selector group name. Default `🔰 选择节点`.
- `--controller`: external-controller URL. Default `http://127.0.0.1:9090`.
- `--config`: config path used to read `secret`; auto-detected when omitted.
- `--url`: latency test URL. Default `https://www.gstatic.com/generate_204`.
- `--timeout`: delay test timeout in milliseconds. Default `6000`.
- `--dry-run`: benchmark only, do not switch.
- `--show-current`: print current node and exit.
- `--include-direct`: include `DIRECT` and `REJECT` in benchmark list.
- `--top`: print top N fastest nodes. Default `10`.

## Guardrails
- Do not edit subscription files unless user explicitly asks.
- Do not restart Clash unless user explicitly asks.
- If API/group is unavailable, list available selector groups and stop.
- If all candidates timeout, do not switch and report failure clearly.
