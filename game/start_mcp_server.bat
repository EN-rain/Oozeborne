@echo off
echo ===================================
echo Godot MCP Server Launcher
echo ===================================
echo.
echo This server allows AI assistants to control Godot Engine
echo via the Godot MCP plugin.
echo.
echo Installing dependencies (if needed)...
pip install -q websockets

echo.
echo Starting MCP Server on ws://127.0.0.1:6505...
echo Keep this window open while using Godot.
echo.
cd /d "%~dp0"
python mcp_server.py

echo.
echo Server stopped. Press any key to close...
pause > nul
