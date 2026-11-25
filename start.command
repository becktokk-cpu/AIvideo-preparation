#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=========================================="
echo "  分鏡指令選擇器｜本機伺服器啟動工具"
echo "=========================================="
echo ""

open_browser() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
  fi
}

PYCMD=""
if command -v python3 >/dev/null 2>&1; then
  PYCMD="python3"
elif command -v python >/dev/null 2>&1; then
  if python -c "import sys; raise SystemExit(0 if sys.version_info[0]>=3 else 1)" >/dev/null 2>&1; then
    PYCMD="python"
  fi
fi

if [ -n "$PYCMD" ]; then
  PORT="$($PYCMD -c "import socket
p=0
for port in range(8765,8800):
    s=socket.socket()
    try:
        s.bind(('127.0.0.1',port)); p=port; s.close(); break
    except OSError:
        s.close()
if not p:
    s=socket.socket(); s.bind(('127.0.0.1',0)); p=s.getsockname()[1]; s.close()
print(p)")"
  URL="http://127.0.0.1:${PORT}/index.html"
  echo "[OK] 使用 ${PYCMD} 啟動本機伺服器：${URL}"
  echo "     按 Ctrl+C 或關閉此視窗即可停止伺服器。"
  echo ""
  (sleep 1 && open_browser "$URL") &
  exec "$PYCMD" -m http.server "$PORT" --bind 127.0.0.1
fi

if command -v node >/dev/null 2>&1; then
  echo "[OK] 使用 Node.js 啟動本機伺服器..."
  echo "     按 Ctrl+C 或關閉此視窗即可停止伺服器。"
  echo ""
  exec node -e "
    const http = require('http'), fs = require('fs'), path = require('path'), { exec } = require('child_process');
    const root = process.cwd();
    const MIME = {
      '.html': 'text/html; charset=utf-8', '.js': 'application/javascript; charset=utf-8',
      '.css': 'text/css; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png',
      '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp',
      '.json': 'application/json; charset=utf-8', '.webm': 'video/webm', '.mp4': 'video/mp4'
    };
    const srv = http.createServer((req, res) => {
      const u = decodeURIComponent((req.url || '/').split('?')[0]);
      const rel = u === '/' ? 'index.html' : u.replace(/^\/+/, '');
      const f = path.resolve(root, rel);
      if (!f.startsWith(root) || !fs.existsSync(f) || !fs.statSync(f).isFile()) {
        res.writeHead(404); return res.end('Not Found');
      }
      res.writeHead(200, { 'Content-Type': MIME[path.extname(f).toLowerCase()] || 'application/octet-stream' });
      fs.createReadStream(f).pipe(res);
    });
    function tryListen(p) {
      srv.once('error', e => {
        if (e.code === 'EADDRINUSE' && p < 8800) tryListen(p + 1);
        else srv.listen(0, '127.0.0.1');
      });
      srv.listen(p, '127.0.0.1', () => {
        const port = srv.address().port;
        const url = 'http://127.0.0.1:' + port + '/index.html';
        console.log('Serving at ' + url);
        const cmd = process.platform === 'darwin' ? 'open' : 'xdg-open';
        exec(cmd + ' \"' + url + '\"');
      });
    }
    tryListen(8765);
  "
fi

if command -v npx >/dev/null 2>&1; then
  echo "[OK] 使用 npx serve 啟動本機伺服器..."
  (sleep 1 && open_browser "http://127.0.0.1:8765/index.html") &
  exec npx --yes serve -l tcp://127.0.0.1:8765 .
fi

echo "[錯誤] 本機未偵測到 Python 3 或 Node.js，無法啟動本機伺服器。"
echo ""
echo "請任選一種方式安裝："
echo "  1. macOS 可執行: brew install python3  或前往 https://www.python.org/downloads/"
echo "  2. 或安裝 Node.js: https://nodejs.org/"
echo ""
read -r -p "按 Enter 鍵關閉..." _
exit 1
