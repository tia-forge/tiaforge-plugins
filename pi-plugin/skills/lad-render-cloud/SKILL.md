---
name: lad-render-cloud
slug: lad-render-cloud
displayName: 梯形图渲染（SimaticML → PNG，免装博途）
version: 1.0.1
summary: 一份 SimaticML 进，真实布局的 PNG 梯形图出——触点、线圈、分支汇合、接口声明表都按工程习惯绘制，AI 助手终于能"看见"自己写的逻辑。含 scale/network 怎么用、7 个错误码怎么判、什么时候别渲染。
description: 把 SimaticML（TIA Portal 导出的 FC/FB/OB 块 XML）渲染成 PNG 梯形图的云端 MCP 服务。当用户要"让 AI 看一眼梯形图"、"SimaticML 转 PNG"、"不装博途把块渲染成图片"、"核对 AI 生成的 LAD 逻辑"、"把梯形图贴进 PR/文档"时使用。只解析 XML 文本，不连接博途、不读写工程；不装博途也能渲染。
license: CC-BY-4.0
tags: [梯形图, LAD, SimaticML, 渲染, PNG, 博途, 博图, PLC, MCP]
homepage: https://tia.hubwiz.com/render/?utm_source=pi-package&utm_medium=plugin
metadata:
  publisher: 汇智网 (hubwiz.com)
  transport: MCP Streamable HTTP（https://tia.hubwiz.com/render/mcp + API Key）
  tools: render_version（不计费）, render_simaticml
  output: PNG（page content image/png + 一段元数据）
  renderer: lad-renderer（MIT）
  billing: 新用户 100 次免费；每次 tools/call 扣 1 次（失败也扣）；render_version 不计费
---

# LAD Render Cloud —— 让 AI "看见"梯形图，而不是猜 XML

**它解决的事**：SimaticML 是几百行嵌套 XML，AI 对着它判断"这个并联到底并到哪"会看漏。把同一个块渲染成 PNG，串联/并联、线圈、分支汇合、接口引用一眼可见——**这不是准确性问题，是能不能看的问题**。

```text
SimaticML XML ──MCP(Streamable HTTP, /render/mcp + API Key)──► 云端渲染器 ──► PNG + 元数据
（博途导出）                                                                  （AI 直接查看）
```

**先说清楚三件事，省掉一半的无效尝试：**

| 是 | 不是 |
|---|---|
| 云端 MCP：客户端支持 **Streamable HTTP + 能显示图片** 就能用 | ❌ **不是博途截图**：按 IEC 61131-3 重绘，字体/间距与博途原生控件不同 |
| 只解析 SimaticML **文本**，不连接博途、不读写工程 | ❌ 不能"上传 .ap19 帮你改工程"（工程级操作走本地 TiaLink） |
| 一次调用渲染**一个块**，可整块也可单网络（`network`） | ❌ **不做逻辑验证**：图对 ≠ 逻辑对（定时器参数错了图上看不出来），那用 `/sim` |

---

## 30 秒跑通

1. **拿 Key**（微信扫码，新用户 **100 次免费**，无需注册）：https://tia.hubwiz.com/render/?utm_source=pi-package&utm_medium=plugin
2. **把这段贴进 MCP 客户端**（WorkBuddy：`~/.workbuddy/mcp.json`；Claude Code / Cursor / VS Code 直接贴）：

```json
{"mcpServers":{"lad-render":{"type":"http","url":"https://tia.hubwiz.com/render/mcp",
  "headers":{"Authorization":"Bearer <你的 API Key>"}}}}
```

3. **成功标准**：`list tools` 能看到 `render_version` / `render_simaticml` → 先调 `render_version`（**不计费**）把真实上限取回来 → 再渲染一个块。

> **401 = Key 没带上或已失效**。注意：本站服务的鉴权在传输层，**连 `initialize` 都要 Key**，不能"裸试握手"。
> `render_version` 免费是指**不扣额度**，不是指不用 Key。

---

## 0. 三条先决条件

