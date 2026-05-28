#!/bin/bash
# 营养标签工具 — 服务器启动脚本
# 支持局域网 + 公网访问（ngrok）

PORT=${1:-8080}
MODE=${2:-local}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "════════════════════════════════════"
echo "  营养标签工具 — GB 28050-2025"
echo "════════════════════════════════════"
echo ""

# 获取本机局域网 IP
get_local_ip() {
    if [[ "$(uname)" == "Darwin" ]]; then
        IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
    else
        IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    echo "$IP"
}

IP=$(get_local_ip)

echo "  本机访问：  http://localhost:$PORT"
[ -n "$IP" ] && echo "  局域网：    http://$IP:$PORT"

# 启动 HTTP 服务器
cd "$SCRIPT_DIR"
python3 -m http.server "$PORT" &
SERVER_PID=$!

# ngrok 公网隧道
if [ "$MODE" == "public" ]; then
    if command -v ngrok &> /dev/null; then
        echo ""
        echo "  ══════════════════════════════════"
        echo "  正在启动公网隧道（ngrok）..."
        ngrok http "$PORT" --log=stdout 2>/dev/null &
        NGROK_PID=$!
        sleep 3
        # 获取公网 URL
        PUBLIC_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['tunnels'][0]['public_url'])" 2>/dev/null)
        if [ -n "$PUBLIC_URL" ]; then
            echo "  ══════════════════════════════════"
            echo "  公网访问：  $PUBLIC_URL"
            echo "  ══════════════════════════════════"
            echo "  任何联网设备均可通过此地址访问"
            echo "  （URL 每次启动会变化）"
        else
            echo "  ngrok 启动中，请查看 http://127.0.0.1:4040"
        fi
    else
        echo ""
        echo "  ngrok 未安装，无法使用公网模式。"
        echo "  安装方法：brew install ngrok"
        echo "  然后运行：bash server.sh 8080 public"
        kill $SERVER_PID 2>/dev/null
        exit 1
    fi
fi

echo ""
echo "  按 Ctrl+C 停止所有服务"
echo "════════════════════════════════════"
echo ""

# 等待并清理
trap "kill $SERVER_PID 2>/dev/null; kill $NGROK_PID 2>/dev/null; echo '已停止'; exit 0" INT TERM
wait
