@echo off
setlocal
rem Explicit PowerShell bootstrap selects and validates a v2 executable.
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0launch-controller.ps1" %*
exit /b %errorlevel%
