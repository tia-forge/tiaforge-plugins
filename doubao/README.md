# 豆包（豆包工作）接西门子博途

豆包支持两种扩展，配合用最顺：

- **连接器（插件）** 给「工具」：让豆包真的能读写工程；
- **技能** 给「流程」：告诉它什么时候用、按什么步骤、怎么判断成败。

两者都自己装，几分钟。

---

## 零、一次装完：上传插件包（4 个云服务 + 6 个技能）

下载 [`tiaforge-doubao-plugin-1.0.0.zip`](https://github.com/tia-forge/tiaforge-plugins/releases/download/doubao-1.0/tiaforge-doubao-plugin-1.0.0.zip)（41 KB）→ 客户端「插件」页 →「+ 添加」→ 上传插件包 → 选 zip，不用解压。

包里有什么：

- **6 个技能**（`skills/`）
- **4 个云服务连接**（`mcp.json`）：文档检索 / 云仿真 / LadDoc / 梯形图渲染
- **4 份鉴权声明**（`com.doubao/auth/*.json`）：装上后每个服务会问你要一次 API Key（各 100 次免费）

⚠️ **包里没有 TiaLink，这是规范限制，不是漏装**：`mcp.json` 的 `url` 必须是**公网 HTTPS 绝对地址**，**禁止 localhost / 127.0.0.1 / ::1**，也不支持本地进程形式。所以"操作真实工程"必须单独加一个自定义连接器：

- HTTP：`http://127.0.0.1:8080/mcp` + Header `Authorization: Bearer <你的 token>`
- 或 STDIO：`npx -y tialink-mcp`（环境变量 `TIALINK_URL` / `TIALINK_TOKEN`）

两种形态的分工就是这一条决定的：**插件包一次性给四个云服务 + 六个技能；本机那一条靠自定义连接器。**

---

## 一、单独加连接器（插件页，填表）

左侧「**插件 · 技能 · 伙伴**」→「**插件**」→ 右上角「**+ 添加**」→「**新建自定义连接器**」，按下表填。

| 名称（随便起） | 传输 | 服务器 URL | Header 名称 | Header 值 |
|---|---|---|---|---|
| 博途工程 TiaLink | HTTP | `http://127.0.0.1:8080/mcp` | `Authorization` | `Bearer <TIALINK_TOKEN>` |
| 博途文档检索 | HTTP | `https://tia.hubwiz.com/ai-coding-docs/mcp` | `Authorization` | `Bearer <TIA_DOCS_KEY>` |
| PLC 云仿真 | HTTP | `https://tia.hubwiz.com/sim/mcp` | `Authorization` | `Bearer <TIA_SIM_KEY>` |
| LadDoc | HTTP | `https://tia.hubwiz.com/lad/mcp` | `Authorization` | `Bearer <TIA_LAD_KEY>` |
| 梯形图渲染 | HTTP | `https://tia.hubwiz.com/render/mcp` | `Authorization` | `Bearer <TIA_RENDER_KEY>` |

- Header 值里的 `Bearer` 后面**有一个空格**；密钥就是 Key 本身（不带前缀）。
- 四把云端 Key 各 100 次免费：<https://tia.hubwiz.com/tia-link>
- ⚠️ `梯形图渲染` 是**计费**的：每渲染一张图扣 1 次额度（查版本免费）。

### 不想填 HTTP 头？用 STDIO

TiaLink 也能走本地命令：传输选 **STDIO**，

```
运行命令: npx
参数:      -y tialink-mcp
环境变量:  TIALINK_URL=http://127.0.0.1:8080/mcp
          TIALINK_TOKEN=<你的 token>
```

---

## 二、装 6 个技能（技能页，上传 zip）

技能页 → 右上角「**+ 添加**」→「**上传技能**」→ 选 zip（不用解压）。
下载：<https://github.com/tia-forge/tiaforge-plugins/releases/tag/doubao-1.0>

| zip | 装完能干什么 | 前置 |
|---|---|---|
| `tia-portal-docs-1.0.9.zip` | 查博途官方文档（2 800+ 章节） | 文档检索 Key |
| `tialink-tia-portal-1.0.10.zip` | 直接操作真实工程：建块、写 SCL、编译、下载仿真、读回 | 本机装 TiaLink |
| `laddoc-cloud-1.0.8.zip` | LadDoc → 博途可导入的 SimaticML | LadDoc Key |
| `lad-render-cloud-1.0.2.zip` | SimaticML → PNG，导入前先看一眼 | 渲染 Key（计费） |
| `plc-cloud-sim-1.0.8.zip` | 云端逐扫描仿真 + 场景 PASS/FAIL | 仿真 Key |
| `plc-programming-ai-tutor-1.0.0.zip` | PLC 编程一对一训练，按判据判 PASS/FAIL | 无 |

技能和连接器是两回事：只装技能、没加连接器，豆包知道该怎么做但**没有手**；只加连接器、没装技能，它有手但不知道你的流程。

---

## 三、怎么确认"真接上了"

在对话里说：

> 连接 http://127.0.0.1:8080/mcp，告诉我现在打开的是哪个工程、有几台设备

- 报出**你屏幕上的工程名和设备型号** → 真接上了；
- 给你一段代码、或者说"建议你这样操作" → **没接上**，它在凭记忆答。

工程名它编不出来，这是最省事的判据。

---

## 四、已知限制

- **TiaLink 是本地网关**，必须与博途同一台 Windows。豆包是云端模型，所以要用**桌面客户端**（能访问 `127.0.0.1`），网页版不行。
- 没装 TiaLink 时，连接器会连不上、对应工具不出现——**先装网关再试**，别先怀疑技能。
- 连接器和技能都装在**你自己这台机器**上，换电脑要重配；别人要用，把这份说明和 zip 给他。
- 未激活的 TiaLink 是**只读**的：能读工程、不能写，也不会擅自动你的工程。
