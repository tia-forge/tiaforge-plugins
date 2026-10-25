---
name: tia-portal-docs
slug: tia-portal-docs
displayName: 博途编程文档检索
version: 1.0.5
summary: 让 AI 查博途官方编程文档而不是凭记忆猜：2800+ 编程章节（函数块、指令、数据类型、系统常量）做成一个 MCP 工具 get_docs，语义检索直接给出处。含 8 个高频提问模板与「topic 怎么写才召回准」。
description: 检索西门子 TIA Portal（博途/博图）官方编程文档：函数块用法、指令参数与边沿语义、数据类型与取值范围、系统常量、错误代码。当用户问"这个指令怎么用""TON 和 TONR 区别""S7-1500 定时器最大时长""某个系统常量是什么"或需要核对 API 参数时使用。比模型记忆可靠，因为博途文档随版本变。
license: CC-BY-4.0
homepage: https://tia.hubwiz.com/ai-coding-docs?utm_source=workbuddy-plugin&utm_medium=plugin
metadata:
  publisher: 汇智网 (hubwiz.com)
  transport: MCP Streamable HTTP（https://tia.hubwiz.com/ai-coding-docs/mcp，协议 2025-03-26）
  tools: get_docs（library=tia-programming@1.0, topic=问题）
  coverage: 2800+ 编程章节
  billing: 新用户 100 次免费；每次 get_docs 扣 1 次；额度包 1000 次 ¥9.90 起
---

# TIA Portal Docs —— 让 AI 查文档，而不是背指令

**一句话**：模型对博途指令的记忆是**模糊且版本相关**的（参数名、边沿语义、定时器上限、系统常量），而这里是 **2800+ 个官方编程章节**接成的 MCP 工具 `get_docs`：你把问题丢进去，它语义检索后返回章节内容。

| 用它 | 不要用它 |
|---|---|
| 查**指令/函数块**的参数与行为 | ❌ 不能用它读你的工程（那是 TiaLink） |
| 核对**数据类型/取值范围/系统常量** | ❌ 不能跑逻辑（那是 PLC 云仿真 `/sim`） |
| 确认**版本相关**的行为差异 | ❌ 不能生成梯形图（那是 LadDoc Cloud `/lad`） |

## 0. 先决条件

| # | 条件 | 说明 |
|---|---|---|
| 1 | 微信扫码登录拿 API Key | 控制台 → 「更换密钥」生成；**新密钥只显示一次，旧密钥全部立即失效** |
| 2 | 客户端支持 Streamable HTTP | 端点 `https://tia.hubwiz.com/ai-coding-docs/mcp` |
| 3 | 知道计费口径 | **每次 `get_docs` 扣 1 次额度**；新用户 100 次免费 |

> ⚠️ **换密钥会把旧的全废掉**。如果团队共用一把 key，换之前先说一声，否则别人那边会突然 401。

## 1. 连接

```bash
# Claude Code
claude mcp add --transport http tia https://tia.hubwiz.com/ai-coding-docs/mcp \
  -H "Authorization: Bearer <YOUR_API_KEY>"
```

```json
{
  "mcpServers": {
    "tia-docs": {
      "type": "http",
      "url": "https://tia.hubwiz.com/ai-coding-docs/mcp",
      "headers": { "Authorization": "Bearer <YOUR_API_KEY>" }
    }
  }
}
```

- Cursor：`.mcp.json`（项目）或 `~/.cursor/mcp.json`（全局），transport 选 `http`。
- VS Code：`.vscode/mcp.json`，注意 key 是 `servers` 不是 `mcpServers`。
- **WorkBuddy**：`~/.workbuddy/mcp.json` 或「插件 → MCP 服务器 → 配置 MCP」。
- **DeepSeek Harness**：profile 的 `cordis.patch.yml` 里加 `@deepseek-ai/dsh-mcp-client` 条目。
- 协议版本 `2025-03-26`；请求头除了 `Authorization: Bearer` 也接受 `X-API-Key`。

## 2. 调用契约（只有一个工具，但参数要写对）

```json
{
  "library": "tia-programming@1.0",
  "topic": "TON 定时器在 S7-1500 上的实例声明方式与最大延时"
}
```

| 参数 | 固定值 / 怎么写 |
|---|---|
| `library` | **固定 `tia-programming@1.0`**（写错就查不到） |
| `topic` | 写成**一个问题**，带上元件名 + 场景，不要只写关键词 |


