REM scripts\Push-Localization.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 — Отправка локализации в GitHub
pushd %~dp0..

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
REM   Проверка глобального Git (ОБЯЗАТЕЛЬНО!)
REM ============================================================================
git --version >nul 2>nul
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Git не найден. Установите Git сначала.%ESC%[0m
    echo   %ESC%[33m       https://git-scm.com/download/win%ESC%[0m
    pause
    del "%PS_WRAPPER%" 2>nul
    popd
    exit /b 1
)

if not exist "%REPO_DIR%\.git" (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не клонирован.%ESC%[0m
    echo   %ESC%[33m       Выполните клонирование репозитория ACE-Step-1.5 в меню установки/обновления%ESC%[0m
    pause
    del "%PS_WRAPPER%" 2>nul
    popd
    exit /b 1
)

cd /d "%REPO_DIR%"

REM ============================================================================
REM   Проверка ветки
REM ============================================================================
for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%a"

if not "!CURRENT_BRANCH!"=="ru-localization" (
    echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mПереключение на ru-localization...%ESC%[0m
    git checkout ru-localization
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось переключиться.%ESC%[0m
        echo   %ESC%[33m       Возможно, ветки нет. Запустите InstallOrUpdate-Repo.bat%ESC%[0m
        pause
        del "%PS_WRAPPER%" 2>nul
        popd
        exit /b 1
    )
)

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m               %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mОтправка локализации в GitHub%ESC%[0m              %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка изменений
REM ============================================================================
git status --short > "%TEMP%\git_status.txt" 2>nul
set "HAS_CHANGES=0"
for /f %%a in ('type "%TEMP%\git_status.txt"') do set "HAS_CHANGES=1"
del "%TEMP%\git_status.txt" 2>nul

if "!HAS_CHANGES!"=="0" (
    echo   %ESC%[1;33mНет изменений для коммита.%ESC%[0m
    echo   %ESC%[2m       Отредактируйте файлы в репозитории и повторите.%ESC%[0m
    echo.
    pause
    del "%PS_WRAPPER%" 2>nul
    popd
    exit /b 0
)

echo   %ESC%[1;33mИзменённые файлы:%ESC%[0m
echo.
git status --short
echo.

REM ============================================================================
REM   Коммит
REM ============================================================================
set "COMMIT_MSG="
set /p "COMMIT_MSG=%ESC%[33mСообщение коммита: %ESC%[0m"

if "!COMMIT_MSG!"=="" (
    echo.
    echo   %ESC%[1;31mСообщение не может быть пустым.%ESC%[0m
    pause
    del "%PS_WRAPPER%" 2>nul
    popd
    exit /b 1
)

echo.
echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mКоммит...%ESC%[0m
git add .
git commit -m "!COMMIT_MSG!"

if !errorlevel! neq 0 (
    echo.
    echo   %ESC%[1;31m[ОШИБКА] Коммит не удался.%ESC%[0m
    echo   %ESC%[33m       Возможно, нет изменений или проблема с Git.%ESC%[0m
    pause
    del "%PS_WRAPPER%" 2>nul
    popd
    exit /b 1
)

echo   %ESC%[1;32m  +   Коммит создан.%ESC%[0m

REM ============================================================================
REM   Пуш
REM ============================================================================
echo.
echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mОтправка в GitHub (MRafStudio/ACE-Step-1.5, ветка ru-localization)...%ESC%[0m
echo   %ESC%[2m       При первом запуске потребуется логин и Personal Access Token%ESC%[0m
echo.

git push origin ru-localization

if !errorlevel! equ 0 (
    echo.
    echo   %ESC%[1;32m  +   Отправлено в GitHub.%ESC%[0m
    echo   %ESC%[2m       https://github.com/MRafStudio/ACE-Step-1.5/tree/ru-localization%ESC%[0m
) else (
    echo.
    echo   %ESC%[1;31m[ОШИБКА] Не удалось запушить.%ESC%[0m
    echo   %ESC%[33m       Возможные причины:%ESC%[0m
    echo   %ESC%[33m       1. Нет интернета%ESC%[0m
    echo   %ESC%[33m       2. Неверный логин/токен ^(при первом запуске^)%ESC%[0m
    echo   %ESC%[33m       3. Конфликт с удалённой веткой ^(сделайте Update-From-Upstream.bat^)%ESC%[0m
)

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mГотово.%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

pause
del "%PS_WRAPPER%" 2>nul
popd
exit /b 0