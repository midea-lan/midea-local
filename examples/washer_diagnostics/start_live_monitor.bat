@echo off
setlocal
cd /d "%~dp0"
set "PY=%~dp0.venv\Scripts\python.exe"
set "URL=http://127.0.0.1:8765/"

if not exist "%PY%" (
  echo Missing Python environment: %PY%
  echo Run install.bat first.
  pause
  exit /b 1
)

if not exist "%~dp0discovery_round2_targeted.json" (
  echo First run: discovering DA washers on the local LAN...
  "%PY%" "%~dp0initialize_device.py"
  if errorlevel 1 (
    pause
    exit /b 1
  )
)

"%PY%" -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8765/api/status', timeout=2).read()" >nul 2>nul
if not errorlevel 1 (
  start "" "%URL%"
  echo Monitor is already running. Opened the dashboard.
  timeout /t 3 >nul
  exit /b 0
)

echo Rediscovering the selected washer and starting read-only monitor...
"%PY%" "%~dp0live_monitor.py" --refresh-discovery --interval 1 --open-browser
echo.
echo Monitor stopped. Press Ctrl+C to stop safely while it is running.
pause
