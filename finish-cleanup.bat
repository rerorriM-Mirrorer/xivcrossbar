@echo off
echo Unload XIVCrossbar in ALL clients before continuing.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Finish-Cleanup.ps1"
if errorlevel 1 echo Cleanup stopped. Existing files remain available for review.
pause
