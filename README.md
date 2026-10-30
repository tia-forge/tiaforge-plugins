# TIA Forge 插件市场（WorkBuddy / CodeBuddy Code）

[![skills.sh](https://skills.sh/b/tia-forge/tiaforge-plugins)](https://skills.sh/tia-forge/tiaforge-plugins)

西门子博途（TIA Portal）工程自动化的**一套插件**：五个技能 + 四个斜杠指令 + 一条 MCP 连接。
WorkBuddy 与 CodeBuddy Code 共用同一套插件运行时，所以**这一个仓库同时服务两个客户端**。

```
查文档 → 生成梯形图块 → 渲染看图核对 → 云端仿真跑 PASS/FAIL → 在真实工程里编译/下载/读回
```

## 装法（先试界面，界面走不通再用命令行）

### A. 桌面端界面装（推荐，三下点完）

1. 打开 **插件** 页 → 右上角 `+`（添加第三方插件市场）；
2. 填市场地址：

   ```
   https://raw.githubusercontent.com/tia-forge/tiaforge-plugins/main/.codebuddy-plugin/marketplace.json
   ```

3. 市场里找到 **tiaforge** → 点安装 → 重启 WorkBuddy。

装完里面就是五个技能 + 四个斜杠指令（`/tiaforge:tia-status` 等）。

> ⚠️ **第 3 步报「路径未找到」就往下走 B**：官方文档要求含 `skills/commands/本地代码` 的插件在条目里声明 Git/NPM 等可物化远端源，或整个市场改用 Git/ZIP 发布；本市场用的是相对路径源（`./plugins/tiaforge`），所以 URL 型市场并不是每个客户端版本都吃。

### B. 界面里的「上传技能」（免市场，只用界面）

技能页 → 「上传技能」→ 选 `zip/` 里现成的包（**已打好，不用自己压**）：

| zip | 装上之后能干什么 |
|---|---|
| `tia-portal-docs-1.0.8.zip` | 查博途官方文档（2 800+ 章节） |
| `laddoc-cloud-1.0.7.zip` | LadDoc → 博途可导入 SimaticML |
| `lad-render-cloud-1.0.1.zip` | SimaticML → PNG，导入前先看一眼 |
| `plc-cloud-sim-1.0.7.zip` | 云端逐扫描仿真 + 场景 PASS/FAIL |
| `tialink-tia-portal-1.0.7.zip` | 操作真实工程（本机装 TiaLink） |

只想要技能的话 B 就够（四个斜杠指令 `/tiaforge:*` 要 A 方式才有）。

### C. 命令行（写脚本、批量装、或界面里找不到入口时）

```bash
/plugin marketplace add tia-forge/tiaforge-plugins
/plugin install tiaforge@tia-forge
```

这条走的也是同一份市场定义，只是把「填地址」换成了 `owner/repo` 形式——反而不受上面那个 URL 限制。

### D. 其他 skill 客户端（Claude Code / Cursor / Codex / Cline 等）

```bash
npx skills add tia-forge/tiaforge-plugins
```

这条只装**技能**（五个 `SKILL.md`），不带斜杠指令。它读的是本仓的 `.claude-plugin/marketplace.json`，
所以没有额外目录要求；`npx skills add tia-forge/tiaforge-plugins --list` 可以先看清单再决定装哪个。

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

装法同样是**先界面**：DSH 桌面端点左上角【插件】→ 输 `dsh-tiaforge` → 安装 → 重启。命令行只是等价备选：

```sh
dsh plugin --profile web add github:tia-forge/tiaforge-plugins#path:dsh-plugin
```

细节见 [`dsh-plugin/README.md`](./dsh-plugin/README.md)。

## 许可与归属

- 技能与文档：**CC BY 4.0**
- 插件清单与命令：同上
- TiaLink 网关与云端四个 MCP 服务为**商业软件/服务**，不在本许可范围内
- 与 Siemens AG 无关；TIA Portal、SIMATIC、S7、PLCSIM 是 Siemens AG 的商标
