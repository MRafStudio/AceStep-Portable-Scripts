REM scripts\InstallOrUpdate-All.bat
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

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
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

REM ============================================================================
REM   PowerShell wrapper (изоляция)
REM ============================================================================
set "PS_WRAPPER=%TEMP%\ps_wrapper.bat"
(
    echo @echo off
    echo set "LOCALAPPDATA=%DATA_DIR%\localappdata"
    echo set "APPDATA=%DATA_DIR%\appdata"
    echo set "TEMP=%TEMP%"
    echo set "TMP=%TMP%"
    echo set "HOME=%HOME%"
    echo set "USERPROFILE=%USERPROFILE%"
    echo powershell -NoProfile -NonInteractive %%*
) > "%PS_WRAPPER%"

for /f "usebackq" %%a in (`%PS_WRAPPER% -Command "Write-Host ([char]27) -NoNewline"`) do set "ESC=%%a"

REM ============================================================================
REM   Проверка Git (глобальный, обязательно!)
REM ============================================================================
git --version >nul 2>nul
if !errorlevel! neq 0 (
    cls
    echo.
    echo  %ESC%[1;31m################################################################################%ESC%[0m
    echo  %ESC%[1;31m##                                                                            ##%ESC%[0m
    echo  %ESC%[1;31m##%ESC%[0m              %ESC%[1;37mGit не найден в системе%ESC%[0m                                %ESC%[1;31m##%ESC%[0m
    echo  %ESC%[1;31m##                                                                            ##%ESC%[0m
    echo  %ESC%[1;31m################################################################################%ESC%[0m
    echo.
    echo   %ESC%[1;31m[ОШИБКА] Git не установлен или не добавлен в PATH.%ESC%[0m
    echo.
    echo   %ESC%[1;33mДля работы со скриптами требуется глобальный Git.%ESC%[0m
    echo.
    echo   %ESC%[1;37mСкачайте и установите Git for Windows:%ESC%[0m
    echo   %ESC%[1;36mhttps://git-scm.com/download/win%ESC%[0m
    echo.
    pause
    popd
    exit /b 1
)

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
echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mУстановка / Обновление Python...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Python.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;31m[ОШИБКА] Python не установился. Остановка.%ESC%[0m
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   ШАГ 2: Репозиторий
REM ============================================================================
echo.
echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mКлонирование / Обновление репозитория...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Repo.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не клонировался. Остановка.%ESC%[0m
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   ШАГ 3: Зависимости
REM ============================================================================
echo.
echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mУстановка PyTorch + зависимостей...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Dependencies.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;31m[ОШИБКА] Зависимости не установились. Остановка.%ESC%[0m
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   ШАГ 4: Модели
REM ============================================================================
echo.
echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mСкачивание моделей...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Models.bat" 1
if errorlevel 1 (
    echo   %ESC%[1;33m.   Модели не скачались (можно скачать позже).%ESC%[0m
    echo.
)

cls
echo.
echo  %ESC%[1;32m  +   Все компоненты успешно установлены / обновлены.%ESC%[0m
echo.
echo   %ESC%[1;33mУстановленные компоненты:%ESC%[0m
echo     %ESC%[2m- Python 3.11.9 (portable)%ESC%[0m
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