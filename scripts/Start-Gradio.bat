@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 — Запуск Gradio
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

set "ROOT_DIR=%~dp0.."
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "REPO_DIR=%ROOT_DIR%\repo"
set "MODELS_DIR=%ROOT_DIR%\models"
set "PYTHON_DIR=%ROOT_DIR%\python-3.11.9"

REM ============================================================================
REM   Изоляция данных
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "TMP=%DATA_DIR%\temp"
set "APPDATA=%DATA_DIR%\appdata"
set "LOCALAPPDATA=%DATA_DIR%\localappdata"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%APPDATA%" mkdir "%APPDATA%" 2>nul
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

REM ============================================================================
REM   Проверки
REM ============================================================================
if not exist "%REPO_DIR%\.venv\Scripts\python.exe" (
    echo   %ESC%[1;31m[ОШИБКА] Виртуальное окружение не найдено!%ESC%[0m
    echo   %ESC%[33m       Запустите установку зависимостей.%ESC%[0m
    pause
    popd
    exit /b 1
)

set "VENV_PYTHON=%REPO_DIR%\.venv\Scripts\python.exe"

if not exist "%MODELS_DIR%\%CURRENT_MODEL%" (
    echo   %ESC%[1;31m[ОШИБКА] Модель %CURRENT_MODEL% не найдена!%ESC%[0m
    echo   %ESC%[33m       Скачайте модель через меню установки.%ESC%[0m
    pause
    popd
    exit /b 1
)

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mЗапуск Gradio%ESC%[0m                          %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.
echo   %ESC%[1;33mМодель:%ESC%[0m %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m
echo   %ESC%[1;33mURL:%ESC%[0m %ESC%[1;37mhttp://127.0.0.1:7860%ESC%[0m
echo.

if "%AUTO_OPEN_BROWSER%"=="1" (
    echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mОткрытие браузера...%ESC%[0m
    start "" "http://127.0.0.1:7860"
)

echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск сервера...%ESC%[0m
echo   %ESC%[2m       Нажмите Ctrl+C для остановки%ESC%[0m
echo.

cd /d "%REPO_DIR%"

REM ============================================================================
REM   Запуск Gradio
REM ============================================================================
REM Путь к скрипту запуска может отличаться, проверим стандартные варианты
if exist "%REPO_DIR%\app.py" (
    "%VENV_PYTHON%" app.py --model-dir "%MODELS_DIR%\%CURRENT_MODEL%"
) else if exist "%REPO_DIR%\gradio_app.py" (
    "%VENV_PYTHON%" gradio_app.py --model-dir "%MODELS_DIR%\%CURRENT_MODEL%"
) else if exist "%REPO_DIR%\run.py" (
    "%VENV_PYTHON%" run.py --model-dir "%MODELS_DIR%\%CURRENT_MODEL%"
) else (
    echo   %ESC%[1;31m[ОШИБКА] Не найден скрипт запуска Gradio.%ESC%[0m
    echo   %ESC%[33m       Проверьте структуру репозитория.%ESC%[0m
    pause
    popd
    exit /b 1
)

echo.
echo   %ESC%[1;33mСервер остановлен.%ESC%[0m
pause
popd
exit /b 0