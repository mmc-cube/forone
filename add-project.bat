@echo off
chcp 65001 >nul

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: add-project.bat "C:\path\to\project"
    echo.
    echo Example: add-project.bat "D:\my-app"
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0add-project.ps1" "%~1"
pause
