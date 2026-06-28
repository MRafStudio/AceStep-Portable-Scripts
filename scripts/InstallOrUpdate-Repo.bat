REM scripts\InstallOrUpdate-Repo.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title ACE-Step-1.5 — Клонирование / Обновление репозитория

REM ============================================================================
REM   Получение ESC через PowerShell
REM ============================================================================
for /f %%a in ('powershell -NoProfile -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение путей
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "REPO_DIR=%ROOT_DIR%\repo"

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
REM   Проверка глобального Git (ОБЯЗАТЕЛЬНО!)
REM ============================================================================
git --version >nul 2>nul
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Git не найден. Установите Git сначала.%ESC%[0m
    echo   %ESC%[33m       https://git-scm.com/download/win%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    del "%PS_WRAPPER%" 2>nul
    exit /b 1
)

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m           %ESC%[1;37mACE-Step-1.5%ESC%[0m   —   %ESC%[1;33mКлонирование / Обновление репозитория%ESC%[0m         %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Развилка: репозиторий есть или нет
REM ============================================================================
if exist "%REPO_DIR%\.git" goto update_repo
goto clone_repo

REM ============================================================================
REM   ОБНОВЛЕНИЕ СУЩЕСТВУЮЩЕГО РЕПОЗИТОРИЯ
REM ============================================================================
:update_repo
echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mРепозиторий найден. Обновление...%ESC%[0m
echo.

cd /d "%REPO_DIR%"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось перейти в %REPO_DIR%%ESC%[0m
    goto error_exit
)

if not exist ".git" (
    echo   %ESC%[1;31m[ОШИБКА] Не найден .git в %REPO_DIR%%ESC%[0m
    goto error_exit
)

for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%a"
echo   %ESC%[2m       Текущая ветка: !CURRENT_BRANCH!%ESC%[0m

echo.
echo   %ESC%[1;33m[1/3]%ESC%[0m %ESC%[1mПолучение обновлений из origin...%ESC%[0m
git fetch origin
echo   %ESC%[1;32m  +   Обновления получены.%ESC%[0m

echo.
echo   %ESC%[1;33m[2/3]%ESC%[0m %ESC%[1mПереключение на ru-localization...%ESC%[0m
git checkout ru-localization
echo   %ESC%[1;32m  +   На ветке ru-localization.%ESC%[0m

echo.
echo   %ESC%[1;33m[3/3]%ESC%[0m %ESC%[1mСлияние origin/main → ru-localization...%ESC%[0m
git merge origin/main --no-edit

if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[КОНФЛИКТ] Требуется ручное разрешение.%ESC%[0m
    echo   %ESC%[33m       Откройте репозиторий в VS/VCode и разрешите конфликты.%ESC%[0m
    pause
    goto error_exit
)

echo   %ESC%[1;32m  +   Слияние завершено без конфликтов.%ESC%[0m

echo.
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;32mРепозиторий обновлён.%ESC%[0m
echo   %ESC%[2m       Ветка: ru-localization%ESC%[0m
echo   %ESC%[2m       origin/main: актуален (синхронизирован workflow)%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m

goto success_exit

REM ============================================================================
REM   КЛОНИРОВАНИЕ РЕПОЗИТОРИЯ
REM ============================================================================
:clone_repo
echo   %ESC%[1;33m[1/2]%ESC%[0m %ESC%[1mКлонирование форка MRafStudio/ACE-Step-1.5...%ESC%[0m
echo   %ESC%[2m       Ветка: ru-localization (рабочая)%ESC%[0m
echo   %ESC%[2m       ~100 МБ (исходный код)%ESC%[0m

if exist "%REPO_DIR%" rmdir /s /q "%REPO_DIR%"
mkdir "%REPO_DIR%" 2>nul

git clone https://github.com/MRafStudio/ACE-Step-1.5.git "%REPO_DIR%"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось клонировать репозиторий.%ESC%[0m
    goto error_exit
)

echo   %ESC%[1;32m  +   Репозиторий клонирован.%ESC%[0m

cd /d "%REPO_DIR%"

echo.
echo   %ESC%[1;33m[2/2]%ESC%[0m %ESC%[1mНастройка рабочей ветки ru-localization...%ESC%[0m

REM Проверяем, есть ли ветка ru-localization на GitHub
git fetch origin ru-localization 2>nul
if !errorlevel! equ 0 (
    REM Ветка есть на GitHub — переключаемся на неё
    git checkout -b ru-localization origin/ru-localization
    if !errorlevel! neq 0 (
        REM Если не получилось (уже есть локально), просто переключаемся
        git checkout ru-localization
    )
    echo   %ESC%[1;32m  +   Переключено на существующую ветку ru-localization.%ESC%[0m
    echo   %ESC%[2m       ^(сохранены все предыдущие коммиты локализации^)%ESC%[0m
) else (
    REM Ветки нет на GitHub — создаём новую от main
    git checkout -b ru-localization origin/main
    git push -u origin ru-localization
    echo   %ESC%[1;32m  +   Ветка ru-localization создана и запушена.%ESC%[0m
)

echo   %ESC%[2m       origin:  https://github.com/MRafStudio/ACE-Step-1.5.git%ESC%[0m
echo   %ESC%[2m       Ветка: ru-localization (рабочая)%ESC%[0m
echo   %ESC%[2m       main: автообновление от workflow%ESC%[0m

echo.
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;32mКлонирование завершено.%ESC%[0m
echo   %ESC%[2m       Рабочая ветка: ru-localization%ESC%[0m
echo   %ESC%[2m       Не забудьте: все правки коммить в ru-localization.%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m

goto success_exit

REM ============================================================================
REM   ВЫХОДЫ
REM ============================================================================
:error_exit
if "%AUTOCLOSE%"=="1" (
    call "%~dp0SmartPause.bat" 5
) else (
    pause
)
exit /b 0

:success_exit
if "%AUTOCLOSE%"=="1" (
    call "%~dp0SmartPause.bat"
) else (
    pause
)
exit /b 0