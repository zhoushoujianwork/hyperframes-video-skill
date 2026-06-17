# 克隆你的音色（拿到 `MMX_VOICE_ID`）

用户想用**自己的声音**配音时，先克隆一次拿到一个 `voice_id`，之后所有视频复用同一个。脚本：`scripts/voice-clone.sh`。

- **只支持 MiniMax**。豆包（火山）那条线不做——要单独开通服务权限，太重，没必要。
- `mmx` 这个 CLI 只做**合成**，不带克隆子命令。所以克隆直接打 MiniMax 官方 API。
- 脚本**默认复用 mmx 的凭据**（`~/.mmx/config.json` 的 `api_key` + `region`），一般不用再单独配 key。

## 实测环境（2026-06，已验证）

- `region=cn → https://api.minimaxi.com`；`region=global → https://api.minimax.io`。
- 鉴权：`Authorization: Bearer <mmx api_key>`，**不需要 GroupId**（minimaxi.com 全局平台用纯 Bearer）。
- `mmx` 内部确认无 `voice_clone`/`files/upload`/`GroupId`，证实它不做克隆。

## 第一步：先看有没有现成的（init 优先复用）

很多时候账号里已经有克隆好的音色，直接复用即可，别重复克隆：

```bash
bash "$SKILL_DIR/scripts/voice-clone.sh" list
```

输出例（本机实测）：

```text
[clone] 已克隆音色（host=https://api.minimaxi.com region=cn）：
    MyVoice20260101   (created 2026-01-01 )
    ...
```

挑一个复用：

```bash
export MMX_VOICE_ID=<上面某个 voice_id>
```

## 第二步：克隆一个新音色（没有现成的才做）

样本要求：单人、干净无背景音、约 10s–5min、`mp3`/`m4a`/`wav`、≤20MB，读一段自然语流即可。

```bash
bash "$SKILL_DIR/scripts/voice-clone.sh" my-voice-sample.mp3
# 成功后打印 voice_id（默认按样本名生成，也可传第二个参数自定义）
export MMX_VOICE_ID=<打印出来的 voice_id>
```

脚本流程：上传样本 → 拿 `file_id` → `voice_clone` 绑定一个 `voice_id`。
`voice_id` 命名约束（MiniMax 强制）：字母开头、只含字母数字、至少一个数字、长度 ≥ 8；不传则按样本名自动生成一个合规 id。

## 凭据覆盖（可选）

默认读 `~/.mmx/config.json`；要用别的账号/区域时用环境变量覆盖：

```bash
export MINIMAX_API_KEY=...      # 不设则读 mmx config 的 api_key
export MINIMAX_REGION=cn        # cn | global，不设则读 config（默认 cn）
export MINIMAX_API_HOST=...     # 直接覆盖 host
```

## 故障排查

- 克隆/上传失败时脚本会**回显服务端原始响应**，照 `base_resp.status_msg` 调整。
- 常见原因：样本时长/格式不合规、`voice_id` 命名不符、额度未开通。
- 拿到 `MMX_VOICE_ID` 后写进 shell 配置长期复用；没配 / 不想克隆 → 跳过，配音会自动回退系统 TTS（见 SKILL.md §4）。
