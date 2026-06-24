@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================================================
REM   Параметр firststart
REM ============================================================================
set "FIRSTSTART=0"
if "%1"=="1" set "FIRSTSTART=1"

title AceStep-1.5 Portable — Установка / Обновление всех компонентов
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

set "ROOT_DIR=%~dp0.."
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"

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
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul

echo   %ESC%[2m       Изоляция: %DATA_DIR%%ESC%[0m

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m          %ESC%[1;37mAceStep-1.5 Portable%ESC%[0m   —   %ESC%[1;33mУстановка / Обновление всех%ESC%[0m           %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   ШАГ 1: Python
REM ============================================================================
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mУстановка / Обновление Python...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Python.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;31m[ОШИБКА] Python не установился. Остановка.%ESC%[0m
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   ШАГ 2: Git
REM ============================================================================
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mУстановка / Обновление Git...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Git.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;31m[ОШИБКА] Git не установился. Остановка.%ESC%[0m
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   ШАГ 3: Репозиторий
REM ============================================================================
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mКлонирование / Обновление репозитория...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Repo.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не клонировался. Остановка.%ESC%[0m
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   ШАГ 4: Зависимости
REM ============================================================================
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mУстановка PyTorch + зависимостей...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Dependencies.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;31m[ОШИБКА] Зависимости не установились. Остановка.%ESC%[0m
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   ШАГ 5: Модели
REM ============================================================================
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mСкачивание моделей...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Models.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;33m  ⚠   Модели не скачались ^(можно скачать позже^).%ESC%[0m
    echo.
)

cls
echo.
echo  %ESC%[1;32m  ✔   Все компоненты успешно установлены / обновлены!%ESC%[0m
echo.
echo   %ESC%[1;33mУстановленные компоненты:%ESC%[0m
echo     %ESC%[2m- Python 3.11.9 (portable)%ESC%[0m
echo     %ESC%[2m- Git (portable)%ESC%[0m
echo     %ESC%[2m- Репозиторий ACE-Step-1.5 (форк MRafStudio)%ESC%[0m
echo     %ESC%[2m- PyTorch CUDA 12.8 + зависимости%ESC%[0m
echo     %ESC%[2m- Модели (по выбору)%ESC%[0m
echo.

if "%FIRSTSTART%"=="1" (
    echo   %ESC%[1;33mТеперь можно запускать AceStep-1.5 через главное меню.%ESC%[0m
    pause
    popd
    exit /b 0
)

pause
popd
exit /b 0