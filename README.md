# TIA Forge 插件市场（WorkBuddy / CodeBuddy Code）

西门子博途（TIA Portal）工程自动化的**一套插件**：五个技能 + 四个斜杠指令 + 一条 MCP 连接。
WorkBuddy 与 CodeBuddy Code 共用同一套插件运行时，所以**这一个仓库同时服务两个客户端**。

```
查文档 → 生成梯形图块 → 渲染看图核对 → 云端仿真跑 PASS/FAIL → 在真实工程里编译/下载/读回
```

## 装法（两种，任选）

### A. CodeBuddy Code / WorkBuddy CLI（推荐，支持相对路径源）

```bash
/plugin marketplace add tia-forge/tiaforge-plugins
/plugin install tiaforge@tia-forge
```

### B. WorkBuddy 桌面端 UI

插件 → 右上 `+` → 填入市场地址：

```
https://raw.githubusercontent.com/tia-forge/tiaforge-plugins/main/.codebuddy-plugin/marketplace.json
```

> ⚠️ **URL 型市场的限制**：官方文档明确"包含 `skills/commands/hooks/本地代码` 的插件应在条目里声明 Git/NPM 等可物化的远端源，或把整个 Marketplace 改用 Git/ZIP 发布"。本市场用的是**相对路径源**（`./plugins/tiaforge`），所以**首选 A 的 `owner/repo` 方式**；B 若报"路径未找到"，改用 A 或把仓库打包成 ZIP 上传。
> 另一种免市场的方式：直接「上传技能」——把 `plugins/tiaforge/skills/<slug>/` 目录各自打 zip 导入。

## 里面有什么

| 组件 | 内容 |
|---|---|
| 技能 ×5 | `tia-portal-docs`（2800+ 章节文档检索）、`laddoc-cloud`（LadDoc→SimaticML）、`lad-render-cloud`（SimaticML→PNG 看图核对，**计费**）、`plc-cloud-sim`（LAD/SCL 逐扫描仿真）、`tialink-tia-portal`（真实工程操作） |
| 斜杠指令 ×4 | `/tiaforge:tia-status`（只读体检）、`/tiaforge:tia-hw-add`（机架组态）、`/tiaforge:tia-block`（建块写 SCL）、`/tiaforge:tia-verify`（三层验证） |
| MCP | `.mcp.json` 预置 `tialink` 本地网关（`http://127.0.0.1:8080/mcp`） |

技能正文是**单一真源**：与 SkillHub 上架版本同源（`sync-skills.sh` 从这里同步过去、或反向往回同步），只有埋点 `utm_source` 不同（`workbuddy-plugin` vs `skillhub`）。

## 前置条件

| 需要什么 | 说明 |
|---|---|
| TiaLink 网关 | Windows + 博途 **V19/V20**（V21 不支持）+ 账号在 `Siemens TIA Openness` 组；未授权时**只读可用** |
| 云端四个服务 | `tia-portal-docs` / `laddoc-cloud` / `lad-render-cloud` / `plc-cloud-sim` 各自需要 API Key（微信扫码，各 100 次免费；render 每次渲染扣 1 次），见各技能正文第 1 节 |
| 令牌 | `tialink` 用 `${TIALINK_TOKEN}` 环境变量；网关没配 token 就把 `.mcp.json` 里 `headers` 整段删掉 |

四个云端 MCP 的地址（需要时自行加进 `~/.workbuddy/mcp.json` 或客户端配置）：

```json
{
  "mcpServers": {
    "tia-docs": { "type": "http", "url": "https://tia.hubwiz.com/ai-coding-docs/mcp", "headers": { "Authorization": "Bearer <DOCS_KEY>" } },
    "plc-sim":  { "type": "http", "url": "https://tia.hubwiz.com/sim/mcp",             "headers": { "Authorization": "Bearer <SIM_KEY>" } },
    "laddoc":   { "type": "http", "url": "https://tia.hubwiz.com/lad/mcp",             "headers": { "Authorization": "Bearer <LAD_KEY>" } },
    "lad-render": { "type": "http", "url": "https://tia.hubwiz.com/render/mcp",        "headers": { "Authorization": "Bearer <RENDER_KEY>" } }
  }
}
```

## DeepSeek Harness 也要装？

本仓同时是 **DSH 插件**的来源（`dsh-plugin/`）——DSH 没有 `dsh skill add`，skill 只能靠"放目录"或"插件注册"进去，
那个包用后者：在 `apply()` 里读包内 `skills/*/SKILL.md` 并 `ctx.skills.register()`，外加 5 条 MCP 连接。

```sh
dsh plugin --profile web add github:tia-forge/tiaforge-plugins#path:dsh-plugin
```

细节见 [`dsh-plugin/README.md`](./dsh-plugin/README.md)。

## 维护

```bash
sh sync-skills.sh    # 把 ../skillhub/<slug>/SKILL.md 同步进来并改写 utm_source
sh zip-skills.sh     # 重打 zip/（读 SKILL.md 的 version: 自动命名，旧版自动删）
```

改完 commit + push，客户端 `/plugin marketplace update tia-forge` 即可拿到新版本（或等自动更新）。

## 许可与归属

- 技能与文档：**CC BY 4.0**
- 插件清单与命令：同上
- TiaLink 网关与云端四个 MCP 服务为**商业软件/服务**，不在本许可范围内
- 与 Siemens AG 无关；TIA Portal、SIMATIC、S7、PLCSIM 是 Siemens AG 的商标