| # | 条件 | 说明 |
|---|---|---|
| 1 | **微信扫码登录**拿 API Key | 控制台创建 `render_live_…`，明文**只显示一次**；服务端只存哈希 |
| 2 | 客户端支持 **Streamable HTTP**，且**能显示 `image/png`** | 纯文本客户端也能调，但只能拿到元数据（块名/语言/网络数/尺寸），看不到图——那就失去了用它的一半理由 |
| 3 | **XML 会上传云端** | 服务端保存渲染所需的输入。**产线机密、不能出内网的工程不要用**，改本地 TiaLink |

**红线**：不要把客户完整工程一次性导出来批量刷。先脱敏、单块、只保留要核对的那个块。

---

## 1. 连接（各客户端）

```json
{
  "mcpServers": {
    "lad-render": {
      "type": "http",
      "url": "https://tia.hubwiz.com/render/mcp",
      "headers": { "Authorization": "Bearer render_live_你的密钥" }
    }
  }
}
```

```bash
# Claude Code
claude mcp add --transport http lad-render https://tia.hubwiz.com/render/mcp \
  --header "Authorization: Bearer render_live_你的密钥"
claude mcp list          # 期望 connected
```

- **Cursor / VS Code**：贴上面的 JSON（Cursor 选 `http` 传输）。
- **WorkBuddy**：写进 `~/.workbuddy/mcp.json`，或「插件 → MCP 服务器 → 配置 MCP」。
- **DeepSeek Harness**：profile 的 `cordis.patch.yml` 里加一条 `@deepseek-ai/dsh-mcp-client`（原生支持 Streamable HTTP）。
- 也接受 `X-API-Key: render_live_…` 头（不支持自定义 `Authorization` 的客户端用这个）。

---

## 2. 两个工具与计费

| 工具 | 用途 | 计费 |
|---|---|---|
| `render_version` | 返回渲染器版本、支持的语言/块类型、`scale`/`network` 范围、**全部上限**、计费口径 | **不计费** |
| `render_simaticml` | 入参 `xml`（必填）、`scale`（可选）、`network`（可选）；返回 `content[0]` = `image/png`，`content[1]` = 元数据（块名、语言、网络列表、像素尺寸等） | **每次扣 1 次额度** |

两条计费口径必须记住，否则额度会莫名其妙掉光：

1. **先扣费后执行**：`tools/call` 采用"先扣后跑"，**文档非法也照样扣 1 次**（返回完整错误信息供修正）。所以**不要循环重试**。
2. **不计费的只有** `initialize` / `tools/list` / `render_version`。一次调用只处理**一个块**；被调用的 FC/FB 要各自作为独立块另行提交。

---

## 3. 标准工作序（照抄）

```text
第一步：读限制（不计费）
调 render_version，把这几项原文贴给我，不要改写：
- renderer.version、capabilities.languages、capabilities.blockKinds
- capabilities.scale 的范围与默认值
- limits 全部字段、billing 口径

第二步：渲染整块（先别加参数）
把下面这份 SimaticML 交给 render_simaticml（不传 network、不传 scale）：
<粘贴完整的 SimaticML 文本>
回给我：
- content[0]：把 PNG 直接展示出来，不要用文字描述图片；
- content[1]：块名、语言、网络数量、图片像素尺寸。

第三步：看不清才放大到单个网络
用 network=<索引> + scale=2 只渲那一个网络。索引以元数据里的网络列表为准，不要猜编号。

第四步：报错只改输入，不重复试
把错误码与 message 原文贴给我，按第 5 节判读。为了"再试一次"而重复调用，每次都扣额度。

第五步：产物落地
PNG 存成 <块名>_all.png 或 <块名>_net<N>.png，元数据存同名 .json，方便以后比图。
```

**为什么第二步要"先整块、后单网络"**：整块渲染带**接口声明表**，能一并核对形参/类型/初值；单网络渲染**没有接口表**，只适合定位细节。

---

## 4. 参数与上限（以 `render_version` 为准，下表是 D0 快照）

