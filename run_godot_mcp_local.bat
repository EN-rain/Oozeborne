@echo off
setlocal

set "ROOT=%~dp0"
set "SERVER_DIR=%ROOT%game\addons\godot_mcp_server"
set "ENTRY=%SERVER_DIR%\build\index.js"
set "GODOT_PATH=C:\Users\LENOVO\Desktop\godot\Godot_v4.6.1-stable_win64_console.exe"

if not exist "%ENTRY%" (
  echo Tugcan Godot MCP is not built. Run npm ci and npm run build in "%SERVER_DIR%".
  exit /b 1
)

if not exist "%GODOT_PATH%" (
  echo Configured GODOT_PATH not found: %GODOT_PATH%
  exit /b 1
)

set "DEBUG=true"
node "%ENTRY%" %*
