/**
 * pi-tiaforge —— 把 TIA Forge 的五个 MCP 端点接进 pi。
 *
 * 技能不用写代码：pi 自己扫包的 `skills/` 目录（package.json 的 `pi.skills`）。
 * 本文件只负责 MCP：
 *   ① tialink  —— 本机网关（与博途同机），永远注册；没装网关时报一次连接错误，不影响其它功能
 *   ② 四个云端 —— 有对应 Key 才注册，没 Key 就不出现工具，也不会在启动时刷 401
 *
 * 覆盖方式：环境变量（TIALINK_URL / TIALINK_TOKEN / TIA_*_KEY）。
 * 文件配置（mcp.json / .pi/mcp.json）同名条目优先于这里的注册。
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const env = (name: string): string | undefined => {
  const value = process.env[name]?.trim();
  return value ? value : undefined;
};

/** 有 token 才带 Authorization，避免给不需要鉴权的本机网关塞空 Bearer。 */
const auth = (token: string | undefined) =>
  token ? { headers: { Authorization: `Bearer ${token}` } } : {};

/** 云端四家：服务名、Key 环境变量、端点、给模型看的一句话。 */
const CLOUD = [
  [
    "tia-docs",
    "TIA_DOCS_KEY",
    "https://tia.hubwiz.com/ai-coding-docs/mcp",
    "博途编程文档检索（2800+ 章节，get_docs）。",
  ],
  [
    "plc-sim",
    "TIA_SIM_KEY",
    "https://tia.hubwiz.com/sim/mcp",
    "PLC 云仿真：LAD/SCL 逐扫描执行 + 场景 PASS/FAIL。",
  ],
  [
    "laddoc",
    "TIA_LAD_KEY",
    "https://tia.hubwiz.com/lad/mcp",
    "LadDoc：梯形图 JSON → 博途可导入的 SimaticML。",
  ],
  [
    "lad-render",
    "TIA_RENDER_KEY",
    "https://tia.hubwiz.com/render/mcp",
    "梯形图渲染：SimaticML → PNG，导入博途前先看图核对（渲染计费）。",
  ],
] as const;

export default function tiaforge(pi: ExtensionAPI): void {
  // ① TiaLink 本机网关。编译/下载/RAM 读回都是长操作，超时给到 10 分钟。
  pi.registerMcpServer("tialink", {
    url: env("TIALINK_URL") ?? "http://127.0.0.1:8080/mcp",
    timeout: 600,
    description:
      "TiaLink：通过 TIA Portal Openness 操作本机博途工程（组态硬件、建块写 SCL、编译、下载、读回）。未授权时只读。",
    ...auth(env("TIALINK_TOKEN")),
  });

  // ② 云端服务，Key 缺省即跳过（技能正文仍然可用，只是没有对应工具）。
  for (const [name, keyVar, url, description] of CLOUD) {
    const key = env(keyVar);
    if (!key) continue;
    pi.registerMcpServer(name, {
      url,
      timeout: 180,
      description,
      headers: { Authorization: `Bearer ${key}` },
    });
  }
}
