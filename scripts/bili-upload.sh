#!/usr/bin/env bash
# bili-upload.sh — 用 CLI(bilitool) 把成片 + 封面传到 B站并尝试提交投稿。
#
#   bash bili-upload.sh <video.mp4> <cover.png> "<title>" <tid> "<tag1,tag2,...>" [desc-file]
#
# ──────────────────────────────────────────────────────────────────────────
# 现状提醒（实测 2026-06）：B站已封禁第三方「提交稿件」接口。
#   biliup / bilitool 都能把**视频字节和封面成功传上 B站**，但最后「创建稿件」
#   会被拒：biliup → `21150 投稿入口升级中`；bilitool → `投稿工具已停用`。
#   换别的第三方工具一样被拦——这是 B站策略，不是工具 bug。
#   ⇒ 本脚本用于：① 快速校验登录态/上传链路；② B站若恢复接口即可直接用。
#   ⇒ **最终投稿仍以浏览器创作中心为准**（见 SKILL.md 第 7 节「Browser Upload」）。
# ──────────────────────────────────────────────────────────────────────────
#
# 登录（二选一）：
#   A) 复用 biliup 已登录的 cookie：设 BILIUP_COOKIE=/path/to/cookies.json，
#      脚本自动转成 bilitool 格式并登录（无需再扫码）。
#   B) 直接 `bilitool login`（扫码，需真实终端 TTY）。
#
# tid（分区）参考 https://bilitool.timerring.com/tid.html，例：174=野生技术协会。
set -euo pipefail

VID="${1:?usage: bili-upload.sh <video> <cover> <title> <tid> <tags> [desc-file]}"
COVER="${2:?need cover image}"
TITLE="${3:?need title}"
TID="${4:?need tid 分区}"
TAGS="${5:?need tags 逗号分隔}"
DESC_FILE="${6:-}"
DESC="$([ -n "$DESC_FILE" ] && cat "$DESC_FILE" || echo "")"

have() { command -v "$1" >/dev/null 2>&1; }

# --- 确保 bilitool ---
BILITOOL="$(command -v bilitool || echo "$HOME/Library/Python/3.9/bin/bilitool")"
if [ ! -x "$BILITOOL" ]; then
  echo "[bili] 安装 bilitool ..."
  python3 -m pip install --user --quiet bilitool
  BILITOOL="$(command -v bilitool || echo "$HOME/Library/Python/3.9/bin/bilitool")"
fi

# --- 登录：优先复用 biliup cookie ---
if ! "$BILITOOL" check 2>/dev/null | grep -q "Current account"; then
  if [ -n "${BILIUP_COOKIE:-}" ] && [ -f "$BILIUP_COOKIE" ]; then
    echo "[bili] 复用 biliup cookie 登录 ..."
    TMP_CK="$(mktemp -t bilitool-ck).json"
    python3 - "$BILIUP_COOKIE" "$TMP_CK" <<'PY'
import json, sys
b = json.load(open(sys.argv[1]))
# bilitool 期望 data.access_token + data.cookie_info.cookies[0..4]
out = {"data": {"access_token": b["token_info"]["access_token"],
                "cookie_info": b["cookie_info"]}}
json.dump(out, open(sys.argv[2], "w"))
PY
    "$BILITOOL" login -f "$TMP_CK"
    rm -f "$TMP_CK"
  else
    echo "[bili] 未登录。请先在终端跑 'bilitool login' 扫码，或设 BILIUP_COOKIE 复用 biliup 登录。" >&2
    exit 1
  fi
fi

# --- 上传 + 提交 ---
echo "[bili] 上传：$TITLE"
set +e
OUT="$("$BILITOOL" upload "$VID" \
  --copyright 1 --title "$TITLE" --desc "$DESC" \
  --tid "$TID" --tag "$TAGS" --cover "$COVER" 2>&1)"
code=$?
set -e
echo "$OUT" | grep -viE "NotOpenSSL|warnings.warn"

if echo "$OUT" | grep -qiE "投稿工具已停用|投稿入口升级|21150"; then
  echo ""
  echo "[bili] ⚠ 视频/封面已传上 B站，但**提交稿件被 B站拦截**（第三方提交接口已封）。"
  echo "[bili] ⇒ 改用浏览器创作中心完成最后投稿：https://member.bilibili.com/platform/upload/video/frame"
  echo "[bili]   （元数据见 publish-draft.md；封面用本脚本同一张）"
  exit 2
fi
[ $code -eq 0 ] && echo "[bili] done." || exit $code
