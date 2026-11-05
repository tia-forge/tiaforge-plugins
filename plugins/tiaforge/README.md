# TIA Forge

Siemens TIA Portal (博途) automation for Claude Code: five skills and four slash commands that search TIA documentation, generate LAD/SCL blocks, render SimaticML to PNG for a visual check, run cloud simulation, and drive a real TIA Portal project through the TiaLink MCP gateway. 博途工程自动化：从查文档、生成块、看图核对、仿真验证，一直到在真实工程里组态、编译、下载、读回。

## What's inside

| Component | What it does |
|---|---|
| `tia-portal-docs` skill | Search 2,800+ sections of TIA Portal documentation instead of guessing an instruction or a parameter |
| `laddoc-cloud` skill | Turn a described interlock/sequence into a SimaticML LAD block, then import it into the project |
| `lad-render-cloud` skill | Render SimaticML back to a PNG so Claude can look at the diagram it produced (metered) |
| `plc-cloud-sim` skill | Run the block scan-by-scan with test inputs and return PASS/FAIL per case |
| `tialink-tia-portal` skill | Operate a real project through the TiaLink gateway: hardware and networks, FB/FC/DB, compile, download, read back |
| `/tiaforge:tia-status` | Read-only health check: gateway, TIA version, project, device and block lists |
| `/tiaforge:tia-hw-add` | Configure a rack and network in the open project |
| `/tiaforge:tia-block` | Create a block and write its SCL |
| `/tiaforge:tia-verify` | Three-layer verification: compile, simulate, read back |

## Install

```bash
/plugin marketplace add tia-forge/tiaforge-plugins
/plugin install tiaforge@tia-forge
```

## Requirements

| Need | Detail |
|---|---|
| Claude Code | Skills and slash commands load in any Claude Code session. |
| TiaLink gateway (optional) | Only the `tialink` MCP needs it: Windows 64-bit, a licensed TIA Portal **V19 / V20 / V21**, the Windows account in the local *Siemens TIA Openness* group, and the TiaLink gateway itself (paid software, 汇智网). Read-only without a licence. |
| Cloud API keys (optional) | Each of the four cloud skills needs its own key from <https://tia.hubwiz.com> (100 free runs each; render is metered per image). Get only the ones you use. |

Nothing else is required: without a gateway or keys the plugin still loads, and only the parts you configured will work.

## Configuration

The `tialink` endpoint and token are asked for by the plugin's own configuration form (Claude Code stores the token in secure storage, not in `settings.json`):

| Field | Default | Meaning |
|---|---|---|
| TiaLink gateway URL | `http://127.0.0.1:8080/mcp` | Where the local gateway listens. Leave as is for the standard install. |
| TiaLink token | empty | The Bearer token your gateway was configured with. Leave empty if it has none. |

No TiaLink installation? Leave both empty — the `tialink` server simply fails to connect, and the four cloud skills are unaffected.

## Network and data

Each skill talks only to the endpoint it needs, and the plugin sends nothing else — no telemetry, no analytics, no third-party endpoints.

| Skill | Destination | What is sent |
|---|---|---|
| `tia-portal-docs` | `https://tia.hubwiz.com/ai-coding-docs/mcp` | your documentation query |
| `laddoc-cloud` | `https://tia.hubwiz.com/lad/mcp` | the block description and ladder specification you gave it |
| `lad-render-cloud` | `https://tia.hubwiz.com/render/mcp` | the SimaticML it is asked to render |
| `plc-cloud-sim` | `https://tia.hubwiz.com/sim/mcp` | the LAD/SCL program and the test inputs |
| `tialink-tia-portal` | `http://127.0.0.1:8080/mcp` (your machine) | nothing leaves the machine: the gateway drives TIA Portal over Openness locally and its licence works offline |

Requests to the cloud endpoints carry your key in an `Authorization: Bearer` header. Project files, tag tables and block sources stay on your machine unless one of the cloud skills above is used on them.

Privacy / 隐私：<https://github.com/tia-forge/claude-plugin-tiaforge/blob/main/PRIVACY.md>

## Licence

Skills, commands and this README: CC-BY-4.0. The TiaLink gateway and the four cloud MCP services are commercial products of 汇智网 (hubwiz.com) and are not covered by that licence. TIA Portal, SIMATIC, S7 and PLCSIM are trademarks of Siemens AG; this plugin is an independent product and is not affiliated with or endorsed by Siemens.
