# awesome-dsh-plugin PR 提交包（2026-10-26 15:08 之后可用）

## 0. 时间门槛

仓库 `tia-forge/tiaforge-plugins` 创建于 **2026-10-25T07:08Z**。
规则要求 *"The repo is at least 1 day old"*，由 CI 自动检查 → **最早 2026-10-26 07:08Z（北京 15:08）**。

## 1. 只有一个文件

路径（注意 monorepo 子包命名规则）：

```
data/plugins/tia-forge__tiaforge-plugins--dsh-plugin.yml
```

内容（与 `awesome-entry.yml` 相同）：

```yaml
url: https://github.com/tia-forge/tiaforge-plugins/tree/main/dsh-plugin
name: tia-forge/tiaforge-plugins#dsh-plugin
category: tools
description:
  en: Registers four TIA Portal skills (Siemens PLC docs lookup, ladder-logic generation, scan-cycle simulation with PASS/FAIL scenarios, and a local gateway that drives a real TIA Portal project) and wires the matching MCP endpoints, so an agent can go from a question to compiled, verified PLC code.
  zh: 一次装齐西门子博途（TIA Portal）的四项能力——官方文档检索、梯形图生成、逐扫描仿真与 PASS/FAIL 验收、操作真实工程的本机网关——并把对应 MCP 端点一并接好，让智能体从提问一路走到编译通过的 PLC 代码。
icon: https://raw.githubusercontent.com/tia-forge/tiaforge-plugins/main/dsh-plugin/assets/icon-180.png
```

## 2. PR 标题与正文（英文，直接用）

**Title**

```
Add tiaforge-plugins#dsh-plugin — TIA Portal (Siemens PLC) skills + MCP endpoints
```

**Body**

```markdown
Adds `tia-forge/tiaforge-plugins#dsh-plugin` (npm: `dsh-tiaforge`).

**What it ships, not just what it depends on:**
- four skill bodies in `skills/*/SKILL.md` (~40 KB of engineering checklists, wiring tables, failure triage), registered at runtime via `ctx.skills.register()` in `index.js` — no file copying, no `customSkillDirs`;
- four `@deepseek-ai/dsh-mcp-client` rows wired in one patch layer (TIA Portal docs, LadDoc→SimaticML, PLC cloud simulation, and a local gateway that drives a real TIA Portal project).
This is configuration composition + bundled content, not a meta-package of other people's plugins — it depends on no third-party plugin.

**Installability (checked per contributing.md):**
- `package.json` declares `dsh.bundle.patch = ./cordis.patch.yml` (in the `dsh-plugin/` subpackage; the repo root is a plugin-catalogue repo, hence the monorepo form);
- the patch only `insert`s new rows and overrides nothing, so it survives `dsh-base`/`web-app` upgrades;
- every MCP row sets `failOnStartupError: false` — with no gateway or API key present the profile still boots, which is the failure mode that otherwise bricks a profile.

**Verified:**
- `dsh plugin --profile desktop add dsh-tiaforge` on **dsh desktop 0.2.0-rc.2** (Windows): plugin loads, 4 MCP servers register, and with one API key the agent called `mcp__tia-docs__get_docs` twice (the second time because the first parameter table was truncated) and answered from the Siemens docs, distinguishing the LAD and FBD `TON` instructions.
- `engines.dsh` is `>=0.2.0-rc.0 <0.2.1-rc.0 || >=0.2.1-rc.0 <0.3.0` — two branches on purpose; a single branch without a prerelease tag on the matching tuple silently excludes prerelease harness builds.

Maintenance: the skill bodies are the same sources published on SkillHub, synced by `sync-skills.sh`; version bumps track the PLC tooling we actually test against.
```

## 3. 提交方式（两条）

**A. 网页**（最稳）

1. fork `awesome-dsh-plugin/awesome-dsh-plugin`
2. 在自己的 fork 里新建上面那个 YAML 文件（路径 `data/plugins/`）
3. 发起 PR 到 `main`，标题正文照抄

**B. 用现有 token 走 API**（未实测，fine-grained token 可能无 fork 权限）

```bash
# 可能返回 403；失败就走 A
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/awesome-dsh-plugin/awesome-dsh-plugin/forks
```

## 4. 评审会看什么（对照自查）

| 他们问 | 我们的答 |
|---|---|
| 能 `dsh plugin add` 装吗 | 能，桌面端与 npm 都实测过 |
| 是不是纯聚合包 | 不是：自带 4 份技能正文并在 `apply()` 里注册；不依赖任何第三方插件 |
| 描述有夸大吗 | 描述里每一句都对应仓库里的文件（skills/、cordis.patch.yml、index.js） |
| 分类对不对 | `tools`——它确实新增工具能力；若维护者改判为 `skill` 也接受 |
| 仓库活跃吗 | 今天刚发布 0.1.2，后续按产品迭代发版 |
