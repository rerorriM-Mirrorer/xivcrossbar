@echo off
setlocal
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0WindowerPatch.ps1" -WindowerRoot "%~dp0." %*
if errorlevel 1 echo Installation did not complete. See the report above.
pause
