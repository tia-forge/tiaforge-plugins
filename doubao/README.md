# 豆包（豆包工作）接西门子博途

豆包支持两种扩展：

- **插件包** = 技能 + 连接一起装（**推荐，一次装完**）
- **自定义连接器 / 上传技能** = 九手单装，用来补插件包补不了的那一条

最省事的顺序：**装插件包 → 再补一条 TiaLink 连接器 → 用一句话验证。** 三分钟。

---

## 零、一次装完（推荐）：上传插件包 —— 6 技能 + 5 个连接

下载 [`tiaforge-doubao-plugin-1.0.3.zip`](https://github.com/tia-forge/tiaforge-plugins/releases/download/doubao-1.0/tiaforge-doubao-plugin-1.0.3.zip)（41 KB）→ 客户端「插件」页 →「+ 添加」→ 上传插件包 → 选 zip，不用解压。

包里有什么：

- **6 个技能**（`skills/`，界面显示中文名：博途工程直连 / 博途文档检索 / LadDoc 转 SimaticML / 梯形图渲染 / PLC 云仿真 / PLC 编程教练）
- **5 个服务连接**（`mcp.json`）：**TiaLink 本机网关** + 文档检索 + 云仿真 + LadDoc + 梯形图渲染
- **4 份鉴权声明**（`com.doubao/auth/*.json`）：云端四个服务各问你要一次 Key（每把 100 次免费）
- **TiaLink 故意不带鉴权文件**：网关默认没开令牌，硬塞一个必填令牌框会让人装完卡住。**只有你的网关开了令牌**，才需要补一个 `com.doubao/auth/tialink.json`：
  ```json
  {"credentials":[{"id":"apiKey","label":"TiaLink 令牌","description":"网关控制台 http://localhost:8080/ 里查看","required":true,"secret":true}],
   "injections":[{"target":"header","name":"Authorization","value":"Bearer ${apiKey}"}]}
  ```

### 唯一要改的地方：TiaLink 的 IP

包里的 TiaLink 默认写 `http://127.0.0.1:8080/mcp`。**网关不在你这台机器上时，把它改成那台 Windows 的局域网 IP**，例如 `http://192.168.1.110:8080/mcp`：

```
…\workspace\plugins\<id>\mcp.json      ← 改这一行
…\workspace\plugins\<id>\plugin.json   ← 只改 IP 的话这里不用动
```

或者更省事：**直接在对话里说「网关在 192.168.1.110:8080」，它会自己改完并提示你重启**（2026-11-15 原生实测，它还会先把原文件备份一份）。

> ⚠️ 让它自己改的时候，**要说清是豆包的插件配置**。实测有一回它把 tialink 写进了 `C:\Users\<你>\.workbuddy\mcp.json`——那是另一个客户端的配置，豆包读不到。豆包这份在 `…\workspace\plugins\<id>\mcp.json`。

> **改完必须完全退出豆包客户端再打开**，MCP 连接是启动时建立的；不重启的话当前会话认不到 `tialink` 的工具，表现得像没装上。


### 为什么"地址每次都要重讲"（三个原因，按概率排）

| # | 原因 | 30 秒怎么判 | 怎么修 |
|---|---|---|---|
| **1** | **改完没重启客户端**。MCP 连接在**启动时**建立，改完文件当前会话就是看不到工具 | 会话里没有 `tialink` 开头的工具、只有它现场用命令/curl 连 | 完全退出豆包（托盘也退）再打开，然后**新开一个任务** |
| **2** | **手改的是包内副本，启动时被还原**（插件来自 zip，`…"+BS+"workspace"+BS+"plugins"+BS+"<id>"+BS+"mcp.json` 属于包） | 重启后那个连接器的 URL 又变回 `127.0.0.1:8080` | 别改包。**网关不在本机**的人，把包里那条 tialink 关掉，改用「+ 添加 → 新建自定义连接器」加一条 `http://<网关IP>:8080/mcp` —— 自定义连接器是**用户级配置**，重启不丢 |
| **3** | **改错了文件**（写到 `~"+BS+".workbuddy"+BS+"mcp.json` 或 `~"+BS+".pi"+BS+"agent"+BS+"mcp.json`） | 那些文件里有 `tialink`，但豆包的连接器列表里 URL 没变 | 豆包只读自己的插件目录与自定义连接器；把别处的 tialink 删掉，免得以后误判 |

> 一句话：**本机网关 → 用包里那条（127.0.0.1）；跨机网关 → 用自定义连接器。** 包内那条是随包配置，不适合当"长期可改"的地方。

> 如果这一版客户端拒绝带 `127.0.0.1` 的包（部分版本会按公网规则校验），用 [`1.0.0`](https://github.com/tia-forge/tiaforge-plugins/releases/download/doubao-1.0/tiaforge-doubao-plugin-1.0.0.zip)（只有 4 个云服务），再按下面第一节手工加一条 TiaLink。

---

## 一、再补一条连接器：TiaLink（本机工程的那条）

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

## 二、备选：只想装某一个技能（散装 zip）

插件包已经包含全部 6 个技能。**只有这两种情况才需要下面这套**：① 只想装其中一个、不想要云连接；② 上传插件包那步在你这版客户端里走不通。

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
