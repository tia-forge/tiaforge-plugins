# dsh-tiaforge —— DeepSeek Harness 插件

[![skills.sh](https://skills.sh/b/tia-forge/tiaforge-plugins)](https://skills.sh/tia-forge/tiaforge-plugins)

把 TIA Forge 的**五个技能**和**五个 MCP 端点**打成**一个组合包（bundle）**：
装一次，DSH 里就有「查文档 → 生成梯形图 → 看图核对 → 跑仿真 → 操作真实工程」这条链。

> **为什么需要它**：DSH 本身支持 skill（`ctx.skills` + 文件系统提供方，扫 `<project>/.dsh/skills`、`.agents/skills`、`~/.dsh/skills`），
> 但**没有 `dsh skill add` 这类命令** —— skill 只能靠"把文件放到扫描目录"或"插件注册"进来。
> 这个包用后者：`index.js` 在 `apply()` 里读包内 `skills/*/SKILL.md`，直接 `ctx.skills.register()`。
> 所以你不需要拷文件、也不需要配 `customSkillDirs`。

## 装

### A. 桌面端界面装（推荐，三步）

1. 点 DSH 左上角【插件】；
2. 输入 `dsh-tiaforge`；
3. 点安装 → **完全退出并重开** DSH（MCP 连接是在启动时建立的）。

装完模型侧就能看到 **五个技能 + 五个已接入的服务**，全程不用开终端、不用改配置文件。

### B. 命令行（写脚本、批量装、或 `dsh web` 里找不到插件入口时）

```sh
# 从 npm（预构建，推荐）
dsh plugin --profile web add dsh-tiaforge

# 从 GitHub（本仓库的 dsh-plugin 目录）
dsh plugin --profile web add github:tia-forge/tiaforge-plugins#path:dsh-plugin
```

装完重启 `dsh web`，并强刷浏览器。

## 它装了什么

| 类型 | 名称 | 说明 |
|---|---|---|
| 技能 | `tialink-tia-portal` | AI 操作博途工程（V19/V20；未授权只读） |
| 技能 | `plc-cloud-sim` | 云端逐扫描仿真 + 场景 PASS/FAIL |
| 技能 | `laddoc-cloud` | LadDoc → 博途可导入 SimaticML |
| 技能 | `lad-render-cloud` | SimaticML → PNG，导入前先看一眼（**计费**，每次渲染扣 1 次） |
| 技能 | `tia-portal-docs` | 博途编程文档检索（`get_docs`） |
| MCP | `tialink` | `http://127.0.0.1:8080/mcp`（本机网关） |
| MCP | `tia-docs` | `https://tia.hubwiz.com/ai-coding-docs/mcp` |
| MCP | `plc-sim` | `https://tia.hubwiz.com/sim/mcp` |
| MCP | `laddoc` | `https://tia.hubwiz.com/lad/mcp` |
| MCP | `lad-render` | `https://tia.hubwiz.com/render/mcp`（**计费**，见下） |

MCP 行全部设 `failOnStartupError: false`：端点没起来（没装 TiaLink、没配 Key）时插件照常加载，只是对应的工具不出现，**不会拖垮 profile**。

## 桌面端（Desktop）

Desktop 是 dsh Web 应用的 Electron 壳，**插件语义完全一致**（同一个共享插件管理器、同一个 profile runner），
只是 profile 目录不同：`$DSH_HOME/profiles/desktop`，且**由 Electron 独占**。

> **走 A（界面安装）不会碰到下面这两条** —— 它们只在你用**命令行**往 Desktop 里装时才有关。

两个硬约束（官方 `apps/desktop/README.zh.md`）：

1. **先用 npm 装的 dsh 管不了它** —— 必须用 Desktop 自带的 CLI：菜单 →「检查更新…」下方「**管理 dsh 命令…**」→ 安装，然后新终端里 `dsh --version`。
2. **第一次要先用 Desktop 启动一次**（初始化 profile），然后**完全退出应用**，再执行安装命令。

```sh
# 1) 启动一次 Desktop 再完全退出
# 2) 装好 Desktop 自带 CLI 后：
dsh plugin --profile desktop add dsh-tiaforge
# 3) 重新打开 Desktop
```

Desktop 里没有"技能"页面——这不是缺功能：**技能是模型调用的**（`skill` 工具 + 目录注入），
本插件在 `apply()` 里注册，所以桌面端一样能用到，不需要任何 UI。

若安装被拒且报 `engines.dsh` 不匹配：Desktop 的 dsh 版本与打包版本严格一致，
升级 Desktop，或把 `package.json` 的 `engines.dsh` 放宽到覆盖你的版本。

## 配 token（三选一，按需）

```sh
# ① TiaLink 本机网关（默认 127.0.0.1:8080，装了 token 就填）
export TIALINK_TOKEN=...
export TIALINK_URL=http://192.168.1.78:8080/mcp   # 网关在另一台机器时

# ② 四个云端服务各自一把 Key（微信扫码，各 100 次免费）
export TIA_DOCS_KEY=...
export TIA_SIM_KEY=...
export TIA_LAD_KEY=...
export TIA_RENDER_KEY=...   # 唯一计费的：每次渲染扣 1 次，先扣后执行
```

四个云端服务的大致分工：

| Key | 端点 | 免费额度 | 技能 |
|---|---|---|---|
| `TIA_DOCS_KEY` | `/ai-coding-docs/mcp` | 100 次 | `tia-portal-docs` |
| `TIA_SIM_KEY` | `/sim/mcp` | 100 次 | `plc-cloud-sim` |
| `TIA_LAD_KEY` | `/lad/mcp` | 100 次 | `laddoc-cloud` |
| `TIA_RENDER_KEY` | `/render/mcp` | 100 次 | `lad-render-cloud`（`render_version` 免费，渲染扣 1） |

不配的话对应 MCP 不出现工具（没 Key = `initialize` 就 401），但**技能仍然可用**（技能正文本身就是可读的知识，不依赖工具）。
`TIA_RENDER_KEY` 不配也不会白扣额度——这一点跟另三个一样，靠 key 门控。

## 验证

```sh
# 1) 组合后的配置里应该有这 6 行
dsh --profile web --dump-config | grep -n tiaforge

# 2) 起来之后，模型侧应该能用 skill 工具看到五个技能
dsh web
#   对话里问：「列出你能用的 TIA 相关技能」
```

## 结构

```
dsh-plugin/
├── package.json          # dsh.bundle.patch = ./cordis.patch.yml；engines.dsh = >=0.2.0 <0.3.0
├── cordis.patch.yml      # 1 行技能注册插件 + 5 行 mcp-client
├── index.js              # 读 skills/*/SKILL.md → ctx.skills.register()
└── skills/<slug>/SKILL.md
```

`cordis.patch.yml` 只 `insert` 新行、**不覆盖任何已有行**，所以 dsh-base / web-app 升级时这个包最不容易坏。

## 兼容性

- `engines.dsh: ">=0.2.0-rc.0 <0.2.1-rc.0 || >=0.2.1-rc.0 <0.3.0"`（0.1.1 起）。**两个分支是必需的**：node-semver 只允许某个比较符元组与版本 tuple 完全一致且自带预发布标签时才放行预发布版，单个 `>=0.2.1-rc.1 <0.3.0` 会把 `0.2.0-rc.2` 这类版本静默排除。
- 实测环境：**dsh desktop 0.2.0-rc.2** 可安装并加载（桌面端未强制 engines，但其它安装路径会校验）。
- 升级 DSH 后先跑一次 `--dump-config`，确认 6 行还在，再开始用。

## 许可

插件代码 MIT；技能正文 CC BY 4.0（见各 `SKILL.md`）。TiaLink 网关与四个云端服务是商业软件/服务，不在本许可范围内。
