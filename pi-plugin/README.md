# pi-tiaforge

[![skills.sh](https://skills.sh/b/tia-forge/tiaforge-plugins)](https://skills.sh/tia-forge/tiaforge-plugins)

把 TIA Forge 的**五个技能**和**五个 MCP 端点**打进一个 pi 包：装一次，pi 里就有
「查文档 → 生成梯形图 → 渲染看图核对 → 云端仿真跑 PASS/FAIL → 在真实工程里编译/下载/读回」这条链。

```bash
pi install npm:pi-tiaforge
```

装完 `/mcp` 里应能看到 `tialink`（本机网关在跑时），`/skill:` 补全里能看到五个技能。
先在别的项目里试一次而不写进配置：`pi -e npm:pi-tiaforge`。

> **前提**：TiaLink 网关跑在 Windows + 博途 **V19/V20**（V21 暂不支持）的机器上，账号需在
> `Siemens TIA Openness` 用户组；**未授权时只读**——能读工程、读块、读硬件树，不能改。
> 四个云端服务要各自的 Key（微信扫码，各 100 次免费）。没装网关、没配 Key 都不影响 pi 启动，
> 只是对应的工具不出现。

## 它装了什么

| 类型 | 名称 | 说明 |
|---|---|---|
| 技能 | `tialink-tia-portal` | 操作真实博途工程（组态、建块、编译、下载、读回） |
| 技能 | `plc-cloud-sim` | 云端逐扫描仿真 + 场景 PASS/FAIL |
| 技能 | `laddoc-cloud` | LadDoc → 博途可导入的 SimaticML |
| 技能 | `lad-render-cloud` | SimaticML → PNG，导入前先看一眼（**计费**，每次渲染扣 1 次） |
| 技能 | `tia-portal-docs` | 博途编程文档检索（`get_docs`，2800+ 章节） |
| MCP | `tialink` | `http://127.0.0.1:8080/mcp`（与博途同机的本机网关） |
| MCP | `tia-docs` | `https://tia.hubwiz.com/ai-coding-docs/mcp` |
| MCP | `plc-sim` | `https://tia.hubwiz.com/sim/mcp` |
| MCP | `laddoc` | `https://tia.hubwiz.com/lad/mcp` |
| MCP | `lad-render` | `https://tia.hubwiz.com/render/mcp`（**计费**，见下） |

`tialink` 总是注册；四个云端**只有存在对应 Key 时才注册**，所以没配 Key 的机器上不会刷一串 401，
也不会出现"看得到工具、点了就报错"的情况。MCP 默认走 `codemode` 暴露：模型用 `searchTools()` 找工具，
不在提示里常驻，装多少服务都不会撑爆上下文。

## 配环境变量（按需）

```sh
# ① TiaLink 本机网关：默认 127.0.0.1:8080；网关在另一台机器时改 URL
export TIALINK_URL=http://<网关机器IP>:8080/mcp
export TIALINK_TOKEN=...          # 网关没开鉴权就不用设

# ② 四个云端服务各自一把 Key
export TIA_DOCS_KEY=...           # 文档检索
export TIA_SIM_KEY=...            # 云仿真
export TIA_LAD_KEY=...            # LadDoc
export TIA_RENDER_KEY=...         # 渲染，唯一计费的：每次渲染扣 1 次，先扣后执行
```

| Key | 端点 | 免费额度 | 对应技能 |
|---|---|---|---|
| `TIA_DOCS_KEY` | `/ai-coding-docs/mcp` | 100 次 | `tia-portal-docs` |
| `TIA_SIM_KEY` | `/sim/mcp` | 100 次 | `plc-cloud-sim` |
| `TIA_LAD_KEY` | `/lad/mcp` | 100 次 | `laddoc-cloud` |
| `TIA_RENDER_KEY` | `/render/mcp` | 100 次 | `lad-render-cloud`（`render_version` 免费，渲染扣 1） |

想固定下来而不是每次 export，写进 `~/.pi/agent/mcp.json` 也行——**文件配置的同名条目优先于本包的注册**：

```json
{
  "mcpServers": {
    "tialink": { "url": "http://127.0.0.1:8080/mcp", "timeout": 600 }
  }
}
```

## 验证

```sh
pi install npm:pi-tiaforge     # 或 pi -e npm:pi-tiaforge 试用一次
pi mcp list                    # 只列文件配置；本包注册的在会话里看
```

进会话后：

1. `/mcp` —— 服务器列表里应有 `tialink`，状态 connected，并列出工具数；
2. `/skill:tialink-tia-portal` —— 能直接加载技能正文；
3. 问一句「列出你能用的 TIA 相关工具」——模型应该能通过 `searchTools("mcp__tialink")` 找到它们。

连不上先看 `~/.pi/agent/mcp.log`：网关不在跑是 `ECONNREFUSED`，Key 不对是 401，都会写明。

## 结构

```text
pi-plugin/
├── package.json          # keywords 里必须有 "pi-package"（pi.dev/packages 靠它发现）
├── extensions/tiaforge.ts # registerMcpServer × 5（云端按 Key 门控）
├── skills/<slug>/SKILL.md # 五个技能，与 SkillHub 上架版同源
└── README.md
```

技能正文是单一真源：本仓 `sync-skills.sh` 从 `distribution/skillhub/<slug>/SKILL.md` 生成，
只把埋点 `utm_source` 换成 `pi-package`。

## 许可

包代码 MIT；技能正文 CC BY 4.0（见各 `SKILL.md`）。TiaLink 网关与四个云端服务是商业软件/服务，
不在本许可范围内。与 Siemens AG 无关；TIA Portal、SIMATIC、S7、PLCSIM 是 Siemens AG 的商标。