| 项 | 值 | 怎么用 |
|---|---|---|
| `scale` | 1–3，默认 **1** | 越大越清晰，**越容易撞像素上限**；先 1 出图，细节不够再放大单网络 |
| `network` | 0 起始的索引 | 不传 = 整块（含接口声明表）；传了 = 只渲该网络 |
| 单份 XML | 4 MiB | 一个块一般远小于此；接近 4 MiB 说明导出错了（多半是整工程而非单块） |
| MCP 请求体 | 8 MiB | 客户端侧限制，超了先在想是不是塞了别的东西 |
| 最大图片 | 32,000,000 像素，单边 ≤ 20,000 px | 高块 + 大 scale 最先撞这条 |
| PNG 上限 | 12 MiB | 同上 |
| 限流 | 120 次/分钟（按 Key 或 IP） | 批量刷图会被限；批量场景自己排队 |
| 典型耗时 | 约 20 个网络的 FC/FB 整块 **0.2–0.5 秒** | 别为"等图"去做异步改造 |

**大块三步走**：整块 `scale=1` → 报 `RENDER_TOO_LARGE` 就用 `network` 逐个渲 → 单网络需要细节再加 `scale=2`。不要一上来就 `scale=3` 整块，那是最容易失败且最贵的组合。

---

## 5. 错误码与判读

| 错误码 | 含义 | 处理 |
|---|---|---|
| `INVALID_SIMATICML` | XML 非法或找不到块 | 确认传的是**完整的块 XML**（含 `<Document>`），不是 `.ap19`、不是 SCL 源、不是别的东西 |
| `UNSUPPORTED_DOCUMENT` | DB / InstanceDB / UDT / 标签表等**没有梯形图**的文档 | 不是 bug：改用 FC / FB / OB 块 |
| `UNSUPPORTED_LANGUAGE` | FBD / GRAPH / STL | 只支持 LAD / SCL（同一块内混合 LAD/SCL 可以） |
| `LAYOUT_ERROR` | 网络不是串并联结构，布局失败 | 整块报错时用 `network` 逐个渲，定位是哪个网络；其余网络照常出图 |
| `INVALID_ARGUMENT` | `scale` 或 `network` 越界 | 先 `render_version` 拿范围；索引从 0 开始 |
| `RENDER_TOO_LARGE` | 超 XML / 像素 / 尺寸 / PNG 限制 | 降 `scale` 或指定 `network` |
| `QUOTA_EXHAUSTED` | 额度用完 | 控制台买额度（额度**不过期**） |

判读三原则：

1. **错误码是产品语义，不是网络故障**。别反复重试——那只会继续扣额度。
2. `UNSUPPORTED_DOCUMENT` / `UNSUPPORTED_LANGUAGE` 是**能力边界**，改输入没用，换工具（或换块）。
3. `LAYOUT_ERROR` 是**这一块**画不出来，不代表服务挂了；先用 `network` 把范围缩到单个网络。

---

## 6. 它证明什么、不证明什么

能证明：**这一块画出来的图形逻辑，和 XML 里写的是同一件事**（触点串并、线圈位置、分支汇合、接口声明）。
不能证明：逻辑**正确**、时序**对**、和硬件/通信**配合得上**。所以它只是流水线里"看一眼"的那一步，不是验收。

| 什么时候**不要**用它 | 为什么 |
|---|---|
| 要判断逻辑对不对（起保停、互锁、超时） | 图对 ≠ 语义对 → 用 PLC 云仿真（`/sim`）跑用例拿 PASS/FAIL |
| 安全功能（急停、安全门、光幕） | 安全逻辑必须在安全 PLC / 安全继电器里验证，普通程序块渲染图不能当证据 |
| 工程不能出内网 | XML 会上传云端 → 用本地 TiaLink |
| 想拿图当"博途里长这样"的证据 | 渲染是**重绘**，不是博途控件截图；评审口径要说清"这是按 IEC 符号重绘的" |

---

## 7. 真实用法（这四条最常被用到）

| 场景 | 怎么用 | 注意 |
|---|---|---|
| **导入博途前过一眼** | AI 生成的块 → 渲一张 → 看触点/线圈/分支有没有明显错 | 只看结构；逻辑正确性交给 `/sim` |
| **给没有博途的人看** | PNG 贴进 PR / issue / 交付文档 / 周报 | 对方不用装博途，也不用懂 XML |
| **改前改后对比** | 两个版本的 XML 各渲一张，并排看图找差异 | 只证明"图变了"，不证明"改对了" |
| **评审 / 教学材料** | 从真实项目导出 XML 渲成图，比手画示意图准 | 机密工程先脱敏再导出 |

