#!/usr/bin/env sh
# 把 SkillHub 上架的四个技能同步进插件包，并把埋点改成 workbuddy 渠道。
# 单一真源：distribution/skillhub/<slug>/SKILL.md
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$HERE/../skillhub"
DST="$HERE/plugins/tiaforge/skills"

for slug in tialink-tia-portal plc-cloud-sim laddoc-cloud tia-portal-docs; do
  mkdir -p "$DST/$slug"
  sed -e 's/utm_source=skillhub/utm_source=workbuddy-plugin/g' \
      -e 's/utm_medium=skill/utm_medium=plugin/g' \
      "$SRC/$slug/SKILL.md" > "$DST/$slug/SKILL.md"
  # 同步技能自带的辅助文件（如有）
  if [ -d "$SRC/$slug/scripts" ]; then
    mkdir -p "$DST/$slug/scripts"
    cp -r "$SRC/$slug/scripts/." "$DST/$slug/scripts/"
  fi
  echo "synced $slug"
done

echo "done -> $DST"

# ② DSH 插件包内的技能副本（埋点改成 dsh）
DSH="$HERE/dsh-plugin/skills"
for slug in tialink-tia-portal plc-cloud-sim laddoc-cloud tia-portal-docs; do
  mkdir -p "$DSH/$slug"
  sed -e 's/utm_source=skillhub/utm_source=dsh/g' \
      -e 's/utm_medium=skill/utm_medium=plugin/g' \
      "$SRC/$slug/SKILL.md" > "$DSH/$slug/SKILL.md"
  if [ -d "$SRC/$slug/scripts" ]; then
    mkdir -p "$DSH/$slug/scripts"
    cp -r "$SRC/$slug/scripts/." "$DSH/$slug/scripts/"
  fi
  echo "synced dsh $slug"
done
