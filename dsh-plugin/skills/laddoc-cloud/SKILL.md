---
name: laddoc-cloud
slug: laddoc-cloud
displayName: 梯形图生成（博途可导入）
version: 1.0.7
summary: 让 AI 直接产出「能导入博途」的梯形图块：写 LadDoc（JSON 格式的 PLC 梯形图文档）→ 按 lad-ir D9 规则校验 → 确定性生成 V19 SimaticML（FC/FB/OB）。有 issue 就不出 XML，避免导入被拒。
description: 把 LadDoc（JSON 格式的 PLC 梯形图文档）校验后确定性生成为 TIA Portal V19 可直接导入的 SimaticML 块（FC/FB/OB）。当用户要"用 AI 生成梯形图块"、"让 AI 写 LAD 并导入博途"、"LadDoc 校验/生成 SimaticML"、"批量生成 PLC 块"时使用。不需要博途即可生成，导入时才需要博途 V19。
license: CC-BY-4.0
tags: [梯形图, LAD, 博途, 博图, SimaticML, PLC, 代码生成]
homepage: https://tia.hubwiz.com/lad?utm_source=dsh&utm_medium=plugin
metadata:
  publisher: 汇智网 (hubwiz.com)
  transport: MCP Streamable HTTP（https://tia.hubwiz.com/lad/mcp + API Key）
  tools: lad_version（不计费）, lad_validate, lad_generate
  output: TIA Portal V19 SimaticML（<SW.Blocks.FC|FB|OB>）
  billing: 新用户 100 次免费；之后按额度包（1000 次 ¥9.90 起）
---

# LadDoc Cloud —— 把 AI 写的梯形图变成博途能导入的块

## 30 秒跑通（照这个做，养成“先能跑再读”的习惯）

1. **拿 Key**（微信扫码，新用户 100 次免费，无需注册）：https://tia.hubwiz.com/lad?utm_source=dsh&utm_medium=plugin
2. **把下面这段贴进你的 MCP 客户端**（WorkBuddy：`~/.workbuddy/mcp.json`）：

```json
{"mcpServers":{"laddoc":{"type":"http","url":"https://tia.hubwiz.com/lad/mcp",
  "headers":{"Authorization":"Bearer <你的 API Key>"}}}}
```

3. **成功标准**：`list tools` 能看到 `lad_version` / `lad_validate` / `lad_generate` → 先调 `lad_version`（**不计费**）确认连通，再 validate 一份 LadDoc。

> 401 = Key 没带上或已过期；`initialize` / `tools/list` / `lad_version` 都不计费。

**一句话**：AI 很少能可靠地"画"梯形图，但很擅长写 **JSON**。LadDoc 就是为这个设计的中间表示：**LadDoc（JSON 格式的 PLC 梯形图文档，专为 AI 生成与修改设计）**，经服务校验后**确定性**生成 SimaticML，导入博途即成块。

## 0. 先消歧义（这三个名字经常被搞混）

| 名字 | 是什么 | 不是什么 |
|---|---|---|
| **LadDoc** | JSON 格式的 PLC 梯形图文档，**专为 AI 生成/修改设计** | ❌ 不是 Lua 的 **LDoc**（文档生成器）；❌ 不是 **Teladoc**（美股） |
| **LadDoc Cloud**（`/lad`） | 云端 MCP：校验 LadDoc → 生成 SimaticML | ❌ 不是 TXT2LAD（那个吃自然语言、在博途插件里画图） |
| **SimaticML** | 西门子 XML 交换格式，博途可导入 | ❌ 不是 LAD 源文件的"另一种后缀" |

## 1. 三条先决条件

| # | 条件 | 说明 |
|---|---|---|
| 1 | **微信扫码登录**拿 API Key | 扫码即开通；Key 只存哈希，明文只显示一次 |
| 2 | 客户端支持 **Streamable HTTP + header** | 端点 `https://tia.hubwiz.com/lad/mcp` |
| 3 | **LadDoc 会上传云端；生成的是 V19 文档** | 机密工程不要用（改用本地 TiaLink）；V20/V21 尚未逐版本验证，导入端要自己确认 |

