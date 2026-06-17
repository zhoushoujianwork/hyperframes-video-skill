# hyperframes-video-skill

把一个项目 / 工具 / 工程故事，做成**短小、形象、面向普通大众程序员**的产品视频，并协助发布到 B站。一个给 AI 编程助手（Claude Code / Codex）用的 **skill**。

> 渲染基于开源的 [HyperFrames](https://github.com/heygen-com/hyperframes)（Apache-2.0，"Write HTML. Render video. Built for agents."）。本 skill 不 fork HyperFrames，而是把它当依赖，在外层补上**故事化脚本方法论、音色克隆配音、形象动画工具箱、封面/元数据、浏览器投稿**。

## 能力

- **故事化脚本**：故事弧（痛点→翻车→解决）+ 钩子库，拒绝功能罗列；受众=普通大众程序员，不堆内部行话。
- **形态轮换**：常规故事 / 对比评测 / 翻车踩坑，破单调。
- **音色克隆配音**：配了 MMX/MiniMax 克隆声就用克隆声；**没配自动回退系统 TTS**（macOS `say` / Linux `espeak`），任何人都能出片。
- **形象动画**：HyperFrames + GSAP（DrawSVG 自绘概念图 / MotionPath 路径运动 / kinetic 砸字幕）+ 组件库 + 布局轮换 + 隐喻库。
- **封面 + 元数据 + 浏览器投稿**：点阵风格封面、标题/简介/标签、合集管理、创作中心一键上传（投稿前关键动作确认）。

## 安装（Claude Code + Codex 双端）

```bash
curl -fsSL https://raw.githubusercontent.com/zhoushoujianwork/hyperframes-video-skill/main/install.sh | bash
```

- 克隆到主目录（`~/.claude/skills/bilibili-product-video`，claude 优先），另一端（`~/.codex/skills/`）用 **symlink** 指过去——`git pull` 一次两端同步。
- **自更新**：每次使用前 skill 会自动 `git pull`（`scripts/update.sh`），保证本地最新。

## 依赖

| 必需 | 说明 |
|---|---|
| Node.js | `npx hyperframes`（渲染、组件库、transcribe）|
| ffmpeg | 音频转码 / 抽帧 |
| Chrome | HyperFrames 本地渲染 + 浏览器投稿 |

| 可选 | 说明 |
|---|---|
| `mmx`（MiniMax 包装 CLI）+ `MMX_VOICE_ID` | 音色克隆配音；没有则回退系统 TTS |
| `say`(macOS) / `espeak-ng`(Linux) | 系统 TTS 回退 |
| `rsvg-convert` | SVG 封面转 PNG |

## 配音（音色克隆 / 回退）

合成配音：

```bash
bash scripts/voice.sh narration.txt assets/voice.mp3
```

环境变量：`MMX_VOICE_ID`（设了才用克隆声）、`VOICE_EMOTION`(默认 happy)、`VOICE_SPEED`(默认 1.12)。

### 想用自己的声音？先初始化一次音色（可选）

声音走 `MMX_VOICE_ID`。装了 `mmx` 的话，克隆脚本**默认复用 `~/.mmx/config.json` 的凭据**，不用再单独配 key。只支持 MiniMax（豆包不做，要单独开权限）。

```bash
# 1) 先看账号里有没有现成的克隆音色，有就直接复用
bash scripts/voice-clone.sh list
export MMX_VOICE_ID=<上面某个 voice_id>

# 2) 没有现成的，才克隆一个（录一段 10s–5min 干净人声：mp3/m4a/wav）
bash scripts/voice-clone.sh my-voice.mp3
export MMX_VOICE_ID=<打印出来的 voice_id>
```

把 `export MMX_VOICE_ID=...` 写进 `~/.zshrc` 即长期复用。**没装 mmx / 不想克隆** → 跳过本节，配音自动回退系统 TTS。完整说明见 [`references/voice-clone.md`](references/voice-clone.md)。

> 产物落 `~/Downloads/hf-video/<项目名>/<episode>/`，不写进你的项目仓库。

## 用法

装好后，在 Claude Code / Codex 里说：「帮我做个产品视频 / B站投稿 / bilibili-product-video」。skill 会带你走：理解产品 → 脚本 → 配音 → HyperFrames 成片 → 封面/元数据 → 协助投稿。

## License

Apache-2.0（与 HyperFrames 一致）。
