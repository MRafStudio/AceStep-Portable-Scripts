REM scripts\InstallOrUpdate-Dependencies.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title AceStep-1.5 — Установка зависимостей
pushd %~dp0..

REM ============================================================================
REM   Получение ESC через PowerShell
REM ============================================================================
for /f %%a in ('powershell -NoProfile -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "REPO_DIR=%ROOT_DIR%\repo"
set "PYTHON_DIR=%ROOT_DIR%\python-3.12.10"
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"

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

cls
echo.
echo  %ESC%[1;36m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;36m║%ESC%[0m               %ESC%[1;37mAceStep-1.5%ESC%[0m  —  %ESC%[1;33mУстановка PyTorch + зависимостей%ESC%[0m               %ESC%[1;36m║%ESC%[0m
echo  %ESC%[1;36m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.

REM ============================================================================
REM   Проверка Python
REM ============================================================================
if not exist "%PYTHON_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Python не найден! Установите Python сначала.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

REM ============================================================================
REM   Проверка репозитория
REM ============================================================================
if not exist "%REPO_DIR%\requirements.txt" (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не найден! Клонируйте репозиторий сначала.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

REM ============================================================================
REM   Автоопределение GPU
REM ============================================================================
echo   %ESC%[1;33m→ Определение видеокарты...%ESC%[0m

set "GPU_TYPE=UNKNOWN"
set "GPU_NAME=Не определена"

REM NVIDIA через nvidia-smi -L
nvidia-smi -L >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('nvidia-smi -L 2^>nul') do (
        set "RAW=%%a"
        set "RAW=!RAW:GPU 0: =!"
        for /f "delims=(" %%b in ("!RAW!") do set "GPU_NAME=%%b"
        set "GPU_NAME=!GPU_NAME:~0,-1!"
        set "GPU_TYPE=NVIDIA"
        echo   %ESC%[1;32m  +   NVIDIA: !GPU_NAME!%ESC%[0m
        goto gpu_detected
    )
)

REM AMD через PowerShell
for /f "tokens=*" %%a in ('powershell -Command "(Get-CimInstance Win32_VideoController).Name" 2^>nul') do (
    echo %%a | findstr /I "AMD" >nul 2>nul
    if !errorlevel! equ 0 (
        set "GPU_NAME=%%a"
        set "GPU_TYPE=AMD"
        goto gpu_detected
    )
)
if "!GPU_TYPE!"=="AMD" (
    echo   %ESC%[1;32m  +   AMD: !GPU_NAME!%ESC%[0m
    goto gpu_detected
)

echo   %ESC%[1;31m  -   Видеокарта не определена!%ESC%[0m
echo   %ESC%[1;31m[ОШИБКА] Требуется NVIDIA или AMD GPU.%ESC%[0m
if "%AUTOCLOSE%"=="1" (
    call "%~dp0SmartPause.bat" 5
) else (
    pause
)
popd
exit /b 1

:gpu_detected
echo.
REM ============================================================================
REM   Разветвление по GPU
REM ============================================================================
if "!GPU_TYPE!"=="NVIDIA" (
    call "%SCRIPTS_DIR%\InstallOrUpdate-Deps-NVIDIA.bat" %AUTOCLOSE%
) else if "!GPU_TYPE!"=="AMD" (
    call "%SCRIPTS_DIR%\InstallOrUpdate-Deps-AMD.bat" %AUTOCLOSE%
)

:exit
popd
exit /b 0