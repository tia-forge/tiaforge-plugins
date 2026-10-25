#!/usr/bin/env sh
# 把本目录推到 GitHub：tia-forge/tiaforge-plugins
#
# 本目录是源码（在 marketing 仓里），远端是独立仓，所以用「临时目录 + 搬运」的方式推送，
# 避免在 marketing 仓内部嵌套一个 .git。
#
# 用法：
#   sh publish.sh                 # 提交信息默认
#   sh publish.sh "feat: xxx"     # 自定义提交信息
#
# 注意：本机直连 GitHub 会被重置，必须走代理（见 marketing/AGENTS.md）。
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
STAGE="${TMPDIR:-/tmp}/tiaforge-plugins"
PROXY="${PROXY:-http://192.168.1.169:8118}"
MSG="${1:-chore: sync plugin market}"

# 1) 先把技能从 skillhub 单一真源同步进来
sh "$HERE/sync-skills.sh"

# 2) 搬到一个独立的临时仓
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -r "$HERE/." "$STAGE"/
cd "$STAGE"
rm -rf .git

git init -q -b main
git config user.name "TIA Forge"
git config user.email "support@hubwiz.com"
git add -A
git commit -q -m "$MSG" || { echo "没有变更，跳过提交"; }
git remote add origin https://github.com/tia-forge/tiaforge-plugins.git

# 3) 推（走代理）
git -c http.proxy="$PROXY" -c https.proxy="$PROXY" push -f origin main

echo
echo "✓ pushed: https://github.com/tia-forge/tiaforge-plugins"
echo "  市场地址: https://raw.githubusercontent.com/tia-forge/tiaforge-plugins/main/.codebuddy-plugin/marketplace.json"
