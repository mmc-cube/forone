@echo off
chcp 65001 >nul
echo ===== 一键更新并推送 =====
echo.

:: 用 Git Bash 执行 update.sh
"%ProgramFiles%\Git\bin\bash.exe" "%~dp0update.sh"

pause
