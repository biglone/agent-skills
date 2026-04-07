# Third-Party Notices

本仓库除自有内容外，还包含从第三方仓库审计后引入的 skill 目录。

## `anthropics/skills`

- Upstream: `https://github.com/anthropics/skills`
- Audited ref: `98669c11ca63e9c81c11501e1437e5c47b556621`
- Included under retained upstream license terms:
  - `skills/algorithmic-art`
  - `skills/brand-guidelines`
  - `skills/canvas-design`
  - `skills/claude-api`
  - `skills/frontend-design`
  - `skills/internal-comms`
  - `skills/mcp-builder`
  - `skills/skill-creator`
  - `skills/slack-gif-creator`
  - `skills/theme-factory`
  - `skills/web-artifacts-builder`
  - `skills/webapp-testing`

说明：

- 上述目录保留了上游自带的 `LICENSE.txt`、字体许可或其他随目录分发的许可文件。
- 本仓库根目录 `LICENSE` 适用于仓库自有内容；上述第三方 skill 目录继续适用其各自上游许可。

## Reviewed But Not Vendored

以下候选已进入审计范围，但当前未直接纳入本仓库：

- `docx`
- `pdf`
- `pptx`
- `xlsx`

原因：

- 这 4 个目录的 `LICENSE.txt` 明确写明其为 source-available / 受 Anthropic 服务协议约束，并限制提取、复制、衍生和分发；因此不适合 vendoring 到本仓库。

另外还有：

- `doc-coauthoring`

原因：

- 在审计提交 `98669c11ca63e9c81c11501e1437e5c47b556621` 中，该目录未附带明确的目录级许可文件；为避免许可歧义，当前不纳入。
