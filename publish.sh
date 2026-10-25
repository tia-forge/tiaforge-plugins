#!/usr/bin/env sh
# 把本目录推送到 GitHub：tia-forge/tiaforge-plugins
#
# 设计要点（2026-10-25 改版）：
#   早期版本每次都在临时目录 `git init` + force push，结果远端永远只有一个提交、
#   历史被反复覆盖。awesome 那类清单一类会看仓库活跃度/提交历史，所以改成
#   **持久克隆 + 普通 push**：提交逐次累积，diff 可读。
#
# 用法：
#   sh publish.sh                 # 默认提交信息
#   sh publish.sh "feat: xxx"     # 自定义提交信息
#
# 注意：本机直连 GitHub 会被重置，必须走代理（见 marketing/AGENTS.md）。
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
REPO="${TMPDIR:-/tmp}/tiaforge-plugins-repo"
PROXY="${PROXY:-http://192.168.1.169:8118}"
REMOTE="https://github.com/tia-forge/tiaforge-plugins.git"
MSG="${1:-chore: sync plugin market}"

# 1) 先把技能从 skillhub 单一真源同步进来
sh "$HERE/sync-skills.sh"

# 2) 准备持久克隆（首次 clone，之后 fetch + 快进）
if [ ! -d "$REPO/.git" ]; then
  rm -rf "$REPO"
  git -c http.proxy="$PROXY" -c https.proxy="$PROXY" clone --quiet "$REMOTE" "$REPO"
fi
cd "$REPO"
git -c http.proxy="$PROXY" -c https.proxy="$PROXY" fetch --quiet origin main
git reset --hard origin/main --quiet
git config user.name "TIA Forge"
git config user.email "support@hubwiz.com"

# 3) 把源目录镜像进来（不带 .git；保留仓库已有的 .gitattributes/.gitignore）
find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
tar -C "$HERE" --exclude .git --exclude '*.tgz' -cf - . | tar -xf -

git add -A
if git diff --cached --quiet; then
  echo "没有变更，无需提交"
else
  git commit -q -m "$MSG"
  git -c http.proxy="$PROXY" -c https.proxy="$PROXY" push origin main
  echo "✓ pushed: $(git log --oneline -1)"
fi

echo "仓库: https://github.com/tia-forge/tiaforge-plugins"
echo "市场: https://raw.githubusercontent.com/tia-forge/tiaforge-plugins/main/.codebuddy-plugin/marketplace.json"
