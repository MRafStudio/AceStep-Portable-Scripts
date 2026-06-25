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

:dev_tools_menu
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m              %ESC%[1;37mAceStep-1.5 Portable%ESC%[0m   —   %ESC%[1;33mИнструменты разработчика%ESC%[0m           %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка репозитория ACE-Step-1.5
REM ============================================================================
set "REPO_EXISTS=0"
set "REPO_BRANCH="
set "REPO_CHANGES=0"
if exist "%REPO_DIR%\.git" (
    cd /d "%REPO_DIR%" 2>nul
    for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "REPO_BRANCH=%%a"
    
    REM Проверяем, есть ли незакоммиченные изменения
    git status --short > "%TEMP%\repo_status.txt" 2>nul
    for /f %%a in ('type "%TEMP%\repo_status.txt"') do set "REPO_CHANGES=1"
    del "%TEMP%\repo_status.txt" 2>nul
    
    cd /d "%ROOT_DIR%" 2>nul
    
    if "!REPO_BRANCH!"=="ru-localization" (
        if "!REPO_CHANGES!"=="1" (
            echo   %ESC%[1;33m.  %ESC%[0m Репозиторий ACE-Step-1.5: %ESC%[1;33mru-localization%ESC%[0m %ESC%[1;33m^(есть изменения^)%ESC%[0m
        ) else (
            echo   %ESC%[1;32m+  %ESC%[0m Репозиторий ACE-Step-1.5: %ESC%[1;33mru-localization%ESC%[0m
        )
    ) else (
        echo   %ESC%[1;33m.  %ESC%[0m Репозиторий ACE-Step-1.5: %ESC%[1;33m!REPO_BRANCH!%ESC%[0m %ESC%[2m^(ожидается ru-localization^)%ESC%[0m
    )
    set "REPO_EXISTS=1"
) else (
    echo   %ESC%[1;31m-  %ESC%[0m Репозиторий ACE-Step-1.5 — не клонирован
)

REM ============================================================================
REM   Проверка репозитория скриптов (AceStep-Portable-Scripts)
REM ============================================================================
set "SCRIPTS_CHANGES=0"
cd /d "%ROOT_DIR%" 2>nul
git status --short > "%TEMP%\scripts_status.txt" 2>nul
for /f %%a in ('type "%TEMP%\scripts_status.txt"') do set "SCRIPTS_CHANGES=1"
del "%TEMP%\scripts_status.txt" 2>nul

if "!SCRIPTS_CHANGES!"=="1" (
    echo   %ESC%[1;33m.  %ESC%[0m Скрипты: %ESC%[1;33mесть незакоммиченные изменения%ESC%[0m
) else (
    echo   %ESC%[1;32m+  %ESC%[0m Скрипты: %ESC%[2mнет изменений%ESC%[0m
)

echo.
echo   %ESC%[1;34m── Обновление локальных репозиториев ────────────────────────────────%ESC%[0m
echo.
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mОбновить локальный репозиторий ACE-Step-1.5%ESC%[0m
echo       %ESC%[2m(git fetch origin + merge origin/main → ru-localization)%ESC%[0m
echo       %ESC%[1;33m⚠ Риск: конфликты слияния, потребуется ручное разрешение%ESC%[0m
echo.
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mОбновить скрипты AceStep-Portable-Scripts%ESC%[0m
echo       %ESC%[2m(git pull из GitHub)%ESC%[0m
echo       %ESC%[1;33m⚠ Риск: локальные изменения скриптов будут ПЕРЕЗАПИСАНЫ%ESC%[0m

echo.
echo   %ESC%[1;34m── Отправка изменений на GitHub ───────────────────────────────────%ESC%[0m
echo.
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mОтправить локализацию в GitHub%ESC%[0m
echo       %ESC%[2m(git commit + push ru-localization → MRafStudio/ACE-Step-1.5)%ESC%[0m
echo       %ESC%[1;33m⚠ Риск: сломанный код попадёт в репозиторий%ESC%[0m
echo       %ESC%[2m⚠ Требует Personal Access Token при первом запуске%ESC%[0m
echo.
echo   %ESC%[1;37m[4]%ESC%[0m %ESC%[1mОтправить скрипты в GitHub%ESC%[0m
echo       %ESC%[2m(git commit + push → MRafStudio/AceStep-Portable-Scripts)%ESC%[0m
echo       %ESC%[1;33m⚠ Риск: сломанный скрипт сломает установку у других пользователей%ESC%[0m
echo       %ESC%[2m⚠ Требует Personal Access Token при первом запуске%ESC%[0m

echo.
echo   %ESC%[1;34m── Проверка статуса ─────────────────────────────────────────────%ESC%[0m
echo.
echo   %ESC%[1;37m[5]%ESC%[0m %ESC%[1mПроверить статус репозиториев%ESC%[0m
echo       %ESC%[2m(git status для ACE-Step-1.5 и AceStep-Portable-Scripts)%ESC%[0m

echo.
echo   %ESC%[1;34m── Системные операции ─────────────────────────────────────────────%ESC%[0m
echo.
echo   %ESC%[1;37m[6]%ESC%[0m %ESC%[1mУдалить и переклонировать репозиторий ACE-Step-1.5%ESC%[0m
echo       %ESC%[1;31m⚠ ВНИМАНИЕ: Все локальные изменения в repo\ будут УНИЧТОЖЕНЫ%ESC%[0m

echo.
echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mНазад в главное меню%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите действие (0-6): %ESC%[0m"

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
REM   [1] Подтверждение: Обновить локальный репозиторий ACE-Step-1.5
REM ============================================================================
:confirm_update_repo
cls
echo.
echo   %ESC%[1;33m→ Обновление локального репозитория ACE-Step-1.5%ESC%[0m
echo.
echo   %ESC%[2mЧто будет выполнено:%ESC%[0m
echo     git fetch origin
echo     git merge origin/main → ru-localization
echo.
echo   %ESC%[1;33mРиски:%ESC%[0m
echo     • Конфликты слияния → потребуется ручное разрешение в VS 2022
echo     • Локальные изменения в ru-localization сохранятся (если нет конфликтов)
echo.
set "CONFIRM="
set /p "CONFIRM=%ESC%[33mПродолжить? (y/n): %ESC%[0m"
if /I "%CONFIRM%"=="y" goto do_update_repo
goto dev_tools_menu

:do_update_repo
call "%SCRIPTS_DIR%\Update-From-Upstream.bat"
goto dev_tools_menu

REM ============================================================================
REM   [2] Подтверждение: Обновить скрипты AceStep-Portable-Scripts
REM ============================================================================
:confirm_update_scripts
cls
echo.
echo   %ESC%[1;33m→ Обновление скриптов AceStep-Portable-Scripts%ESC%[0m
echo.
echo   %ESC%[2mЧто будет выполнено:%ESC%[0m
echo     git pull origin main
echo.
echo   %ESC%[1;31m⚠ ВНИМАНИЕ: Локальные изменения в скриптах будут ПЕРЕЗАПИСАНЫ.%ESC%[0m
echo   %ESC%[33mЕсли вы правили скрипты — они пропадут.%ESC%[0m
echo.
echo   %ESC%[2mРекомендация: перед обновлением сохраните изменения через пункт [4].%ESC%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=%ESC%[33mПродолжить? (y/n): %ESC%[0m"
if /I "%CONFIRM%"=="y" goto do_update_scripts
goto dev_tools_menu

:do_update_scripts
cls
echo.
echo   %ESC%[1;33m→ Обновление скриптов из GitHub...%ESC%[0m
echo.
cd /d "%ROOT_DIR%"
git pull origin main
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   Скрипты обновлены.%ESC%[0m
) else (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось обновить скрипты.%ESC%[0m
    echo   %ESC%[33m       Возможно, есть локальные изменения или конфликты.%ESC%[0m
    echo   %ESC%[33m       Сохраните изменения (пункт [4]) и повторите.%ESC%[0m
)
echo.
pause
goto dev_tools_menu

REM ============================================================================
REM   [3] Подтверждение: Отправить локализацию в GitHub
REM ============================================================================
:confirm_push_localization
cls
echo.
echo   %ESC%[1;33m→ Отправка локализации в GitHub%ESC%[0m
echo.
echo   %ESC%[2mЧто будет выполнено:%ESC%[0m
echo     git add .
echo     git commit -m "ваше сообщение"
echo     git push origin ru-localization
echo.
echo   %ESC%[2mЦелевой репозиторий: https://github.com/MRafStudio/ACE-Step-1.5%ESC%[0m
echo.
echo   %ESC%[1;33m⚠ Риск: сломанный код попадёт в репозиторий и сломает сборку.%ESC%[0m
echo   %ESC%[2m⚠ При первом запуске потребуется логин и Personal Access Token.%ESC%[0m
echo   %ESC%[2m   Не используйте пароль от GitHub — только Token.%ESC%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=%ESC%[33mПродолжить? (y/n): %ESC%[0m"
if /I "%CONFIRM%"=="y" goto do_push_localization
goto dev_tools_menu

:do_push_localization
call "%SCRIPTS_DIR%\Push-Localization.bat"
goto dev_tools_menu

REM ============================================================================
REM   [4] Подтверждение: Отправить скрипты в GitHub
REM ============================================================================
:confirm_push_scripts
cls
echo.
echo   %ESC%[1;33m→ Отправка скриптов в GitHub%ESC%[0m
echo.
echo   %ESC%[2mЧто будет выполнено:%ESC%[0m
echo     git add .
echo     git commit -m "ваше сообщение"
echo     git push origin main
echo.
echo   %ESC%[2mЦелевой репозиторий: https://github.com/MRafStudio/AceStep-Portable-Scripts%ESC%[0m
echo.
echo   %ESC%[1;31m⚠ ВНИМАНИЕ: Сломанный скрипт сломает установку у ВСЕХ пользователей.%ESC%[0m
echo   %ESC%[33mПроверьте скрипты перед отправкой.%ESC%[0m
echo.
echo   %ESC%[2m⚠ При первом запуске потребуется логин и Personal Access Token.%ESC%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=%ESC%[33mПродолжить? (y/n): %ESC%[0m"
if /I "%CONFIRM%"=="y" goto do_push_scripts
goto dev_tools_menu

:do_push_scripts
cls
echo.
echo   %ESC%[1;33m→ Отправка скриптов в GitHub...%ESC%[0m
echo.
cd /d "%ROOT_DIR%"

REM Проверяем, есть ли изменения
git status --short > "%TEMP%\scripts_status.txt" 2>nul
set "HAS_CHANGES=0"
for /f %%a in ('type "%TEMP%\scripts_status.txt"') do set "HAS_CHANGES=1"
del "%TEMP%\scripts_status.txt" 2>nul

if "!HAS_CHANGES!"=="0" (
    echo   %ESC%[1;33mНет изменений для коммита.%ESC%[0m
    echo   %ESC%[2m       Отредактируйте скрипты и повторите.%ESC%[0m
    echo.
    pause
    goto dev_tools_menu
)

echo   %ESC%[1;33mИзменённые файлы:%ESC%[0m
echo.
git status --short
echo.

set "COMMIT_MSG="
set /p "COMMIT_MSG=%ESC%[33mСообщение коммита: %ESC%[0m"

if "!COMMIT_MSG!"=="" (
    echo.
    echo   %ESC%[1;31mСообщение не может быть пустым.%ESC%[0m
    pause
    goto dev_tools_menu
)

echo.
echo   %ESC%[1;33m→ Коммит...%ESC%[0m
git add .
git commit -m "!COMMIT_MSG!"

if !errorlevel! neq 0 (
    echo.
    echo   %ESC%[1;31m[ОШИБКА] Коммит не удался.%ESC%[0m
    pause
    goto dev_tools_menu
)

echo   %ESC%[1;32m  +   Коммит создан.%ESC%[0m

echo.
echo   %ESC%[1;33m→ Пуш в GitHub...%ESC%[0m
git push origin main

if !errorlevel! equ 0 (
    echo.
    echo   %ESC%[1;32m  +   Скрипты отправлены в GitHub.%ESC%[0m
    echo   %ESC%[2m       https://github.com/MRafStudio/AceStep-Portable-Scripts%ESC%[0m
) else (
    echo.
    echo   %ESC%[1;31m[ОШИБКА] Не удалось запушить.%ESC%[0m
    echo   %ESC%[33m       Проверьте соединение и токен.%ESC%[0m
)

echo.
pause
goto dev_tools_menu

REM ============================================================================
REM   [5] Проверить статус репозиториев
REM ============================================================================
:check_status
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m              %ESC%[1;37mAceStep-1.5 Portable%ESC%[0m   —   %ESC%[1;33mСтатус репозиториев%ESC%[0m              %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Статус ACE-Step-1.5
REM ============================================================================
echo   %ESC%[1;37m── ACE-Step-1.5 (repo\) ────────────────────────────────────────────%ESC%[0m
echo.
if exist "%REPO_DIR%\.git" (
    cd /d "%REPO_DIR%" 2>nul
    echo   %ESC%[2mВетка:%ESC%[0m
    git branch -v
    echo.
    echo   %ESC%[2mСтатус:%ESC%[0m
    git status --short
    echo.
    echo   %ESC%[2mRemotes:%ESC%[0m
    git remote -v
    cd /d "%ROOT_DIR%" 2>nul
) else (
    echo   %ESC%[1;31m  -   Репозиторий не клонирован.%ESC%[0m
)

echo.
echo   %ESC%[1;37m── AceStep-Portable-Scripts (корень проекта) ─────────────────────%ESC%[0m
echo.
cd /d "%ROOT_DIR%" 2>nul
echo   %ESC%[2mВетка:%ESC%[0m
git branch -v
echo.
echo   %ESC%[2mСтатус:%ESC%[0m
git status --short
echo.
echo   %ESC%[2mRemotes:%ESC%[0m
git remote -v

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[2mЛегенда: M = modified, A = added, D = deleted, ? = untracked%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

pause
goto dev_tools_menu

REM ============================================================================
REM   [6] Подтверждение: Удалить и переклонировать репозиторий ACE-Step-1.5
REM ============================================================================
:confirm_destroy_repo
cls
echo.
echo   %ESC%[1;31m################################################################################%ESC%[0m
echo   %ESC%[1;31m##                                                                            ##%ESC%[0m
echo   %ESC%[1;31m##%ESC%[0m              %ESC%[1;37m⚠⚠⚠ КРИТИЧЕСКАЯ ОПЕРАЦИЯ ⚠⚠⚠%ESC%[0m                              %ESC%[1;31m##%ESC%[0m
echo   %ESC%[1;31m##                                                                            ##%ESC%[0m
echo   %ESC%[1;31m################################################################################%ESC%[0m
echo.
echo   %ESC%[1;33m→ Удаление и переклонирование репозитория ACE-Step-1.5%ESC%[0m
echo.
echo   %ESC%[2mЧто будет выполнено:%ESC%[0m
echo     1. Удаление папки %REPO_DIR%
echo     2. git clone https://github.com/MRafStudio/ACE-Step-1.5.git
echo     3. Переключение на ветку ru-localization
echo.
echo   %ESC%[1;31m⚠ ВСЕ ЛОКАЛЬНЫЕ ИЗМЕНЕНИЯ в repo\ БУДУТ УНИЧТОЖЕНЫ.%ESC%[0m
echo   %ESC%[2mНе затронуты: модели (models\), выходные файлы (output\), настройки.%ESC%[0m
echo.
echo   %ESC%[1;31mДля подтверждения введите: DESTROY%ESC%[0m
echo   %ESC%[2m(или любой другой текст для отмены)%ESC%[0m
echo.
set "DESTROY_CONFIRM="
set /p "DESTROY_CONFIRM=%ESC%[33mВвод: %ESC%[0m"

if /I "%DESTROY_CONFIRM%"=="DESTROY" goto do_destroy_repo
echo.
echo   %ESC%[1;33mОперация отменена.%ESC%[0m
pause
goto dev_tools_menu

:do_destroy_repo
cls
echo.
echo   %ESC%[1;33m→ Удаление репозитория...%ESC%[0m
if exist "%REPO_DIR%" (
    rmdir /s /q "%REPO_DIR%"
    echo   %ESC%[1;32m  +   Папка repo\ удалена.%ESC%[0m
) else (
    echo   %ESC%[2m       Папка repo\ не существует.%ESC%[0m
)

echo.
echo   %ESC%[1;33m→ Переклонирование...%ESC%[0m
call "%SCRIPTS_DIR%\InstallOrUpdate-Repo.bat"
goto dev_tools_menu

:dev_tools_exit
del "%PS_WRAPPER%" 2>nul
popd
exit /b 0