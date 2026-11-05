# Privacy / 数据与隐私说明

TIA Forge is a Claude Code plugin published by 汇智网 (hubwiz.com). This page covers the plugin itself: what the five skills send, where it goes, and what stays on your machine.

## What leaves your machine

The plugin contacts a service only when a skill that needs it runs. Each request goes to one endpoint, carries the API key you configured, and contains nothing else.

| Skill | Endpoint | Data sent |
|---|---|---|
| `tia-portal-docs` | `https://tia.hubwiz.com/ai-coding-docs/mcp` | the documentation query you asked for |
| `laddoc-cloud` | `https://tia.hubwiz.com/lad/mcp` | the block description and ladder specification you gave the skill |
| `lad-render-cloud` | `https://tia.hubwiz.com/render/mcp` | the SimaticML program to be rendered |
| `plc-cloud-sim` | `https://tia.hubwiz.com/sim/mcp` | the LAD/SCL program and the test inputs |
| `tialink-tia-portal` | the gateway URL you configured (default `http://127.0.0.1:8080/mcp`) | nothing leaves the machine. The gateway drives TIA Portal over Openness locally, and its licence works offline |

There is no telemetry, no crash reporting, no analytics and no other endpoint. Project files, tag tables and block sources stay on your machine unless you run one of the four cloud skills on them.

## What the cloud services retain

The four cloud endpoints are metered API services. They process a request, return a result and record usage against your key (a count and a timestamp, so quotas can be enforced). Keys are per-account and can be revoked in the console at <https://tia.hubwiz.com>.

## Credentials

API keys and the TiaLink token are collected by the plugin's configuration form. Sensitive values are stored in the client's secure storage rather than in a plain settings file, and are sent only to the endpoint they belong to, in an `Authorization: Bearer` header. They are never written into this repository or into generated files.

## Contact

Data controller: 汇智网 (hubwiz.com), China. Questions or deletion requests: <support@hubwiz.com>. Company-wide terms published at <https://www.hubwiz.com> apply in addition to this page.

---

本页说明 TIA Forge 插件本身的数据流向：只有你调用的那个技能会联网，请求只发往它对应的一个端点，只带该端点的 Key，不含其他内容；本地 `tialink` 网关不向外发送任何工程数据（授权离线可用）；插件无遥测、无统计。云端四个服务只记录配额计数与时间戳。Key 与令牌保存在客户端安全存储，只以 Bearer 头发往所属端点。联系方式：support@hubwiz.com。
