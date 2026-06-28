REM scripts\InstallOrUpdate-Models.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 — Установка / Обновление моделей

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
set "CHECKPOINTS_DIR=%REPO_DIR%\checkpoints"

REM ============================================================================
REM   Изоляция
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul

REM ============================================================================
REM   Чтение текущей модели из Config.ini
REM ============================================================================
set "CURRENT_MODEL=turbo"
if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CURRENT_MODEL=" "%CONFIG_FILE%"') do set "CURRENT_MODEL=%%b"
)
set "CURRENT_MODEL=%CURRENT_MODEL: =%"

:menu
cls
echo.
echo  %ESC%[1;36m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;36m║%ESC%[0m               %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mУправление моделями%ESC%[0m                      %ESC%[1;36m║%ESC%[0m
echo  %ESC%[1;36m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.
echo   %ESC%[1;33mТекущая модель в Config.ini:%ESC%[0m %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m
echo.
echo   %ESC%[1;33mСтатус checkpoints\:%ESC%[0m

if exist "%CHECKPOINTS_DIR%" (
    dir /b /ad "%CHECKPOINTS_DIR%" 2>nul | findstr /I "acestep" >nul
    if !errorlevel! equ 0 (
        echo     %ESC%[1;32m+  %ESC%[0m Модели уже загружены
        for /f %%a in ('dir /b /ad "%CHECKPOINTS_DIR%\acestep*" 2^>nul') do (
            echo     %ESC%[2m   - %%a%ESC%[0m
        )
    ) else (
        echo     %ESC%[1;33m.  %ESC%[0m Модели будут загружены автоматически при первом запуске
    )
) else (
    echo     %ESC%[1;33m.  %ESC%[0m Каталог checkpoints\ ещё не создан
    echo     %ESC%[2m       Модели загрузятся при первом запуске Ace-Step%ESC%[0m
)

echo.
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mСменить модель в Config.ini%ESC%[0m %ESC%[2m(без скачивания)%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mОткрыть папку checkpoints\%ESC%[0m
echo.
echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mНазад%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mДействие (0-2): %ESC%[0m"

set "choice=%choice: =%"
if "%choice%"=="" goto menu
if "%choice%"=="0" goto exit
if "%choice%"=="1" goto change_model
if "%choice%"=="2" goto open_folder
goto menu

:change_model
cls
echo.
echo   %ESC%[1;33mВыбор модели DiT:%ESC%[0m
echo.
echo   %ESC%[1;34m── Стандарт (2B, ~5GB) ─────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mbase%ESC%[0m   %ESC%[2mVRAM: 6GB+  Шаги: 50  Все задачи%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1msft%ESC%[0m    %ESC%[2mVRAM: 6GB+  Шаги: 50  Стандарт%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mturbo%ESC%[0m  %ESC%[2mVRAM: 6GB+  Шаги: 8   Быстрая%ESC%[0m
echo.
echo   %ESC%[1;34m── XL (4B, ~19GB) ───────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[4]%ESC%[0m %ESC%[1mxl-base%ESC%[0m   %ESC%[2mVRAM: 12GB+  Шаги: 50  Все задачи%ESC%[0m
echo   %ESC%[1;37m[5]%ESC%[0m %ESC%[1mxl-sft%ESC%[0m    %ESC%[2mVRAM: 12GB+  Шаги: 50  Стандарт%ESC%[0m
echo   %ESC%[1;37m[6]%ESC%[0m %ESC%[1mxl-turbo%ESC%[0m  %ESC%[2mVRAM: 12GB+  Шаги: 8   Быстрая%ESC%[0m
echo.
set "mchoice="
set /p "mchoice=%ESC%[33mВыберите модель (1-6): %ESC%[0m"

set "mchoice=%mchoice: =%"
if "%mchoice%"=="1" set "NEW_MODEL=base"
if "%mchoice%"=="2" set "NEW_MODEL=sft"
if "%mchoice%"=="3" set "NEW_MODEL=turbo"
if "%mchoice%"=="4" set "NEW_MODEL=xl-base"
if "%mchoice%"=="5" set "NEW_MODEL=xl-sft"
if "%mchoice%"=="6" set "NEW_MODEL=xl-turbo"

if defined NEW_MODEL (
    if exist "%CONFIG_FILE%" (
        powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'CURRENT_MODEL=.*', 'CURRENT_MODEL=%NEW_MODEL%' | Set-Content '%CONFIG_FILE%'"
        set "CURRENT_MODEL=%NEW_MODEL%"
        echo.
        echo   %ESC%[1;32m  +   Модель изменена на %NEW_MODEL%%ESC%[0m
        echo   %ESC%[2m       При следующем запуске Ace-Step загрузит нужную модель.%ESC%[0m
    ) else (
        echo   %ESC%[1;31m[ОШИБКА] Config.ini не найден.%ESC%[0m
    )
    timeout /t 2 /nobreak >nul
)
goto menu

:open_folder
if not exist "%CHECKPOINTS_DIR%" mkdir "%CHECKPOINTS_DIR%" 2>nul
start "" "%CHECKPOINTS_DIR%"
goto menu

:exit
popd
exit /b 0