---

## 8. 与同门工具的分工（别装错）

| 要做的事 | 用谁 |
|---|---|
| LadDoc（JSON）→ 博途可导入的 SimaticML 块 | LadDoc Cloud（`/lad`） |
| **SimaticML → PNG 梯形图（看）** | **LAD Render Cloud（这里）** |
| 逻辑跑不跑得通（逐扫描 + 场景 PASS/FAIL） | PLC 云仿真（`/sim`） |
| 在真实工程里编译、下载、读回 | TiaLink（本地 MCP 网关，工程不出内网） |
| 自然语言 → 直接在博途插件里画 LAD | TXT2LAD（博途 Add-In） |
| 已有 LAD 块 → SCL 源码 | LAD2SCL（博途 Add-In） |

**同门 ≠ 同类，四个容易被认错的**：

- **博途自带截图**：像素级真相，但要装博途、要打开工程、要人工操作；本服务不装博途、只吃 XML。
- **BLOCK-SIM**：博途 Add-In，在博途内部做块级**验证**；这里只出**图**。
- **PLCSIM Advanced**：整机/控制器仿真（含硬件组态与通信）；这里只画一个程序块。
- **LadDoc Cloud**：**生成** SimaticML；这里**渲染** SimaticML。一进一出，别搞反。

推荐闭环：**LadDoc Cloud 生成 → LAD Render Cloud 看图 → `/sim` 跑场景 → TiaLink 落地并编译读回**。

---

## 配套技能（同一套 TIA Forge 工作流）

这五个技能是一条链：**查文档 → 生成块 → 看图核对 → 跑验证 → 落地工程**。单独装一个能用，装齐才闭环。

| 技能 | 安装坐标 | 什么时候需要它 |
|---|---|---|
| 博途编程文档检索 | `@indiv-tiaforge/tia-portal-docs` | 不确定指令参数、引脚含义、版本行为 |
| LadDoc Cloud | `@indiv-tiaforge/laddoc-cloud` | 要把 LadDoc 生成成博途可导入的块 |
| 梯形图渲染 **← 你在这里** | `@indiv-tiaforge/lad-render-cloud` | 想把 SimaticML 变成能看的 PNG、导入前过一眼 |
| PLC 云仿真 | `@indiv-tiaforge/plc-cloud-sim` | 生成后跑 PASS/FAIL、回归、边界用例 |
| TiaLink | `@indiv-tiaforge/tialink-tia-portal` | 在真实工程里编译、下载、读回 |

装齐的方式：把下面这句发给你正在用的 AI 助手（逐个发即可）：

```text
请根据 https://skillhub.cn/install/skillhub.md，安装 @indiv-tiaforge/<slug>
```

---

## 9. 获取与计费

| 项 | 说明 |
|---|---|
| 端点 | `https://tia.hubwiz.com/render/mcp`（Streamable HTTP，无状态 POST JSON-RPC） |
| 开通 | 微信扫码登录即得 API Key，无需注册；新用户 **100 次免费** |
| 计费 | 每次 `tools/call` 扣 1 次（**失败也扣**）；`initialize` / `tools/list` / `render_version` 不计费 |
| 额度包 | 1000 次 ¥9.90 / 5000 次 ¥29.90 / 15000 次 ¥69.90（一次性，**额度不过期**，无订阅无月费） |
| 页面 | https://tia.hubwiz.com/render/?utm_source=pi-package&utm_medium=plugin （含 MCP 配置指南：`/render/help`） |
| 机器可读口径 | `https://tia.hubwiz.com/render/version`（版本/能力/上限/计费，客户端应以它为准） |

---

*汇智网（hubwiz.com）出品。TIA Portal、SIMATIC、S7 是 Siemens AG 的商标；本服务与 Siemens AG 无关。渲染器 `lad-renderer` 以 MIT 许可发布。文档许可 CC BY 4.0。*
