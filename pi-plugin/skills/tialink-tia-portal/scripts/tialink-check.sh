#!/usr/bin/env sh
# tialink-check.sh — 只读冒烟：确认「网关可达 + 令牌可用 + 工具列表非空」
#
# 用法：
#   sh tialink-check.sh http://192.168.1.78:8080/mcp <令牌>
# 或：
#   TIALINK_URL=... TIALINK_TOKEN=... sh tialink-check.sh
#
# 只发两个只读 JSON-RPC 请求（initialize / tools/list），不写工程、不改配置、不装东西。

set -u

URL="${1:-${TIALINK_URL:-http://127.0.0.1:8080/mcp}}"
TOKEN="${2:-${TIALINK_TOKEN:-}}"

case "$URL" in
  */mcp) ;;
  *) echo "[!] 地址似乎不是 /mcp 结尾：$URL  （正确形如 http://host:8080/mcp）" >&2 ;;
esac

ACCEPT='Accept: application/json, text/event-stream'

if [ -n "$TOKEN" ]; then
  AUTH="Authorization: Bearer $TOKEN"
else
  AUTH="X-No-Token: 1"
  echo "[i] 没给令牌（网关可能没配 token）"
fi

echo "== 1/2 initialize =="
code=$(curl -sS -o /tmp/tialink-init.out -w '%{http_code}' -m 30 \
  -X POST "$URL" -H "$AUTH" -H "$ACCEPT" -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"tialink-check","version":"1.0"}}}' 2>/dev/null) || code=000

echo "HTTP $code"
case "$code" in
  200) echo "    OK：网关在线，令牌被接受" ;;
  401|403) echo "    ✗ 令牌缺失或错误（注意尾部换行/空格），header 必须是 Authorization: Bearer <token>" ;;
  404) echo "    ✗ 路径不对：必须 /mcp" ;;
  406) echo "    ✗ 缺 Accept: text/event-stream" ;;
  000) echo "    ✗ 连不上：网关没起 / 只绑 localhost / 防火墙" ;;
  *) echo "    ? 未预期状态，原始响应前 300 字节：" && head -c 300 /tmp/tialink-init.out ;;
esac

[ "$code" = "200" ] || exit 1

echo "== 2/2 tools/list =="
code2=$(curl -sS -o /tmp/tialink-tools.out -w '%{http_code}' -m 60 \
  -X POST "$URL" -H "$AUTH" -H "$ACCEPT" -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' 2>/dev/null) || code2=000

echo "HTTP $code2"
if [ "$code2" = "200" ]; then
  n=$(grep -o '"name"' /tmp/tialink-tools.out | wc -l | tr -d ' ')
  echo "    工具条目数（粗略计数）：$n"
  [ "$n" = "0" ] && echo "    ✗ 工具为空：客户端/服务端版本不匹配，或网关未连上博途"
  [ "$n" != "0" ] && echo "    OK：能看到工具，可以进入只读热身（读设备清单、读块清单）"
else
  echo "    ✗ 原始响应前 300 字节：" && head -c 300 /tmp/tialink-tools.out
fi

echo
echo "下一步：只读热身 —— 打开目标工程，先报设备清单 + 块清单 + TIA 版本 + PLCSIM 在线状态，不要先写。"
