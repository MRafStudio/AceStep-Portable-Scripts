@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title ACE-Step-1.5 — Клонирование / Обновление репозитория
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

set "ROOT_DIR=%~dp0.."
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "REPO_DIR=%ROOT_DIR%\repo"
set "GIT_DIR=%ROOT_DIR%\git"
set "GIT_EXE=%GIT_DIR%\cmd\git.exe"

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
REM   Проверка Git
REM ============================================================================
if not exist "%GIT_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Git не найден! Установите Git сначала.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

set "PATH=%GIT_DIR%\cmd;%PATH%"

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m          %ESC%[1;37mACE-Step-1.5%ESC%[0m   —   %ESC%[1;33mКлонирование / Обновление репозитория%ESC%[0m      %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка существующего репозитория
REM ============================================================================
if exist "%REPO_DIR%\.git" (
    echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mРепозиторий найден. Обновление...%ESC%[0m
    echo.
    
    cd /d "%REPO_DIR%"
    
    REM Проверяем remote
    git remote -v >nul 2>nul
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось прочитать remote.%ESC%[0m
        if "%AUTOCLOSE%"=="0" pause
        popd
        exit /b 1
    )
    
    REM Проверяем upstream
    git remote get-url upstream >nul 2>nul
    if !errorlevel! neq 0 (
        echo   %ESC%[2m       Добавление upstream...%ESC%[0m
        git remote add upstream https://github.com/ace-step/ACE-Step-1.5.git
        echo   %ESC%[1;32m  ✔   Upstream добавлен.%ESC%[0m
    ) else (
        echo   %ESC%[2m       Upstream уже настроен.%ESC%[0m
    )
    
    REM Fetch upstream
    echo   %ESC%[2m       Получение обновлений с upstream...%ESC%[0m
    git fetch upstream
    if !errorlevel! neq 0 (
        echo   %ESC%[1;33m  ⚠   Не удалось получить обновления.%ESC%[0m
        echo   %ESC%[33m       Возможно, нет интернета.%ESC%[0m
    ) else (
        echo   %ESC%[1;32m  ✔   Обновления получены.%ESC%[0m
    )
    
    REM Merge upstream/main
    echo   %ESC%[2m       Слияние upstream/main...%ESC%[0m
    git merge upstream/main --no-edit
    if !errorlevel! neq 0 (
        echo   %ESC%[1;33m  ⚠   Конфликт слияния!%ESC%[0m
        echo   %ESC%[33m       Разрешите конфликт вручную:%ESC%[0m
        echo   %ESC%[33m       cd %REPO_DIR%%ESC%[0m
        echo   %ESC%[33m       git status%ESC%[0m
    ) else (
        echo   %ESC%[1;32m  ✔   Репозиторий обновлён.%ESC%[0m
    )
    
    echo.
    echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
    echo   %ESC%[1;32mОбновление репозитория завершено!%ESC%[0m
    echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
    echo.
    
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 0
)

REM ============================================================================
REM   Клонирование нового репозитория
REM ============================================================================
echo   %ESC%[1;33m[1/2]%ESC%[0m %ESC%[1mКлонирование форка MRafStudio/ACE-Step-1.5...%ESC%[0m
echo   %ESC%[2m       ~100 МБ (исходный код)%ESC%[0m

if exist "%REPO_DIR%" rmdir /s /q "%REPO_DIR%"
mkdir "%REPO_DIR%" 2>nul

git clone --depth 1 https://github.com/MRafStudio/ACE-Step-1.5.git "%REPO_DIR%"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось клонировать репозиторий.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

echo   %ESC%[1;32m  ✔   Репозиторий клонирован.%ESC%[0m
echo.
echo   %ESC%[1;33m[2/2]%ESC%[0m %ESC%[1mНастройка upstream...%ESC%[0m

cd /d "%REPO_DIR%"
git remote add upstream https://github.com/ace-step/ACE-Step-1.5.git

echo   %ESC%[1;32m  ✔   Upstream настроен.%ESC%[0m
echo   %ESC%[2m       origin:  https://github.com/MRafStudio/ACE-Step-1.5.git%ESC%[0m
echo   %ESC%[2m       upstream: https://github.com/ace-step/ACE-Step-1.5.git%ESC%[0m

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mКлонирование репозитория завершено!%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

if "%AUTOCLOSE%"=="0" pause
popd
exit /b 0