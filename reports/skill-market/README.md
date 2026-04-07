# Skill Market Reports

该目录用于存放本地定时任务生成的日报与审计产物。

## 目录约定

- `latest.md` / `latest.json`：最近一次运行的汇总报告
- `runs/YYYY-MM-DD/HHMMSS/`：单次运行的详细产物
- `runs/YYYY-MM-DD/HHMMSS/artifacts/`：原始扫描输出
- `runs/YYYY-MM-DD/HHMMSS/merge-previews/`：仅报告用途的 merge preview 产物，不会回写本地 skill

## 生成方式

```bash
./scripts/run-skill-market-daily-audit.sh
```

如需同时发送 Matrix 通知：

```bash
MATRIX_HOMESERVER_URL=https://matrix.example.com \
MATRIX_ACCESS_TOKEN=... \
MATRIX_ROOM_ID='!roomid:example.com' \
./scripts/run-skill-market-daily-audit.sh --notify-matrix
```

说明：

- 默认只对白名单仓库做深度审计，当前见 `scripts/manifest/skill-market-allowlist.txt`
- `scripts/manifest/market-seed-repos.txt` 中的 seed 仓库会并入发现候选池
- 默认不改动 `skills/`，只生成报告和 merge preview 建议
- 缺少 Matrix 环境变量时会自动跳过通知，不会阻断日报生成
- Matrix 通知发送的是完整报告正文，而不是摘要
