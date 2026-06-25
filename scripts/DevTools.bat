REM scripts\DevTools.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 Portable — Инструменты разработчика
pushd %~dp0..

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "REPO_DIR=%ROOT_DIR%\repo"
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
REM   Проверка Git
REM ============================================================================
git --version >nul 2>nul
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Git не найден.%ESC%[0m
    pause
    del "%PS_WRAPPER%" 2>nul
    popd
    exit /b 1
)
goto :dev_tools_menu

REM ============================================================================
REM   Проверка / настройка Git identity (локально, без глобальной системы)
REM ============================================================================
:check_git_identity
cd /d "%ROOT_DIR%" 2>nul

git config --local user.name >nul 2>nul
set "HAS_NAME=!errorlevel!"
git config --local user.email >nul 2>nul
set "HAS_EMAIL=!errorlevel!"

if !HAS_NAME! neq 0 (
    echo.
    echo   %ESC%[1;33m⚠  Git identity не настроена.%ESC%[0m
    echo   %ESC%[2m   Требуется для коммитов в репозиторий скриптов.%ESC%[0m
    echo.
    set "GIT_NAME="
    set /p "GIT_NAME=%ESC%[33mВведите имя (например, MRafStudio): %ESC%[0m"
    if "!GIT_NAME!"=="" set "GIT_NAME=MRafStudio"
    
    set "GIT_EMAIL="
    set /p "GIT_EMAIL=%ESC%[33mВведите email (например, raf@example.com): %ESC%[0m"
    if "!GIT_EMAIL!"=="" set "GIT_EMAIL=raf@rafstudio.local"
    
    git config --local user.name "!GIT_NAME!"
    git config --local user.email "!GIT_EMAIL!"
    
    echo   %ESC%[1;32m  +   Identity сохранена локально.%ESC%[0m
    echo.
    timeout /t 2 /nobreak >nul
)
if !HAS_EMAIL! neq 0 (
    REM Если name был, но email нет — отдельно обрабатываем
    if !HAS_NAME! equ 0 (
        echo.
        echo   %ESC%[1;33m⚠  Git email не настроен.%ESC%[0m
        set "GIT_EMAIL="
        set /p "GIT_EMAIL=%ESC%[33mВведите email: %ESC%[0m"
        if "!GIT_EMAIL!"=="" set "GIT_EMAIL=raf@rafstudio.local"
        git config --local user.email "!GIT_EMAIL!"
        echo   %ESC%[1;32m  +   Email сохранён.%ESC%[0m
        timeout /t 2 /nobreak >nul
    )
)
cd /d "%ROOT_DIR%" 2>nul
goto :eof

:dev_tools_menu
cls
echo.
echo  %ESC%[1;36m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;36m║%ESC%[0m                 %ESC%[1;37mAceStep-1.5 Portable%ESC%[0m  —  %ESC%[1;33mИнструменты разработчика%ESC%[0m            %ESC%[1;36m║%ESC%[0m
echo  %ESC%[1;36m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.

REM --- Статус репозиториев (одной строкой) ---
set "REPO_STATUS=%ESC%[1;31m- не клонирован%ESC%[0m"
set "SCRIPTS_STATUS=%ESC%[2mнет изменений%ESC%[0m"

if exist "%REPO_DIR%\.git" (
    cd /d "%REPO_DIR%" 2>nul
    for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "RB=%%a"
    git status --short > "%TEMP%\rs.txt" 2>nul
    set "RC=0"
    for /f %%a in ('type "%TEMP%\rs.txt"') do set "RC=1"
    del "%TEMP%\rs.txt" 2>nul
    cd /d "%ROOT_DIR%" 2>nul
    
    if "!RB!"=="ru-localization" (
        if "!RC!"=="1" (set "REPO_STATUS=%ESC%[1;33mru-localization [есть изменения]%ESC%[0m") else (set "REPO_STATUS=%ESC%[1;32mru-localization%ESC%[0m")
    ) else (
        set "REPO_STATUS=%ESC%[1;33m!RB! [ожидается ru-localization]%ESC%[0m"
    )
)

cd /d "%ROOT_DIR%" 2>nul
git status --short > "%TEMP%\ss.txt" 2>nul
for /f %%a in ('type "%TEMP%\ss.txt"') do set "SCRIPTS_STATUS=%ESC%[1;33mесть изменения%ESC%[0m"
del "%TEMP%\ss.txt" 2>nul

echo   %ESC%[2mACE-Step-1.5:%ESC%[0m  !REPO_STATUS!
echo   %ESC%[2mСкрипты:%ESC%[0m      !SCRIPTS_STATUS!
echo.

echo   %ESC%[1;34m── Обновление ────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[1]%ESC%[0m Обновить репозиторий ACE-Step-1.5
echo   %ESC%[1;37m[2]%ESC%[0m Обновить скрипты из GitHub
echo.
echo   %ESC%[1;34m── Отправка на GitHub ────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m Отправить локализацию
echo   %ESC%[1;37m[4]%ESC%[0m Отправить скрипты
echo.
echo   %ESC%[1;34m── Проверка ──────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[5]%ESC%[0m Статус репозиториев
echo.
echo   %ESC%[1;34m── Система ───────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[6]%ESC%[0m %ESC%[1;31mУдалить и переклонировать repo\%ESC%[0m
echo.
echo   %ESC%[1;37m[0]%ESC%[0m Назад
echo.
set "choice="
set /p "choice=%ESC%[33mДействие (0-6): %ESC%[0m"

set "choice=%choice: =%"
if "%choice%"=="" goto dev_tools_menu
if "%choice%"=="0" goto dev_tools_exit
if "%choice%"=="1" goto confirm_update_repo
if "%choice%"=="2" goto confirm_update_scripts
if "%choice%"=="3" goto confirm_push_localization
if "%choice%"=="4" goto confirm_push_scripts
if "%choice%"=="5" goto check_status
if "%choice%"=="6" goto confirm_destroy_repo
goto dev_tools_menu

REM ============================================================================
REM   [1] Обновить репозиторий ACE-Step-1.5
REM ============================================================================
:confirm_update_repo
cls
echo.
echo  %ESC%[1;33m→ Обновление репозитория ACE-Step-1.5%ESC%[0m
echo.
echo   %ESC%[2mВыполнит: git fetch origin + merge origin/main → ru-localization%ESC%[0m
echo   %ESC%[1;33m⚠  Риск: конфликты слияния → ручное разрешение в VS/VS Code%ESC%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=%ESC%[33mПродолжить? (y/n): %ESC%[0m"
if /I "%CONFIRM%"=="y" call "%SCRIPTS_DIR%\Update-From-Upstream.bat" & goto dev_tools_menu
goto dev_tools_menu

REM ============================================================================
REM   [2] Обновить скрипты из GitHub
REM ============================================================================
:confirm_update_scripts
cls
echo.
echo  %ESC%[1;33m→ Обновление скриптов из GitHub%ESC%[0m
echo.
echo   %ESC%[2mВыполнит: git pull origin main%ESC%[0m
echo   %ESC%[1;31m⚠  Локальные изменения скриптов будут ПЕРЕЗАПИСАНЫ!%ESC%[0m
echo   %ESC%[2mСовет: сначала сохраните изменения (пункт 4)%ESC%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=%ESC%[33mПродолжить? (y/n): %ESC%[0m"
if /I "%CONFIRM%"=="y" goto do_update_scripts
goto dev_tools_menu

:do_update_scripts
call :check_git_identity
cls
echo.
echo   %ESC%[1;33m→ Обновление...%ESC%[0m
cd /d "%ROOT_DIR%"
git pull origin main
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   Скрипты обновлены.%ESC%[0m
) else (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось обновить.%ESC%[0m
    echo   %ESC%[33m       Сохраните изменения ^(пункт 4^) и повторите.%ESC%[0m
)
goto dev_tools_menu

REM ============================================================================
REM   [3] Отправить локализацию
REM ============================================================================
:confirm_push_localization
cls
echo.
echo  %ESC%[1;33m→ Отправка локализации в GitHub%ESC%[0m
echo.
echo   %ESC%[2mЦель: MRafStudio/ACE-Step-1.5, ветка ru-localization%ESC%[0m
echo   %ESC%[1;33m⚠  Риск: сломанный код попадёт в репозиторий%ESC%[0m
echo   %ESC%[2mПри первом запуске: логин + Personal Access Token (не пароль!)%ESC%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=%ESC%[33mПродолжить? (y/n): %ESC%[0m"
if /I "%CONFIRM%"=="y" call "%SCRIPTS_DIR%\Push-Localization.bat" & goto dev_tools_menu
goto dev_tools_menu

REM ============================================================================
REM   [4] Отправить скрипты
REM ============================================================================
:confirm_push_scripts
cls
echo.
echo  %ESC%[1;33m→ Отправка скриптов в GitHub%ESC%[0m
echo.
echo   %ESC%[2mЦель: MRafStudio/AceStep-Portable-Scripts, ветка main%ESC%[0m
echo   %ESC%[1;31m⚠  ВНИМАНИЕ: Сломанный скрипт сломает установку у ВСЕХ пользователей!%ESC%[0m
echo   %ESC%[2mПри первом запуске: логин + Personal Access Token (не пароль!)%ESC%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=%ESC%[33mПродолжить? (y/n): %ESC%[0m"
if /I "%CONFIRM%"=="y" goto do_push_scripts
goto dev_tools_menu

:do_push_scripts
call :check_git_identity
cls
echo.
echo   %ESC%[1;33m→ Отправка скриптов...%ESC%[0m
cd /d "%ROOT_DIR%"

git status --short > "%TEMP%\ss.txt" 2>nul
set "HAS_CHANGES=0"
for /f %%a in ('type "%TEMP%\ss.txt"') do set "HAS_CHANGES=1"
del "%TEMP%\ss.txt" 2>nul

if "!HAS_CHANGES!"=="0" (
    echo   %ESC%[1;33mНет изменений для коммита.%ESC%[0m
    pause
    goto dev_tools_menu
)

echo   %ESC%[1;33mИзменённые файлы:%ESC%[0m
git status --short
echo.

set "COMMIT_MSG="
set /p "COMMIT_MSG=%ESC%[33mСообщение коммита: %ESC%[0m"
if "!COMMIT_MSG!"=="" (
    echo   %ESC%[1;31mСообщение не может быть пустым.%ESC%[0m
    pause
    goto dev_tools_menu
)

echo   %ESC%[1;33m→ Коммит...%ESC%[0m
git add .
git commit -m "!COMMIT_MSG!"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Коммит не удался.%ESC%[0m
    pause
    goto dev_tools_menu
)
echo   %ESC%[1;32m  +   Коммит создан.%ESC%[0m

echo   %ESC%[1;33m→ Пуш...%ESC%[0m
git push origin main
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   Отправлено в GitHub.%ESC%[0m
) else (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось запушить.%ESC%[0m
)
pause
goto dev_tools_menu

REM ============================================================================
REM   [5] Статус репозиториев
REM ============================================================================
:check_status
cls
echo.
echo  %ESC%[1;36m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;36m║%ESC%[0m              %ESC%[1;37mAceStep-1.5%ESC%[0m  —  %ESC%[1;33mСтатус репозиториев%ESC%[0m                  %ESC%[1;36m║%ESC%[0m
echo  %ESC%[1;36m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.

echo   %ESC%[1;37m── ACE-Step-1.5 (repo\) ────────────────────────────────────────────%ESC%[0m
if exist "%REPO_DIR%\.git" (
    cd /d "%REPO_DIR%" 2>nul
    echo   %ESC%[2mВетка:%ESC%[0m  & git branch -v
    echo   %ESC%[2mСтатус:%ESC%[0m & git status --short
    echo   %ESC%[2mRemotes:%ESC%[0m & git remote -v
    cd /d "%ROOT_DIR%" 2>nul
) else (
    echo   %ESC%[1;31m  -   Не клонирован%ESC%[0m
)

echo.
echo   %ESC%[1;37m── AceStep-Portable-Scripts (корень) ─────────────────────────────%ESC%[0m
cd /d "%ROOT_DIR%" 2>nul
echo   %ESC%[2mВетка:%ESC%[0m  & git branch -v
echo   %ESC%[2mСтатус:%ESC%[0m & git status --short
echo   %ESC%[2mRemotes:%ESC%[0m & git remote -v

echo.
echo   %ESC%[2mЛегенда: M=modified, A=added, D=deleted, ?=untracked%ESC%[0m
pause
goto dev_tools_menu

REM ============================================================================
REM   [6] Удалить и переклонировать repo\
REM ============================================================================
:confirm_destroy_repo
cls
echo.
echo  %ESC%[1;31m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;31m║%ESC%[0m              %ESC%[1;37m⚠  КРИТИЧЕСКАЯ ОПЕРАЦИЯ ⚠%ESC%[0m                              %ESC%[1;31m║%ESC%[0m
echo  %ESC%[1;31m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.
echo   %ESC%[1;31m⚠  ВСЕ ЛОКАЛЬНЫЕ ИЗМЕНЕНИЯ в repo\ БУДУТ УНИЧТОЖЕНЫ!%ESC%[0m
echo   %ESC%[2mНе затронуты: models\, output\, настройки.%ESC%[0m
echo.
echo   %ESC%[1;31mДля подтверждения введите: DESTROY%ESC%[0m
set "DESTROY_CONFIRM="
set /p "DESTROY_CONFIRM=%ESC%[33mВвод: %ESC%[0m"
if /I "%DESTROY_CONFIRM%"=="DESTROY" goto do_destroy_repo
echo   %ESC%[1;33mОтменено.%ESC%[0m
pause
goto dev_tools_menu

:do_destroy_repo
cls
echo.
echo   %ESC%[1;33m→ Удаление repo\...%ESC%[0m
if exist "%REPO_DIR%" (rmdir /s /q "%REPO_DIR%" & echo   %ESC%[1;32m  +   Удалено.%ESC%[0m) else (echo   %ESC%[2m       Не существует.%ESC%[0m)
echo   %ESC%[1;33m→ Переклонирование...%ESC%[0m
call "%SCRIPTS_DIR%\InstallOrUpdate-Repo.bat"
goto dev_tools_menu

:dev_tools_exit
del "%PS_WRAPPER%" 2>nul
popd
exit /b 0