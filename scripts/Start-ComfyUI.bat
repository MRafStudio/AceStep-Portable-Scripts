@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 — Запуск ComfyUI
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение ROOT_DIR (корень проекта = уровень выше scripts\)
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "REPO_DIR=%ROOT_DIR%\repo"
set "MODELS_DIR=%ROOT_DIR%\models"

REM ============================================================================
REM   Изоляция данных
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul

REM ============================================================================
REM   Чтение настроек
REM ============================================================================
set "CURRENT_MODEL=xl-base"
set "AUTO_OPEN_BROWSER=1"

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CURRENT_MODEL=" "%CONFIG_FILE%"') do set "CURRENT_MODEL=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
)

set "CURRENT_MODEL=%CURRENT_MODEL: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mЗапуск ComfyUI%ESC%[0m                         %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.
echo   %ESC%[1;33mМодель:%ESC%[0m %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m
echo   %ESC%[1;33mURL:%ESC%[0m %ESC%[1;37mhttp://127.0.0.1:8188%ESC%[0m
echo.
echo   %ESC%[1;33m⚠   ComfyUI требует отдельной установки нод ACE-Step!%ESC%[0m
echo   %ESC%[33m       Убедитесь, что ноды установлены в ComfyUI.%ESC%[0m
echo.

if "%AUTO_OPEN_BROWSER%"=="1" (
    echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mОткрытие браузера...%ESC%[0m
    start "" "http://127.0.0.1:8188"
)

echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск ComfyUI...%ESC%[0m
echo   %ESC%[2m       Нажмите Ctrl+C для остановки%ESC%[0m
echo.

REM ============================================================================
REM   Проверка ComfyUI
REM ============================================================================
if not exist "%REPO_DIR%\comfyui" (
    echo   %ESC%[1;31m[ОШИБКА] ComfyUI не найден в репозитории.%ESC%[0m
    echo   %ESC%[33m       Установите ComfyUI отдельно или используйте Gradio.%ESC%[0m
    pause
    popd
    exit /b 1
)

cd /d "%REPO_DIR%\comfyui"

REM Запуск ComfyUI (путь может отличаться)
if exist "main.py" (
    "%REPO_DIR%\.venv\Scripts\python.exe" main.py --listen 127.0.0.1 --port 8188
) else (
    echo   %ESC%[1;31m[ОШИБКА] Не найден скрипт запуска ComfyUI.%ESC%[0m
    pause
    popd
    exit /b 1
)

echo.
echo   %ESC%[1;33mСервер остановлен.%ESC%[0m
pause
popd
exit /b 0