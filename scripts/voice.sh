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
#   MMX_VOICE_ID   克隆声 ID（设了才用 MMX）
#   VOICE_EMOTION  默认 happy
#   VOICE_SPEED    默认 1.12
set -euo pipefail

TXT="${1:?usage: voice.sh <narration.txt> <out.mp3>}"
OUT="${2:?usage: voice.sh <narration.txt> <out.mp3>}"
EMOTION="${VOICE_EMOTION:-happy}"
SPEED="${VOICE_SPEED:-1.12}"
SRT="${OUT%.*}.srt"

mkdir -p "$(dirname "$OUT")"

have() { command -v "$1" >/dev/null 2>&1; }

to_mp3() { # <in_audio> <out_mp3>
  if have ffmpeg; then ffmpeg -y -loglevel error -i "$1" "$2"; else cp "$1" "$2"; fi
}

# --- 1) MMX 克隆声 ---
if have mmx && [ -n "${MMX_VOICE_ID:-}" ]; then
  echo "[voice] MMX 克隆声: $MMX_VOICE_ID (emotion=$EMOTION speed=$SPEED)"
  mmx speech synthesize --voice "$MMX_VOICE_ID" --text-file "$TXT" \
    --subtitles --emotion "$EMOTION" --speed "$SPEED" --language Chinese \
    --format mp3 --out "$OUT"
  echo "[voice] done -> $OUT (+ $SRT)"
  exit 0
fi

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

# 回退路径尽量补 SRT（hyperframes transcribe 可用则用）
if have npx; then
  npx --yes hyperframes transcribe "$OUT" --out "$SRT" >/dev/null 2>&1 \
    && echo "[voice] SRT via hyperframes transcribe -> $SRT" \
    || echo "[voice] 提示：未生成 SRT，可后续用 'npx hyperframes transcribe' 补。"
fi
echo "[voice] done -> $OUT"
