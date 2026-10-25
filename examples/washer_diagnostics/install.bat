@echo off
setlocal
cd /d "%~dp0"

py -3.12 --version >nul 2>nul
if errorlevel 1 (
  echo Python 3.12 was not found. Install Python 3.12 with the Windows py launcher, then run this file again.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" py -3.12 -m venv .venv
if errorlevel 1 (
  echo Could not create the isolated virtual environment.
  pause
  exit /b 1
)

".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 goto :failed
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 goto :failed
echo Setup complete. Double-click start_live_monitor.bat to open the dashboard.
pause
exit /b 0

:failed
echo Setup failed. Check the network/package source and read the error above.
pause
exit /b 1