## 2. 连接

```json
{
  "mcpServers": {
    "laddoc": {
      "type": "http",
      "url": "https://tia.hubwiz.com/lad/mcp",
      "headers": { "Authorization": "Bearer <你的 API Key>" }
    }
  }
}
```

Claude Code / Cursor / VS Code 直接贴；**WorkBuddy** 写进 `~/.workbuddy/mcp.json` 或用「插件 → MCP 服务器 → 配置 MCP」；**DeepSeek Harness** 在 profile 的 `cordis.patch.yml` 里加 `@deepseek-ai/dsh-mcp-client` 条目。

## 3. 三个工具与计费

| 工具 | 用途 | 计费 |
|---|---|---|
| `lad_version` | 返回本服务实现的 LAD-IR 身份（`schemaVersion` / `bundleHash` / `sourceCommit`） | **不计费** |
| `lad_validate` | 校验一个 LadDoc，返回 `valid` 与 issues | 每次 1 次额度 |
| `lad_generate` | 校验通过后生成一个 SimaticML 块 XML | 每次 1 次额度 |

> **先调 `lad_version`**：`schemaVersion` 是 LadDoc 的形状版本，`bundleHash`/`sourceCommit` 让"同一份文档在什么时候生成过什么"可追溯。写 LadDoc 之前对齐版本，能省掉一整轮校验失败。

## 4. 标准工作序（照抄）

```text
第一步：对齐版本（不计费）
调 lad_version，告诉我 schemaVersion / bundleHash / sourceCommit。

第二步：按 schema 写 LadDoc，不凭记忆
1) 调 tools/list，把 lad_validate / lad_generate 的入参 schema 原文贴给我；
2) 按该 schema 生成一个最小 FC（2 个网络：起保停 + 一个定时器）的 LadDoc；
3) 不要现在生成 XML，先校验。

第三步：校验并逐条修（不猜修法）
调 lad_validate。只回：
- valid 是否为 true；
- 每条 issue 的 code / path / message 原文（不改写）。
我确认后你再改，一次只改一个 issue。

第四步：生成（校验通过后才做）
valid=true 之后再调 lad_generate，把返回的 XML 存成 .xml，并告诉我：
- 目标块类型（FC/FB/OB）与块名；
- 这份 XML 对应的 LadDoc 的 schemaVersion。

第五步：导入与核对（人工）
我在博途 V19 里导入该 XML，然后：
1) 读回块接口，与 LadDoc 里的接口逐项对照；
2) 编译，把编译输出原文贴给我；
3) 编译不过就把错误原文反馈给你，你只改 LadDoc，不手改 XML。
```

**为什么"只改 LadDoc、不手改 XML"**：生成的 XML 是确定性的产物（同一份 LadDoc 永远生成完全相同的结果，UId 与连线由生成器分配）。手改 XML 会让文档与产物脱钩，下次重生成就覆盖掉你的修改。

## 5. 校验在查什么（D9 规则，按这一层去理解 issue）

| 层 | 查什么 | 典型 issue |
|---|---|---|
| 文档形状 | LadDoc 顶层结构、必填字段、版本 | 字段缺失/类型错 → 看 `path` |
| 块接口 | 块类型、接口区（IN/OUT/IN_OUT/STATIC/TEMP）声明 | 变量重复、区段不合法 |
| 网络与并行分支 | 网络划分、串并联拓扑、分支汇聚 | 悬空引脚、非法并联 |
| 操作数 | 符号与地址、类型匹配（Bool/Int/Time…） | 类型不匹配、地址非法 |
| FC/FB 调用 | 调用目标存在、参数与形参匹配 | 形参数量/类型不符 |

可选：传入**目标工程的 inventory** 做符号交叉检查——能提前发现"符号在工程里根本不存在"。**有工程变量表时一定要传**，这是最省事的一道防线。

