@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title ACE-Step-1.5 — Клонирование / Обновление репозитория

REM ============================================================================
REM   Определение путей
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "REPO_DIR=%ROOT_DIR%\repo"
set "GIT_DIR=%ROOT_DIR%\git"
set "GIT_EXE=%GIT_DIR%\cmd\git.exe"

REM ============================================================================
REM   ИЗОЛЯЦИЯ ДАННЫХ
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul

REM ============================================================================
REM   КРИТИЧЕСКИ ВАЖНО: Создаём временный скрипт для PowerShell с изоляцией
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

REM ============================================================================
REM   Получение ESC через изолированный PowerShell
REM ============================================================================
for /f "usebackq" %%a in (`%PS_WRAPPER% -Command "Write-Host ([char]27) -NoNewline"`) do set "ESC=%%a"

REM ============================================================================
REM   Проверка Git: сначала глобальный, потом portable, потом ошибка
REM ============================================================================
set "GIT_FOUND=0"

REM 1. Проверяем глобальный Git
git --version >nul 2>nul
if !errorlevel! equ 0 (
    echo   %ESC%[2m       Глобальный Git найден.%ESC%[0m
    set "GIT_FOUND=1"
)

REM 2. Если нет глобального — проверяем portable
if !GIT_FOUND! equ 0 (
    if exist "%GIT_EXE%" (
        echo   %ESC%[2m       Portable Git найден: %GIT_EXE%%ESC%[0m
        set "PATH=%GIT_DIR%\cmd;%PATH%"
        set "GIT_FOUND=1"
    )
)

REM 3. Если нет ни того, ни другого — ошибка
if !GIT_FOUND! equ 0 (
    echo   %ESC%[1;31m[ОШИБКА] Git не найден. Установите Git сначала.%ESC%[0m
    echo   %ESC%[33m       Запустите: InstallOrUpdate-Git.bat%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    del "%PS_WRAPPER%" 2>nul
    exit /b 1
)

REM ============================================================================
REM   Проверяем, что git теперь работает
REM ============================================================================
git --version >nul 2>nul
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Git не работает. Проверьте установку.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    del "%PS_WRAPPER%" 2>nul
    exit /b 1
)

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m              %ESC%[1;37mACE-Step-1.5%ESC%[0m   —   %ESC%[1;33mКлонирование / Обновление репозитория%ESC%[0m      %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка существующего репозитория
REM ============================================================================
if exist "%REPO_DIR%\.git" (
    echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mРепозиторий найден. Обновление...%ESC%[0m
    echo.
    
    cd /d "%REPO_DIR%"
    
    for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%a"
    echo   %ESC%[2m       Текущая ветка: !CURRENT_BRANCH!%ESC%[0m
    
    git remote -v >nul 2>nul
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось прочитать remote.%ESC%[0m
        if "%AUTOCLOSE%"=="0" pause
        del "%PS_WRAPPER%" 2>nul
        exit /b 1
    )
    
    git remote get-url upstream >nul 2>nul
    if !errorlevel! neq 0 (
        echo   %ESC%[2m       Добавление upstream...%ESC%[0m
        git remote add upstream https://github.com/ace-step/ACE-Step-1.5.git
        echo   %ESC%[1;32m  +   Upstream добавлен.%ESC%[0m
    ) else (
        echo   %ESC%[2m       Upstream уже настроен.%ESC%[0m
    )
    
    echo.
    echo   %ESC%[1;33m[1/3]%ESC%[0m %ESC%[1mПолучение обновлений...%ESC%[0m
    git fetch origin
    git fetch upstream
    echo   %ESC%[1;32m  +   Обновления получены.%ESC%[0m
    
    git show-ref --verify --quiet refs/heads/ru-localization
    if !errorlevel! neq 0 (
        echo.
        echo   %ESC%[1;33m  .   Ветка ru-localization не найдена.%ESC%[0m
        echo   %ESC%[33m       Создаём из текущей ветки...%ESC%[0m
        git checkout -b ru-localization
        git push -u origin ru-localization
        echo   %ESC%[1;32m  +   Ветка ru-localization создана и запушена.%ESC%[0m
    ) else (
        echo   %ESC%[2m       Ветка ru-localization существует.%ESC%[0m
    )
    
    git show-ref --verify --quiet refs/remotes/origin/ru-localization
    if !errorlevel! neq 0 (
        echo.
        echo   %ESC%[1;33m  .   Ветка ru-localization не найдена на GitHub.%ESC%[0m
        echo   %ESC%[33m       Создаём и пушим...%ESC%[0m
        git push -u origin ru-localization
        echo   %ESC%[1;32m  +   Ветка запушена на GitHub.%ESC%[0m
    ) else (
        echo   %ESC%[2m       Ветка ru-localization на GitHub.%ESC%[0m
    )
    
    echo.
    echo   %ESC%[1;33m[2/3]%ESC%[0m %ESC%[1mПереключение на ru-localization...%ESC%[0m
    git checkout ru-localization
    echo   %ESC%[1;32m  +   На ветке ru-localization.%ESC%[0m
    
    echo.
    echo   %ESC%[1;33m[3/3]%ESC%[0m %ESC%[1mСлияние origin/main - ru-localization...%ESC%[0m
    git merge origin/main --no-edit
    
    if !errorlevel! neq 0 (
        echo.
        echo   %ESC%[1;31m[КОНФЛИКТ] Требуется ручное разрешение.%ESC%[0m
        echo   %ESC%[33m       Откройте репозиторий в VS 2022 и разрешите конфликты.%ESC%[0m
        echo   %ESC%[33m       После разрешения:%ESC%[0m
        echo   %ESC%[33m       git add .%ESC%[0m
        echo   %ESC%[33m       git commit -m "Merge upstream updates"%ESC%[0m
        echo   %ESC%[33m       git push origin ru-localization%ESC%[0m
        pause
        del "%PS_WRAPPER%" 2>nul
        exit /b 1
    ) else (
        echo   %ESC%[1;32m  +   Слияние завершено без конфликтов.%ESC%[0m
    )
    
    echo.
    echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
    echo   %ESC%[1;32mРепозиторий обновлён.%ESC%[0m
    echo   %ESC%[2m       Ветка: ru-localization%ESC%[0m
    echo   %ESC%[2m       origin/main: актуален (workflow обновляет)%ESC%[0m
    echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
    echo.
    
    del "%PS_WRAPPER%" 2>nul
    if "%AUTOCLOSE%"=="0" pause
    exit /b 0
) else (
    REM ============================================================================
    REM   Клонирование нового репозитория
    REM ============================================================================
    echo   %ESC%[1;33m[1/2]%ESC%[0m %ESC%[1mКлонирование форка MRafStudio/ACE-Step-1.5...%ESC%[0m
    echo   %ESC%[2m       Ветка: ru-localization (рабочая)%ESC%[0m
    echo   %ESC%[2m       ~100 МБ (исходный код)%ESC%[0m

    if exist "%REPO_DIR%" rmdir /s /q "%REPO_DIR%"
    mkdir "%REPO_DIR%" 2>nul

    git clone --depth 1 https://github.com/MRafStudio/ACE-Step-1.5.git "%REPO_DIR%"
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось клонировать репозиторий.%ESC%[0m
        del "%PS_WRAPPER%" 2>nul
        if "%AUTOCLOSE%"=="0" pause
        exit /b 1
    )

    echo   %ESC%[1;32m  +   Репозиторий клонирован (main).%ESC%[0m

    cd /d "%REPO_DIR%"

    echo.
    echo   %ESC%[1;33m[2/2]%ESC%[0m %ESC%[1mНастройка upstream и переключение на ru-localization...%ESC%[0m
    git remote add upstream https://github.com/ace-step/ACE-Step-1.5.git

    git fetch origin
    git show-ref --verify --quiet refs/remotes/origin/ru-localization

    if !errorlevel! equ 0 (
        echo   %ESC%[2m       Ветка ru-localization найдена на GitHub.%ESC%[0m
        git checkout ru-localization
        echo   %ESC%[1;32m  +   Переключено на ru-localization.%ESC%[0m
    ) else (
        echo   %ESC%[2m       Ветка ru-localization не найдена, создаём...%ESC%[0m
        git checkout -b ru-localization
        git push -u origin ru-localization
        echo   %ESC%[1;32m  +   Ветка ru-localization создана и запушена.%ESC%[0m
    )

    echo.
    echo   %ESC%[1;32m  +   Upstream настроен.%ESC%[0m
    echo   %ESC%[2m       origin:  https://github.com/MRafStudio/ACE-Step-1.5.git%ESC%[0m
    echo   %ESC%[2m       upstream: https://github.com/ace-step/ACE-Step-1.5.git%ESC%[0m
    echo   %ESC%[2m       Ветка: ru-localization (рабочая)%ESC%[0m
    echo   %ESC%[2m       main: автообновление от workflow%ESC%[0m

    echo.
    echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
    echo   %ESC%[1;32mКлонирование завершено.%ESC%[0m
    echo   %ESC%[2m       Рабочая ветка: ru-localization%ESC%[0m
    echo   %ESC%[2m       Не забудьте: все правки коммить в ru-localization.%ESC%[0m
    echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
    echo.

    del "%PS_WRAPPER%" 2>nul
    if "%AUTOCLOSE%"=="0" pause
    exit /b 0
)