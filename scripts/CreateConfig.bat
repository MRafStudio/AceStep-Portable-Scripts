REM scripts\CreateConfig.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

pushd %~dp0..

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"

REM ============================================================================
REM   Получаем значения из аргументов (или дефолты)
REM ============================================================================
set "LANGUAGE=%~1"
set "CURRENT_MODEL=%~2"
set "LM_MODEL=%~3"
set "AUTO_OPEN_BROWSER=%~4"
set "LAUNCH_METHOD=%~5"
set "CUDA_VERSION=%~6"

::echo %LANGUAGE%
::echo %CURRENT_MODEL%
::echo %LM_MODEL%
::echo %AUTO_OPEN_BROWSER%
::echo %LAUNCH_METHOD%
::echo %CUDA_VERSION%
::pause

if "%LANGUAGE%"=="" set "LANGUAGE=ru"
if "%CURRENT_MODEL%"=="" set "CURRENT_MODEL=turbo"
if "%LM_MODEL%"=="" set "LM_MODEL=acestep-5Hz-lm-1.7B"
if "%AUTO_OPEN_BROWSER%"=="" set "AUTO_OPEN_BROWSER=1"
if "%LAUNCH_METHOD%"=="" set "LAUNCH_METHOD=gradio"
if "%CUDA_VERSION%"=="" set "CUDA_VERSION=12.8"

REM ============================================================================
REM   Валидация
REM ============================================================================
if /I "%CURRENT_MODEL%"=="base" set "CURRENT_MODEL=turbo"
set "VALID_MODEL=0"
if /I "%CURRENT_MODEL%"=="sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="turbo" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-turbo" set "VALID_MODEL=1"
if "!VALID_MODEL!"=="0" set "CURRENT_MODEL=turbo"

REM ============================================================================
REM   Пересоздаём Config.ini с правильным порядком
REM ============================================================================
(
    echo ; ============================================================
    echo ;   AceStep-1.5 Portable — Конфигурация
    echo ; ============================================================
    echo.
    echo ; --- Язык интерфейса ---
    echo ; Доступные: en, zh, ja, he, pt, ru
    echo LANGUAGE=%LANGUAGE%
    echo.
    echo ; --- Модель DiT ---
    echo ; Доступные: turbo, sft, xl-base, xl-sft, xl-turbo
    echo ; Примечание: base устарел, используйте turbo или sft
    echo CURRENT_MODEL=%CURRENT_MODEL%
    echo.
    echo ; --- LM модель ---
    echo ; Доступные: acestep-5Hz-lm-0.6B, acestep-5Hz-lm-1.7B, acestep-5Hz-lm-4B
    echo ; 0.6B = быстро, мало VRAM ^| 1.7B = баланс ^| 4B = макс качество
    echo LM_MODEL=%LM_MODEL%
    echo.
    echo ; --- Запуск ---
    echo AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER%
    echo LAUNCH_METHOD=%LAUNCH_METHOD%
    echo.
    echo ; --- CUDA ---
    echo ; Для RTX 5090 ^(Blackwell^) — CUDA 12.8
    echo CUDA_VERSION=%CUDA_VERSION%
) > "%CONFIG_FILE%"

popd
exit /b 0