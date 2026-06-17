# CLAUDE.md

本仓库是**开源 skill**（公开发布）。在这里改任何东西，默认会被别人看到。

## 提交前必做：检查提交内容（开源仓库红线）

每次 `git add` / commit **之前**，必须扫一遍将要提交的内容，确认没有泄漏。绝不提交：

- **凭据/密钥**：API key（如 `sk-cp-…`）、token、`access_token`、cookie 值、`cookies.json`、密码。
  - 注意：脚本/文档里出现 `access_token`、`cookie_info`、`SESSDATA` 等**字段名**是允许的（讲格式），但**真实的值**绝不能进。
- **账号特定标识**：真实 `voice_id`、真实 `MMX_VOICE_ID`、GroupId、BV 号、用户名/他人姓名等——文档示例一律用占位符（如 `MyVoice20260101`、`<voice_id>`）。
- **本机绝对路径**：`/Users/<name>/…` 等，用 `$HOME`、`$SKILL_DIR`、相对路径代替。
- **视频/音频产物**：`*.mp4`/`*.mov`/`assets/*.mp3`/`*.srt`/抽帧/封面——已在 `.gitignore`，且产物本就该落 `~/Downloads/hf-video/<项目名>/`（见 SKILL.md §2），不进仓库。

建议的自查命令（提交前跑）：

```bash
git diff --staged
grep -rniE "sk-[a-z]+-|SESSDATA=|access_token\"\s*:\s*\"[A-Za-z0-9]|/Users/[a-z]" <改动文件>
```

发现疑似敏感内容先停下来确认，别直接提交。

## 凭据从哪来（不要硬编码）

- MiniMax/mmx 凭据运行时读 `~/.mmx/config.json` 或环境变量（`MINIMAX_API_KEY` 等），脚本里**不写死**。
- B站 cookie 走 `BILIUP_COOKIE` 环境变量指向本机文件，不入库。
