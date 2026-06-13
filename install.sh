#!/usr/bin/env bash
# install.sh — 一键安装 bilibili-product-video skill 到 Claude Code 和 Codex。
#
#   curl -fsSL https://raw.githubusercontent.com/zhoushoujianwork/hyperframes-video-skill/main/install.sh | bash
#   # 或在仓库内： bash install.sh
#
# 策略：克隆一份到「主目录」（claude 优先），另一端用 symlink 指过去——
#       这样 git pull 一次，claude 与 codex 两端同时最新（也是 skill 自更新的基础）。
set -euo pipefail

REPO="https://github.com/zhoushoujianwork/hyperframes-video-skill.git"
SKILL="bilibili-product-video"
CLAUDE="$HOME/.claude/skills"
CODEX="$HOME/.codex/skills"

backup() { [ -e "$1" ] && [ ! -L "$1" ] && mv "$1" "$1.bak.$(date +%s 2>/dev/null || echo old)" && echo "  备份旧目录 -> $1.bak.*"; }

# 选主目录：claude 优先；claude 不存在则用 codex
if [ -d "$HOME/.claude" ] || [ ! -d "$HOME/.codex" ]; then
  PRIMARY_ROOT="$CLAUDE"; OTHER_ROOT="$CODEX"
else
  PRIMARY_ROOT="$CODEX"; OTHER_ROOT="$CLAUDE"
fi
PRIMARY="$PRIMARY_ROOT/$SKILL"

mkdir -p "$PRIMARY_ROOT"
if [ -d "$PRIMARY/.git" ]; then
  echo "更新 skill（主目录 $PRIMARY）..."
  git -C "$PRIMARY" pull --ff-only
else
  backup "$PRIMARY"
  echo "克隆 skill 到主目录 $PRIMARY ..."
  git clone --depth=1 "$REPO" "$PRIMARY"
fi

# 另一端：symlink 指向主克隆（拉一次两端同步）
if [ -d "$(dirname "$OTHER_ROOT")" ] || [ -d "$OTHER_ROOT" ]; then
  mkdir -p "$OTHER_ROOT"
  OTHER="$OTHER_ROOT/$SKILL"
  if [ -L "$OTHER" ]; then rm -f "$OTHER"; else backup "$OTHER"; fi
  ln -s "$PRIMARY" "$OTHER"
  echo "另一端 symlink: $OTHER -> $PRIMARY"
fi

echo
echo "✅ 安装完成。"
echo "   - 主克隆: $PRIMARY"
echo "   - 自更新: 每次使用前 skill 会 git pull（scripts/update.sh）"
echo "   - 配音:   配 MMX_VOICE_ID 用克隆声，否则回退系统 TTS"
echo "   触发: 在 Claude Code / Codex 里说「做个产品视频 / B站投稿 / bilibili-product-video」"
