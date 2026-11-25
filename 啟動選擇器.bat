@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ==========================================
echo   分鏡指令選擇器｜本機伺服器啟動工具
echo ==========================================
echo.

if defined PREFER_NODE goto :try_node

set "PYCMD="
python --version >nul 2>&1
if %ERRORLEVEL%==0 set "PYCMD=python"
if defined PYCMD goto :run_py

py --version >nul 2>&1
if %ERRORLEVEL%==0 set "PYCMD=py"
if defined PYCMD goto :run_py
goto :try_node

:run_py
set "PORT=8765"
for /f "usebackq delims=" %%p in (`%PYCMD% -c "import socket; chk=lambda p: (lambda s: (s.settimeout(0.05), s.connect_ex(('127.0.0.1', p)) != 0, s.close())[1])(socket.socket()); free=[p for p in range(8765, 8800) if chk(p)]; print(free[0] if free else 0)"`) do set "PORT=%%p"
if "%PORT%"=="0" for /f "usebackq delims=" %%p in (`%PYCMD% -c "import socket; s=socket.socket(); s.bind(('127.0.0.1', 0)); print(s.getsockname()[1]); s.close()"`) do set "PORT=%%p"
echo [OK] 使用 %PYCMD% 啟動本機伺服器：http://127.0.0.1:%PORT%/index.html
echo      關閉此視窗即可停止伺服器。
echo.
if not defined SKIP_BROWSER start "" "http://127.0.0.1:%PORT%/index.html"
%PYCMD% -m http.server %PORT% --bind 127.0.0.1
goto :eof

:try_node
node --version >nul 2>&1
if not %ERRORLEVEL%==0 goto :try_npx
echo [OK] 使用 Node.js 啟動本機伺服器...
echo      關閉此視窗即可停止伺服器。
echo.
node -e "const http=require('http'),fs=require('fs'),path=require('path'),cp=require('child_process');const root=process.cwd();const MIME={'.html':'text/html; charset=utf-8','.js':'application/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg','.webp':'image/webp','.json':'application/json; charset=utf-8','.webm':'video/webm','.mp4':'video/mp4'};const srv=http.createServer((req,res)=>{const u=decodeURIComponent((req.url||'/').split('?')[0]);const rel=u==='/'?'index.html':u.replace(/^\/+/,'');const f=path.resolve(root,rel);if(!f.startsWith(root)||!fs.existsSync(f)||!fs.statSync(f).isFile()){res.writeHead(404);return res.end('Not Found');}res.writeHead(200,{'Content-Type':MIME[path.extname(f).toLowerCase()]||'application/octet-stream'});fs.createReadStream(f).pipe(res);});function tryListen(p){srv.once('error',e=>{if(e.code==='EADDRINUSE'&&p<8800)tryListen(p+1);else srv.listen(0,'127.0.0.1');});srv.listen(p,'127.0.0.1',()=>{const port=srv.address().port;const url='http://127.0.0.1:'+port+'/index.html';console.log('[OK] Serving at '+url);if(!process.env.SKIP_BROWSER)cp.exec('start \x22\x22 \x22'+url+'\x22');});}tryListen(8765);"
goto :eof

:try_npx
where npx >nul 2>&1
if not %ERRORLEVEL%==0 goto :no_runtime
echo [OK] 使用 npx serve 啟動本機伺服器...
if not defined SKIP_BROWSER start "" "http://127.0.0.1:8765/index.html"
npx --yes serve -l tcp://127.0.0.1:8765 .
goto :eof

:no_runtime
echo [錯誤] 本機未偵測到 Python 或 Node.js，無法啟動本機伺服器。
echo.
echo 請任選一種方式安裝（免費且僅需 1 分鐘）：
echo   1. 安裝 Python 3：https://www.python.org/downloads/
echo      （Windows 安裝時請勾選 "Add python.exe to PATH"）
echo   2. 或安裝 Node.js：https://nodejs.org/
echo.
echo 若不想安裝任何程式，也可以直接將本專案推上 GitHub 並開啟 GitHub Pages 線上使用！
echo.
pause
