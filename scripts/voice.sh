#!/usr/bin/env bash
# voice.sh — 生成配音，带音色克隆 + 系统 TTS 回退
#
#   bash voice.sh <narration.txt> <out.mp3>
#
# 探测顺序：
#   1) MMX/MiniMax 克隆声：需要 `mmx` 在 PATH 且设了环境变量 MMX_VOICE_ID
#   2) 回退系统 TTS：macOS `say` / Linux `espeak-ng`|`espeak`
#
# 可选环境变量：
#   MMX_VOICE_ID        克隆声 ID（设了才用 MMX）
#   VOICE_EMOTION       默认 happy
#   VOICE_SPEED         默认 1.12
#   VOICE_SAMPLE_RATE   默认 44100（见下方说明：避免拼接上采样杂音）
set -euo pipefail

TXT="${1:?usage: voice.sh <narration.txt> <out.mp3>}"
OUT="${2:?usage: voice.sh <narration.txt> <out.mp3>}"
EMOTION="${VOICE_EMOTION:-happy}"
SPEED="${VOICE_SPEED:-1.12}"
# 默认 44100：成片要拼片头/片尾时，三段音频须同采样率零重采样，
# 否则配音 32k 上采样到 48k 会产生杂音。MiniMax 支持 44100、不支持 48000。
SAMPLE_RATE="${VOICE_SAMPLE_RATE:-44100}"
SRT="${OUT%.*}.srt"

mkdir -p "$(dirname "$OUT")"

have() { command -v "$1" >/dev/null 2>&1; }

to_mp3() { # <in_audio> <out_mp3>
  if have ffmpeg; then ffmpeg -y -loglevel error -i "$1" "$2"; else cp "$1" "$2"; fi
}

# --- 1) MMX 克隆声 ---
if have mmx && [ -n "${MMX_VOICE_ID:-}" ]; then
  echo "[voice] MMX 克隆声: $MMX_VOICE_ID (emotion=$EMOTION speed=$SPEED rate=$SAMPLE_RATE)"
  mmx speech synthesize --voice "$MMX_VOICE_ID" --text-file "$TXT" \
    --emotion "$EMOTION" --speed "$SPEED" --language Chinese \
    --sample-rate "$SAMPLE_RATE" --format mp3 --out "$OUT"
else
  # --- 2) 回退系统 TTS ---
  echo "[voice] 未配置 MMX_VOICE_ID/mmx，回退系统 TTS"
  TMP="$(mktemp -t voice).aiff"
  if have say; then            # macOS
    say -f "$TXT" -o "$TMP"
    to_mp3 "$TMP" "$OUT"; rm -f "$TMP"
  elif have espeak-ng || have espeak; then   # Linux
    ESPEAK="$(command -v espeak-ng || command -v espeak)"
    TMPWAV="$(mktemp -t voice).wav"
    "$ESPEAK" -v zh -s 170 -f "$TXT" -w "$TMPWAV"
    to_mp3 "$TMPWAV" "$OUT"; rm -f "$TMPWAV"
  else
    echo "[voice] 错误：没有 mmx，也没有 say/espeak。装 espeak-ng 或配置 MMX_VOICE_ID。" >&2
    exit 1
  fi
fi

# --- 字幕 SRT（两条路径通用）---
# 注意：mmx 的 --subtitles 只把字幕塞进 JSON 响应、不落地 .srt 文件，
# 所以无论克隆声还是系统 TTS，都统一用 hyperframes transcribe 从音频生成 SRT。
if have npx; then
  npx --yes hyperframes transcribe "$OUT" --out "$SRT" >/dev/null 2>&1 \
    && echo "[voice] SRT -> $SRT" \
    || echo "[voice] 提示：未生成 SRT，可后续用 'npx hyperframes transcribe' 补。"
fi
echo "[voice] done -> $OUT"
