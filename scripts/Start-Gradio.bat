REM scripts\Start-Gradio.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 — Запуск Gradio
pushd %~dp0..

REM ============================================================================
REM   Получение ESC
REM ============================================================================
for /f %%a in ('powershell -NoProfile -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Пути
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "REPO_DIR=%ROOT_DIR%\repo"
set "VENV_PYTHON=%REPO_DIR%\.venv\Scripts\python.exe"
set "PIPELINE_PY=%REPO_DIR%\acestep\acestep_v15_pipeline.py"

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
REM   Чтение Config.ini
REM ============================================================================
set "CURRENT_MODEL=turbo"
set "AUTO_OPEN_BROWSER=1"
set "LAUNCH_METHOD=gradio"

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CURRENT_MODEL=" "%CONFIG_FILE%"') do set "CURRENT_MODEL=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LAUNCH_METHOD=" "%CONFIG_FILE%"') do set "LAUNCH_METHOD=%%b"
)

set "CURRENT_MODEL=%CURRENT_MODEL: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"
set "LAUNCH_METHOD=%LAUNCH_METHOD: =%"

REM ============================================================================
REM   Валидация модели
REM ============================================================================
set "VALID_MODEL=0"
if /I "%CURRENT_MODEL%"=="base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="turbo" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-turbo" set "VALID_MODEL=1"

if "!VALID_MODEL!"=="0" set "CURRENT_MODEL=turbo"
if /I "%CURRENT_MODEL%"=="base" set "CURRENT_MODEL=turbo"

REM ============================================================================
REM   Маппинг: короткое имя → реальное имя папки
REM ============================================================================
if "%CURRENT_MODEL%"=="base"     set "REAL_MODEL=acestep-v15-base"
if "%CURRENT_MODEL%"=="sft"      set "REAL_MODEL=acestep-v15-sft"
if "%CURRENT_MODEL%"=="turbo"    set "REAL_MODEL=acestep-v15-turbo"
if "%CURRENT_MODEL%"=="xl-base"  set "REAL_MODEL=acestep-v15-xl-base"
if "%CURRENT_MODEL%"=="xl-sft"   set "REAL_MODEL=acestep-v15-xl-sft"
if "%CURRENT_MODEL%"=="xl-turbo" set "REAL_MODEL=acestep-v15-xl-turbo"

REM ============================================================================
REM   Проверки
REM ============================================================================
if not exist "%VENV_PYTHON%" (
    echo   %ESC%[1;31m[ОШИБКА] Виртуальное окружение не найдено!%ESC%[0m
    echo   %ESC%[33m       Запустите установку зависимостей ^(меню [1] -^> [3]^).%ESC%[0m
    pause
    popd
    exit /b 1
)

if not exist "%PIPELINE_PY%" (
    echo   %ESC%[1;31m[ОШИБКА] Не найден скрипт запуска:%ESC%[0m
    echo   %ESC%[33m       %PIPELINE_PY%%ESC%[0m
    echo   %ESC%[33m       Проверьте структуру репозитория.%ESC%[0m
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   Создание .env в repo\
REM ============================================================================
set "ENV_FILE=%REPO_DIR%\.env"

(
    echo # AceStep-1.5 Portable — Auto-generated .env
    echo # Редактируйте через Settings.bat или вручную
    echo.
    echo # --- Модели ---
    echo ACESTEP_CONFIG_PATH=%REAL_MODEL%
    echo ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-1.7B
    echo.
    echo # --- Устройство ---
    echo ACESTEP_DEVICE=auto
    echo ACESTEP_LM_BACKEND=vllm
    echo.
    echo # --- LLM ---
    echo ACESTEP_INIT_LLM=auto
    echo.
    echo # --- Скачивание ---
    echo ACESTEP_DOWNLOAD_SOURCE=auto
    echo.
    echo # --- Gradio UI ---
    echo PORT=7860
    echo SERVER_NAME=127.0.0.1
    echo LANGUAGE=en
    echo.
    echo # --- Стартовые настройки ---
    echo ACESTEP_NO_INIT=false
) > "%ENV_FILE%"

REM ============================================================================
REM   Запуск
REM ============================================================================
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mЗапуск Gradio%ESC%[0m                          %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.
echo   %ESC%[1;33mМодель:%ESC%[0m %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m %ESC%[2m^(%REAL_MODEL%^)%ESC%[0m
echo   %ESC%[1;33mURL:%ESC%[0m %ESC%[1;37mhttp://127.0.0.1:7860%ESC%[0m
echo   %ESC%[1;33mМодели:%ESC%[0m %ESC%[2mавто-загрузка в repo\checkpoints\%ESC%[0m
echo.

if "%AUTO_OPEN_BROWSER%"=="1" (
    echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mОткрытие браузера...%ESC%[0m
    start "" "http://127.0.0.1:7860"
)

echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск сервера...%ESC%[0m
echo   %ESC%[2m       Нажмите Ctrl+C для остановки%ESC%[0m
echo   %ESC%[2m       При первом запуске модели скачаются автоматически.%ESC%[0m
echo.

cd /d "%REPO_DIR%"

"%VENV_PYTHON%" "%PIPELINE_PY%" ^
    --port 7860 ^
    --server-name 127.0.0.1 ^
    --language en ^
    --config_path %REAL_MODEL% ^
    --lm_model_path acestep-5Hz-lm-1.7B ^
    --init_service true

echo.
echo   %ESC%[1;33mСервер остановлен.%ESC%[0m
pause
popd
exit /b 0