#!/usr/bin/env sh
# 发布 dsh-tiaforge 到 npm（token 从 ~/.paseo/npmjs-key 读，不落进 ~/.npmrc）
#
# key 文件内容：一行，直接是 token 本体（npm_xxx），不要带
#   //registry.npmjs.org/:_authToken=  前缀，也不要引号。
#
# 用法：
#   sh publish-npm.sh            # 发布当前 package.json 的版本
#   sh publish-npm.sh --dry-run  # 只打包，不推送
set -eu

KEY_FILE="${NPM_KEY_FILE:-$HOME/.paseo/npmjs-key}"
[ -f "$KEY_FILE" ] || { echo "✗ 缺少 $KEY_FILE（应含一行 npm_xxx token）" >&2; exit 1; }

TOKEN=$(tr -d '\r\n' < "$KEY_FILE")
[ -n "$TOKEN" ] || { echo "✗ token 为空" >&2; exit 1; }
case "$TOKEN" in
  npm_*) ;;
  *) echo "✗ token 应以 npm_ 开头（当前: ${TOKEN%%…*}…）" >&2; exit 1 ;;
esac

TMP=$(mktemp 2>/dev/null || echo "/tmp/npmrc.$$")
printf '//registry.npmjs.org/:_authToken=%s\n' "$TOKEN" > "$TMP"
trap 'rm -f "$TMP"' EXIT

# 先用临时 userconfig 验一次身份（经典 token 支持 whoami；granular 会 401，属正常）
echo "→ 校验 token…"
if curl -s -o /dev/null -w "%{http_code}" -m 20 \
     -H "Authorization: Bearer $TOKEN" https://registry.npmjs.org/-/npm/v1/user | grep -q 200; then
  echo "  ✓ token 有效"
else
  echo "  ⚠ /-/npm/v1/user 非 200（granular token 常见），继续尝试发布"
fi

echo "→ 打包检查…"
npm pack --dry-run 2>&1 | tail -6

echo "→ 发布…"
if [ "${1:-}" = "--dry-run" ]; then
  echo "  （--dry-run：不实际推送）"
  exit 0
fi
npm publish --userconfig "$TMP" --access public

echo
echo "✓ 完成：https://www.npmjs.com/package/$(node -p "require('./package.json').name")"
