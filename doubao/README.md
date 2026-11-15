# 豆包（豆包工作）→ 已独立成仓

豆包的插件包、发布与说明**搬到了独立仓库**，便于推广时直接给地址：

👉 **<https://github.com/tia-forge/doubao-tiaforge>**

下载插件包（6 技能 + 5 连接）：

```
https://github.com/tia-forge/doubao-tiaforge/releases/download/v1.0.5/tiaforge-doubao-plugin-1.0.5.zip
```

## 为什么分仓

- 豆包的读者群与本仓（DSH / WorkBuddy / pi / Claude Code）不同，README 首屏各说各的；
- 版本节奏不同（豆包按插件包整体发版，本仓按技能同步）；
- 推广时要一个能直接贴出去的地址。

## 技能正文仍在哪

技能正文的**单一真源**依旧在本仓（`distribution/skillhub/*` → `sync-skills.sh` 同步到各客户端）。
豆包仓里的 `plugin/skills/*` 是打包副本；技能改动后需要重新打 zip 并 bump 版本（`plugin.json` 的 `version` 与资源包名同步）。
