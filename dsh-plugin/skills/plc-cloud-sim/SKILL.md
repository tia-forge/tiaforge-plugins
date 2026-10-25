---
name: plc-cloud-sim
slug: plc-cloud-sim
displayName: PLC 云仿真（免装博途）
version: 1.0.4
summary: 不装博途也能跑 PLC 逻辑：把 SCL 或 LadDoc 梯形图交给云端 MCP，逐扫描周期执行、回读变量、跑声明式场景拿 PASS/FAIL。含六个工具怎么选、场景怎么设计、报告怎么读。
description: 用云端 MCP 仿真 PLC 程序：校验 SCL 与 LadDoc 梯形图、逐扫描周期运行、回读变量与诊断、执行声明式场景（用例/穷举/模糊/不变量）得到 PASS/FAIL 报告。当用户要"验证 AI 写的 PLC 代码"、"不装博途先跑一遍逻辑"、"起保停/状态机回归"、"给梯形图写测试用例"时使用。不需要博途，程序片段会上传云端。
license: CC-BY-4.0
homepage: https://tia.hubwiz.com/sim?utm_source=dsh&utm_medium=plugin
metadata:
  publisher: 汇智网 (hubwiz.com)
  transport: MCP Streamable HTTP（https://tia.hubwiz.com/sim/mcp + API Key）
  tools: lad_validate, lad_simulate, lad_run_scenario, scl_validate, scl_simulate, scl_run_scenario
  billing: 新用户 100 次免费；之后按额度包（1000 次 ¥9.90 起）；initialize / tools/list 不计费
---

# PLC 云仿真 —— 让 AI 写的 PLC 代码先跑起来

**一句话**：这是**程序级**仿真，不是整机仿真。给它 SCL 源码或 LadDoc（JSON 格式的梯形图文档），它逐扫描周期执行、回读变量、按场景出 PASS/FAIL —— **不需要博途，也不需要硬件**。

| | 本服务（`/sim`） | PLCSIM Advanced | BLOCK-SIM |
|---|---|---|---|
| 跑什么 | **程序逻辑**（单块/多块） | 整机/控制器，含硬件组态 | 程序块（博途内） |
| 要不要博途 | ❌ 不要 | ✅ 要 | ✅ 要（Add-In） |
| 形态 | 云端 MCP | 本机软件 | 博途插件 |
| 适合 | AI 写码后的快速回归、批量验收 | 联调、通信、整机行为 | 已在博途里工作的工程师 |

> ⚠️ **同上但不同物**：BLOCK-SIM 是博途 Add-In（在博途内部做块级验证）；这里说的是**云端 MCP**（在 AI 客户端里跑，不碰工程）。

## 0. 三条先决条件（先看，省一半弯路）

| # | 条件 | 说明 |
|---|---|---|
| 1 | **微信扫码登录**拿 API Key | 扫码即开通，无需注册；Key 服务端只存 SHA-256 哈希，明文只显示一次 |
| 2 | 客户端支持 **Streamable HTTP + 自定义 header** | 端点 `https://tia.hubwiz.com/sim/mcp` |
| 3 | **程序片段会上传到云端** | 服务端保存执行所需的输入。**产线机密、不能出内网的工程不要用它** —— 那种场景用本地的 TiaLink |

**红线**：不要把客户真实工程的完整源码贴进来做"随便试试"。脱敏、片段化、只保留复现问题所需的最小逻辑。

## 1. 连接（各客户端）

```json
{
  "mcpServers": {
    "plc-sim": {
      "type": "http",
      "url": "https://tia.hubwiz.com/sim/mcp",
      "headers": { "Authorization": "Bearer <你的 API Key>" }
    }
  }
}
```

- Claude Code / Cursor / VS Code：直接贴上面的片段（Cursor 选 `http` transport）。
- **WorkBuddy**：写进 `~/.workbuddy/mcp.json`，或用「插件 → MCP 服务器 → 配置 MCP」粘贴。
- **DeepSeek Harness**：在 profile 的 `cordis.patch.yml` 里加一条 `@deepseek-ai/dsh-mcp-client` 条目（原生支持 Streamable HTTP）。

**计费口径**（照这个设计调用次数）：`initialize` / `tools/list` **不计费**；每次 `tools/call` 扣 1 次。**不要**把 `*_validate` 放进循环里反复试——把校验当"编译"，一次改到位再跑。

## 2. 六个工具怎么选

| 要做的事 | 梯形图（LadDoc） | SCL 源码 |
|---|---|---|
| 先看程序对不对（语法/结构/接口） | `lad_validate` | `scl_validate` |
| 给一组输入，跑一个扫描周期，读回变量 | `lad_simulate` | `scl_simulate` |
| 跑一组用例/穷举/模糊/不变量，出 PASS/FAIL | `lad_run_scenario` | `scl_run_scenario` |

选择顺序：**validate → simulate（单点验证 1 条路径）→ run_scenario（回归全集）**。
单点都没过就上场景，只会拿到一堆无法定位的 FAIL。

工具的精确参数以 `tools/list` 返回的 schema 为准（**别凭记忆拼字段名**）；LadDoc 的 schema 版本以 `lad_version` 为准（/lad 服务提供 `lad_version`，可用来对齐 lad-ir 版本）。

## 3. 标准工作序（照抄）

