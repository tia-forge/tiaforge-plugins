#!/usr/bin/env sh
# 重打 zip/ —— 每个技能一个 zip，内容 = 该技能目录下的 SKILL.md（+ scripts/，如有）。
# 文件名带版本号：<slug>-<version>.zip，版本读自 SKILL.md 的 front-matter。
#
# 为什么要单独打：WorkBuddy 桌面端「上传技能」只吃 zip（市场走不通时的免市场路径），
# 而 zip/ 以前是手工打的 → 一路停在 1.0.2，比 SkillHub 上的版本落后十几个改动。
#
# 用法：
#   sh zip-skills.sh          # 按当前 plugins/tiaforge/skills/ 重打，顺手删掉旧版本的 zip
#
# 前置：先 sh sync-skills.sh（本脚本只打包，不同步）。
# 依赖：优先用系统 zip；没有的话（Git Bash 常缺）退回 python3 的 zipfile。
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$HERE/plugins/tiaforge/skills"
OUT="$HERE/zip"

PY=""
# 注意：Windows 的 `python3` 常是应用商店的假桩（跑起来直接退出 49），所以必须试跑一次
for cand in python3 python py; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'pass' >/dev/null 2>&1; then PY="$cand"; break; fi
done

mkdir -p "$OUT"
rm -f "$OUT"/*.zip

for d in "$SRC"/*/; do
  slug=$(basename "$d")
  ver=$(sed -n 's/^version:[[:space:]]*\([0-9.]*\).*/\1/p' "$d/SKILL.md" | head -1)
  if [ -z "$ver" ]; then
    echo "跳过 $slug：SKILL.md 里读不到 version:" >&2
    continue
  fi
  ( cd "$d" && find . -name '.DS_Store' -delete 2>/dev/null ) || true
  TARGET="$OUT/$slug-$ver.zip"
  if command -v zip >/dev/null 2>&1; then
    ( cd "$d" && zip -q -X "$TARGET" SKILL.md $( [ -d scripts ] && find scripts -type f ) )
  elif [ -n "$PY" ]; then
    "$PY" - "$d" "$TARGET" <<'EOF'
import os, sys, zipfile
src, target = sys.argv[1], sys.argv[2]
names = ["SKILL.md"]
if os.path.isdir(os.path.join(src, "scripts")):
    for root, _dirs, files in os.walk(os.path.join(src, "scripts")):
        for f in files:
            names.append(os.path.relpath(os.path.join(root, f), src).replace(os.sep, "/"))
with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as z:
    for n in names:
        z.write(os.path.join(src, n), n)
EOF
  else
    echo "既没有 zip 也没有 python，无法打包" >&2; exit 1
  fi
  echo "zipped $slug-$ver.zip"
done

echo "done -> $OUT"
ls -1 "$OUT"
