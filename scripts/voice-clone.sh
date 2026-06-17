#!/usr/bin/env bash
# voice-clone.sh — 克隆你自己的音色 / 列出已克隆音色，拿到 voice_id。
#
#   bash voice-clone.sh list                      # 列出账号里已克隆的音色（先看有没有现成的）
#   bash voice-clone.sh <人声样本.mp3> [voice_id]  # 用样本克隆一个新音色
#
# 背景：mmx 这个 CLI 只做**合成**，不带克隆。克隆直接打 MiniMax 官方 API，
# 且**默认复用 mmx 的凭据**（~/.mmx/config.json 的 api_key + region），
# 所以一般不用再单独配 key。拿到的 voice_id 就是 voice.sh / mmx 用的 MMX_VOICE_ID。
#
# 只支持 MiniMax。豆包（火山）不做——要单独开通服务权限，太重。
#
# 凭据来源（优先级：环境变量 > ~/.mmx/config.json）：
#   MINIMAX_API_KEY   不设则读 ~/.mmx/config.json 的 api_key
#   MINIMAX_REGION    cn | global，不设则读 config 的 region（默认 cn）
#   MINIMAX_API_HOST  直接覆盖 host（cn→https://api.minimaxi.com，global→https://api.minimax.io）
#
# 实测（2026-06）：minimaxi.com 用纯 Bearer 鉴权，**不需要 GroupId**。
#
# 样本要求：单人、干净无背景音、约 10s–5min、mp3/m4a/wav、≤20MB。
# voice_id 命名（MiniMax 强制）：字母开头、只含字母数字、至少一个数字、长度 ≥ 8。
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
have curl || { echo "[clone] 需要 curl" >&2; exit 1; }

CFG="$HOME/.mmx/config.json"
cfg() { [ -f "$CFG" ] && python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get(sys.argv[2],""))' "$CFG" "$1" 2>/dev/null || true; }

API_KEY="${MINIMAX_API_KEY:-$(cfg api_key)}"
REGION="${MINIMAX_REGION:-$(cfg region)}"; REGION="${REGION:-cn}"
[ -n "$API_KEY" ] || { echo "[clone] 没有 api_key：设 MINIMAX_API_KEY 或先配置 mmx（~/.mmx/config.json）" >&2; exit 1; }
case "$REGION" in
  global) HOST="${MINIMAX_API_HOST:-https://api.minimax.io}" ;;
  *)      HOST="${MINIMAX_API_HOST:-https://api.minimaxi.com}" ;;
esac

# 取 JSON 字段（优先 jq，回退 python3）
jget() { if have jq; then printf '%s' "$1" | jq -r ".$2 // empty"
  else printf '%s' "$1" | python3 -c 'import sys,json
d=json.load(sys.stdin)
for k in sys.argv[1].split("."):
    d=d.get(k) if isinstance(d,dict) else None
    if d is None: break
print(d if d is not None else "")' "$2"; fi; }

# --- list：列出已克隆音色 ---
if [ "${1:-}" = "list" ]; then
  R="$(curl -sS -m 20 -X POST "$HOST/v1/get_voice" \
    -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
    -d '{"voice_type":"all"}')"
  [ "$(jget "$R" base_resp.status_code)" = "0" ] || { echo "[clone] 查询失败：$R" >&2; exit 1; }
  echo "[clone] 已克隆音色（host=$HOST region=$REGION）："
  printf '%s' "$R" | python3 -c 'import sys,json
for v in json.load(sys.stdin).get("voice_cloning",[]):
    print("   ",v.get("voice_id"),"  (created",v.get("created_time"),")")'
  echo "[clone] 复用某个：export MMX_VOICE_ID=<上面的 voice_id>"
  exit 0
fi

# --- 克隆新音色 ---
SAMPLE="${1:?usage: voice-clone.sh list | voice-clone.sh <样本.mp3> [voice_id]}"
[ -f "$SAMPLE" ] || { echo "[clone] 找不到样本：$SAMPLE" >&2; exit 1; }

if [ -n "${2:-}" ]; then VOICE_ID="$2"; else
  base="$(basename "${SAMPLE%.*}" | tr -cd 'a-zA-Z0-9')"; [ -n "$base" ] || base="voice"
  case "$base" in [a-zA-Z]*) ;; *) base="v$base" ;; esac
  VOICE_ID="${base}clone1"
fi
echo "[clone] host=$HOST  voice_id=$VOICE_ID"

# 1) 上传样本，拿 file_id
echo "[clone] 上传样本：$SAMPLE"
UP="$(curl -sS -m 60 -X POST "$HOST/v1/files/upload" \
  -H "Authorization: Bearer $API_KEY" \
  -F purpose=voice_clone -F "file=@$SAMPLE")"
FILE_ID="$(jget "$UP" file.file_id)"
[ -n "$FILE_ID" ] || { echo "[clone] 上传失败，服务端返回：" >&2; echo "$UP" >&2; exit 1; }
echo "[clone] file_id=$FILE_ID"

# 2) 克隆，绑定 voice_id
echo "[clone] 克隆中 ..."
CL="$(curl -sS -m 60 -X POST "$HOST/v1/voice_clone" \
  -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
  -d "{\"file_id\":$FILE_ID,\"voice_id\":\"$VOICE_ID\"}")"
[ "$(jget "$CL" base_resp.status_code)" = "0" ] || {
  echo "[clone] 克隆失败，服务端返回：" >&2; echo "$CL" >&2
  echo "[clone] 常见原因：样本时长/格式不合规、voice_id 命名不符、额度未开通。" >&2; exit 1; }

echo ""
echo "[clone] ✅ 克隆成功！音色 ID：$VOICE_ID"
echo "[clone] 复用：export MMX_VOICE_ID=$VOICE_ID"
