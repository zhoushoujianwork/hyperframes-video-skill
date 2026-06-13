#!/usr/bin/env bash
# update.sh — 每次使用 skill 前自更新到最新提交。
# skill 目录即 git 克隆；claude/codex 通过 symlink 共享同一克隆，拉一次两端同步。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"   # 解析 symlink 到真实克隆
if [ -d "$ROOT/.git" ]; then
  git -C "$ROOT" pull --ff-only --quiet 2>/dev/null \
    && echo "[update] $(git -C "$ROOT" rev-parse --short HEAD) (latest)" \
    || echo "[update] 跳过（无网络/非快进/有本地改动）"
else
  echo "[update] 非 git 安装，跳过自更新"
fi