**硬约束**：只要有一条 issue，**不产出 XML**。这不是限制，是保护——它挡掉的是"看起来合理、但博途拒绝导入"的块。

## 6. 失败判读

| 现象 | 原因 | 处理 |
|---|---|---|
| 反复校验不过、issue 越改越多 | 没对齐 schemaVersion | 重调 `lad_version`，按当前 schema 重写 |
| 校验过、导入被拒 | 目标博途版本/块名冲突/符号不存在 | 传 inventory 交叉检查；确认块名唯一 |
| XML 导入后逻辑不对 | LadDoc 的网络拓扑写错了（校验只保证"合语法"） | 用 PLC 云仿真（`/sim`）跑用例验证语义 |
| 生成被拒 | 上游有 issue 未清 | 先 `lad_validate`，`valid=true` 再生成 |
| 额度掉得快 | 每次 tools/call 扣 1 | 本地先人工核对结构，合并修改再一次校验 |

## 7. 与同类工具的分工

| 需求 | 用谁 |
|---|---|
| AI 生成**新的**梯形图块并导入博途 | **LadDoc Cloud（这里）** |
| 自然语言 → 在博途插件里直接画 LAD | TXT2LAD（博途 Add-In） |
| 已有 **LAD 块** → SCL 源码（迁移） | LAD2SCL（博途 Add-In） |
| 验证生成出来的逻辑对不对 | PLC 云仿真（`/sim`，逐扫描 + 场景 PASS/FAIL） |
| 在真实工程里落地（读回/编译/下载） | TiaLink（本地 MCP 网关） |

推荐闭环：**LadDoc Cloud 生成 → `/sim` 跑场景 → TiaLink 导入真实工程并编译读回**。每一层都有可验证的产物，不靠"看起来对"。

## 配套技能（同一套 TIA Forge 工作流）

这五个技能是一条链：**查文档 → 生成块 → 看图核对 → 跑验证 → 落地工程**。单独装一个能用，装齐才闭环。

| 技能 | 安装坐标 | 什么时候需要它 |
|---|---|---|
| 博途编程文档检索 | `@indiv-tiaforge/tia-portal-docs` | 不确定指令参数、引脚含义、版本行为 |
| LadDoc Cloud **← 你在这里** | `@indiv-tiaforge/laddoc-cloud` | 要把 LadDoc 生成成博途可导入的块 |
| 梯形图渲染 | `@indiv-tiaforge/lad-render-cloud` | 把 SimaticML 渲染成 PNG，导入前先看一眼 |
| PLC 云仿真 | `@indiv-tiaforge/plc-cloud-sim` | 生成后跑 PASS/FAIL、回归、边界用例 |
| TiaLink | `@indiv-tiaforge/tialink-tia-portal` | 在真实工程里编译、下载、读回 |

装齐的方式：把下面这句发给你正在用的 AI 助手（逐个发即可）：

```text
请根据 https://skillhub.cn/install/skillhub.md，安装 @indiv-tiaforge/<slug>
```

## 8. 获取与计费

| 项 | 说明 |
|---|---|
| 端点 | `https://tia.hubwiz.com/lad/mcp` |
| 开通 | 微信扫码登录即得 API Key；新用户 **100 次免费** |
| 计费 | `lad_version` / `initialize` / `tools/list` 不计费；`lad_validate`、`lad_generate` 各扣 1 次 |
| 额度包 | 1000 次 ¥9.90 / 5000 次 ¥29.90 / 15000 次 ¥69.90（一次性，无订阅） |
| 页面 | https://tia.hubwiz.com/lad?utm_source=dsh&utm_medium=plugin （含 MCP 配置指南） |

---

*汇智网（hubwiz.com）出品。TIA Portal、SIMATIC、S7 是 Siemens AG 的商标；本服务与 Siemens AG 无关。文档许可 CC BY 4.0。*
