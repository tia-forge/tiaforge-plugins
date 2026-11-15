# 豆包（豆包工作）技能包

让豆包能读写真实的西门子博途（TIA Portal）工程：查文档、生成梯形图、先看图核对、云端跑仿真、在工程里编译下载读回。

六个 zip，一个 zip 一个技能，包根目录就是 `SKILL.md`。

下载：<https://github.com/tia-forge/tiaforge-plugins/releases/tag/doubao-1.0>

## 三步装

1. 打开豆包客户端 → 左侧「**插件 · 技能 · 伙伴**」→ 切到「**技能**」；
2. 右上角「**+ 添加**」→「**上传技能**」→ 选 zip（不用解压）；
3. 传完新建一个任务，试一句：`查一下 S7-1500 里 TON 的引脚定义`。

## 六个包，建议先装前两个

| zip | 装完能干什么 | 前置 |
|---|---|---|
| `tia-portal-docs-1.0.9.zip` | 查博途官方文档（2 800+ 章节） | 一把 Key |
| `tialink-tia-portal-1.0.10.zip` | 直接操作真实工程：建块、写 SCL、编译、下载仿真、读回 | 本机装 TiaLink（与博途同机） |
| `laddoc-cloud-1.0.8.zip` | LadDoc → 博途可导入的 SimaticML | 一把 Key |
| `lad-render-cloud-1.0.2.zip` | SimaticML → PNG，导入前先看一眼 | 一把 Key（每次渲染扣 1 次） |
| `plc-cloud-sim-1.0.8.zip` | 云端逐扫描仿真 + 场景 PASS/FAIL | 一把 Key |
| `plc-programming-ai-tutor-1.0.0.zip` | PLC 编程一对一训练，按判据判 PASS/FAIL | 无 |

每把 Key 100 次免费：<https://tia.hubwiz.com/tia-link>

## 怎么确认"真接上了"

说这句：`连接 http://127.0.0.1:8080/mcp，告诉我现在打开的是哪个工程、有几台设备`。

- 报出**你屏幕上的工程名和设备型号** = 真接上了；
- 给你一段代码或"建议你这样操作" = **没接上**，它在凭记忆答。

## 已知限制

- **TiaLink 是本地网关**，必须与博途同一台 Windows；豆包是云端模型，所以要用**桌面客户端**（能访问 `127.0.0.1`）。
- 没装 TiaLink 时，`tialink-tia-portal` 会走只读或直接报错——先装网关再试。
- 技能装在你自己这台机器上，换电脑要重新装；别人要用，把 zip 给他。