```text
第一步：确认能力与计费
1) 调 tools/list，列出你能用的工具和参数；
2) 说明哪几个调用会计费（每次 tools/call 扣 1 次），不要现在就批量跑。

第二步：校验优先（不算跑通）
把下面这段 SCL 交给 scl_validate，只回：
- valid 是否为 true；
- 如果 false，把每条 issue 的 code / path / message 原文列出（不要改写、不要猜测修法）。

<贴 SCL>

第三步：单点仿真（一次只验一条路径）
用 scl_simulate 跑一个扫描周期，输入：
- 变量表：<变量=值>
- 预期：<哪个输出应当是 TRUE/FALSE>
回读所有输出变量与诊断信息，按「变量 / 期望 / 实测」三列给我。

第四步：场景化回归（确认前三步都过了再做）
把下面场景交给 scl_run_scenario，只回 PASS/FAIL 与失败用例的证据：
- 正常启动：Start=TRUE 持续 3 个周期 → Run=TRUE
- 反馈超时：Start=TRUE, Feedback 一直 FALSE → 5s 后 Fault=TRUE
- 复位竞争：Fault=TRUE 时按 Reset → 只清 Fault，不复位 Run
- 不变量：任何周期都不允许 Run 与 Fault 同时为 TRUE
```

## 4. 场景怎么设计（这是真正决定价值的一步）

四类场景，按"先便宜后昂贵"的顺序写：

| 类型 | 写什么 | 例子 |
|---|---|---|
| **脚本用例**（必写） | 正常流 + 每个异常分支各一条 | 启动/停止/急停/复位/重复触发 |
| **穷举矩阵** | 3–4 个布尔输入的全组合 | 8 种启停组合里哪些会输出双 TRUE（危险） |
| **种子化模糊** | 固定 seed 的随机序列 | 传感器抖动、触点抖动、扫描抖动 |
| **always 不变量** | 任何时刻都必须成立的断言 | `NOT (Run AND Fault)`、`Fault → 输出已断电` |

工程要点：

- **不变量比用例更值钱**。用例只证明"这条路对"，不变量证明"任何路都不炸"。
- **模糊测试必须固定 seed**，否则复现不了、报告无法归档。
- **定时器/计数器要显式给扫描周期**，并且知道仿真用的是固定周期还是按调用推进——否则"5 秒超时"的验证没有意义。
- 首次扫描/上电初始化要单独一条用例（这类问题只在断电重启后暴露）。

## 5. 失败判读

| 现象 | 含义 | 处理 |
|---|---|---|
| `valid=false` + 一堆 issue | 程序没通过静态校验 | 按 `path` 逐个改；**不要**绕过校验直接仿真 |
| 仿真结果与手算不一致 | 多半是扫描语义差异（边沿/保持/顺序） | 检查边沿存储位、置位复位、多重写序 |
| 定时器行为对不上 | 扫描周期假设不一致 | 明确周期或用例里给足周期数 |
| 场景 PASS 但真机不对 | 仿真只覆盖逻辑，不覆盖硬件/通信/时序抖动 | 用 PLCSIM 或真机补；见下图 |
| 调用被拒 / 额度很快见底 | 每次 `tools/call` 扣 1 | 合并调用、先本地手算筛掉明显错误 |

**分层验证**（别指望一层兜住所有问题）：

```
① 块级逻辑      → PLC 云仿真（这里，最快最便宜）
② 整机/通信     → PLCSIM Advanced + 真实组态
③ 现场时序/安全 → 真机 + 硬件安全回路（不可省）
```

## 6. 什么时候**不要**用它

- 逻辑涉及**安全功能**（急停、安全门、光幕）：安全逻辑必须在安全 PLC/安全继电器里验证，不能用普通逻辑仿真"证明安全"。
- 程序**不能出内网**：改用本地 TiaLink（工程数据不出内网）。
- 需要验证**硬件组态、通信、IO 映射**：那是 PLCSIM Advanced / 真机的活。
- 只是想"跑一下看看"：先 `*_validate`，不合格别浪费额度。

## 配套技能（同一套 TIA Forge 工作流）

这四个技能是一条链：**查文档 → 生成块 → 跑验证 → 落地工程**。单独装一个能用，装齐才闭环。

| 技能 | 安装坐标 | 什么时候需要它 |
|---|---|---|
| 博途编程文档检索 | `@indiv-tiaforge/tia-portal-docs` | 不确定指令参数、引脚含义、版本行为 |
| LadDoc Cloud | `@indiv-tiaforge/laddoc-cloud` | 要把 LadDoc 生成成博途可导入的块 |
| PLC 云仿真 **← 你在这里** | `@indiv-tiaforge/plc-cloud-sim` | 生成后跑 PASS/FAIL、回归、边界用例 |
| TiaLink | `@indiv-tiaforge/tialink-tia-portal` | 在真实工程里编译、下载、读回 |

装齐的方式：把下面这句发给你正在用的 AI 助手（逐个发即可）：

```text
请根据 https://skillhub.cn/install/skillhub.md，安装 @indiv-tiaforge/<slug>
```

## 7. 获取与计费

| 项 | 说明 |
|---|---|
| 端点 | `https://tia.hubwiz.com/sim/mcp`（Streamable HTTP） |
| 开通 | 微信扫码登录即得 API Key，无需注册；新用户 **100 次免费** |
| 计费 | 每次 `tools/call` 扣 1 次；`initialize` / `tools/list` 不计费 |
| 额度包 | 1000 次 ¥9.90 / 5000 次 ¥29.90 / 15000 次 ¥69.90（一次性，无订阅无月费） |
| 页面 | https://tia.hubwiz.com/sim?utm_source=dsh&utm_medium=plugin （含 MCP 配置指南） |

---

*汇智网（hubwiz.com）出品。TIA Portal、SIMATIC、S7、PLCSIM 是 Siemens AG 的商标；本服务与 Siemens AG 无关。文档许可 CC BY 4.0。*