> **两次查询是正常的**：`get_docs` 返回的参数表在长表格处可能被截断。
> 看到截断就**带着更具体的问题再查一次**（例如"LAD 里 TON 的四个引脚 名称/类型/含义"），不要拿半张表去写代码。
> 同理：一个 `topic` 里混了两个问题（"TON 和 TOF 有什么区别、各自怎么接线"）会两边都答不全，拆开查。

**`topic` 的好坏直接决定召回质量**：

| ❌ 差 | ✅ 好 |
|---|---|
| `TON` | `TON 定时器的 IN/PT/Q/ET 四个引脚含义，PT 的时间格式怎么写` |
| `数组` | `S7-1500 里 DB 中声明二维数组并遍历，ARRAY[1..10,1..5] of Int 的索引写法` |
| `报错` | `下载时报 "该块不能被编译" 的常见原因与排查顺序` |

## 3. 八个高频提问模板（直接抄）

```text
1) 指令语义：<指令名> 的每个引脚/参数的名称、类型、含义是什么？哪些参数可省略？
2) 边沿行为：<指令> 在冷启动/热启动第一个扫描周期会不会误触发？
3) 数据类型：<类型> 的取值范围、精度、与相邻类型转换时的溢出行为？
4) 定时器/计数器：<型号> 的最大计时/计数范围，超出后会怎样？
5) 系统常量：<常量名> 的定义与典型用途？
6) 诊断：报错/诊断缓冲区条目 <原文> 的官方解释与处理建议？
7) 版本差异：<指令/功能> 在 V19 与更早版本之间有没有行为变化？
8) 通信/组态：<协议/接口> 在博途侧需要哪些组态步骤与参数？
```

**用它的正确姿势**：先查文档 → 再写代码 → 再用仿真验证（`/sim`）。三步都有可核对产物，不靠"模型觉得对"。

## 4. 失败判读

| 现象 | 原因 | 处理 |
|---|---|---|
| `401` / `403` | key 错、过期，或**别人刚换了密钥**（旧的立即失效） | 控制台重新取 key，或用 `X-API-Key` 头发 |
| 工具返回"额度耗尽"提示 | 100 次免费已用完 | 按需买额度包；别拿它当"每写一行代码都查一次" |
| 协议握手失败 | 客户端把 transport 当 SSE 或 stdio | 选 `http` / `streamable-http`，协议 `2025-03-26` |
| 返回内容不相关 | `topic` 太短或混了多个问题 | 拆成单个问题重问；一次只问一件事 |
| 答得对但版本不对 | 文档覆盖版本与你现场不一致 | 在 `topic` 里写明版本（如"V19"） |

## 配套技能（同一套 TIA Forge 工作流）

这四个技能是一条链：**查文档 → 生成块 → 跑验证 → 落地工程**。单独装一个能用，装齐才闭环。

| 技能 | 安装坐标 | 什么时候需要它 |
|---|---|---|
| 博途编程文档检索 **← 你在这里** | `@indiv-tiaforge/tia-portal-docs` | 不确定指令参数、引脚含义、版本行为 |
| LadDoc Cloud | `@indiv-tiaforge/laddoc-cloud` | 要把 LadDoc 生成成博途可导入的块 |
| PLC 云仿真 | `@indiv-tiaforge/plc-cloud-sim` | 生成后跑 PASS/FAIL、回归、边界用例 |
| TiaLink | `@indiv-tiaforge/tialink-tia-portal` | 在真实工程里编译、下载、读回 |

装齐的方式：把下面这句发给你正在用的 AI 助手（逐个发即可）：

```text
请根据 https://skillhub.cn/install/skillhub.md，安装 @indiv-tiaforge/<slug>
```

## 5. 计费与获取

| 项 | 说明 |
|---|---|
| 端点 | `https://tia.hubwiz.com/ai-coding-docs/mcp`（streamable-http，协议 2025-03-26） |
| 开通 | 微信扫码登录即得 API Key，无需注册；**新用户 100 次免费** |
| 计费 | 每次 `get_docs` 扣 1 次；额度包 1000 次 ¥9.90 / 5000 次 ¥29.90 / 15000 次 ¥69.90（一次性，无订阅） |
| 控制台 | 登录后 `/dashboard` → 「更换密钥」 |
| 页面 | https://tia.hubwiz.com/ai-coding-docs?utm_source=workbuddy-plugin&utm_medium=plugin |

---

*汇智网（hubwiz.com）出品。TIA Portal、SIMATIC、S7 是 Siemens AG 的商标；本服务与 Siemens AG 无关，内容为检索自公开文档的编程参考。文档许可 CC BY 4.0。*
