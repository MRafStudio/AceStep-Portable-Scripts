@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 — Обновление ru-localization
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "REPO_DIR=%ROOT_DIR%\repo"
set "GIT_DIR=%ROOT_DIR%\git"
set "GIT_EXE=%GIT_DIR%\cmd\git.exe"

if not exist "%GIT_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Git не найден!%ESC%[0m
    pause
    popd
    exit /b 1
)

if not exist "%REPO_DIR%\.git" (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не клонирован!%ESC%[0m
    pause
    popd
    exit /b 1
)

set "PATH=%GIT_DIR%\cmd;%PATH%"

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m          %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mОбновление ru-localization%ESC%[0m              %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

cd /d "%REPO_DIR%"

REM ============================================================================
REM   Проверка текущей ветки
REM ============================================================================
for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%a"

if not "!CURRENT_BRANCH!"=="ru-localization" (
    echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mПереключение на ru-localization...%ESC%[0m
    git checkout ru-localization
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось переключиться.%ESC%[0m
        echo   %ESC%[33m       Возможно, ветки нет. Запустите InstallOrUpdate-Repo.bat%ESC%[0m
        pause
        popd
        exit /b 1
    )
    echo   %ESC%[1;32m  ✔   Переключено на ru-localization.%ESC%[0m
) else (
    echo   %ESC%[2m       Уже на ветке ru-localization.%ESC%[0m
)

REM ============================================================================
REM   Получение обновлений
REM ============================================================================
echo.
echo   %ESC%[1;33m[1/3]%ESC%[0m %ESC%[1mПолучение обновлений...%ESC%[0m
git fetch origin
git fetch upstream
echo   %ESC%[1;32m  ✔   Обновления получены.%ESC%[0m

REM ============================================================================
REM   Проверка, есть ли новые коммиты в origin/main
REM ============================================================================
echo.
echo   %ESC%[1;33m[2/3]%ESC%[0m %ESC%[1mПроверка изменений origin/main...%ESC%[0m

for /f %%a in ('git rev-list --count HEAD..origin/main 2^>nul') do set "COMMITS_BEHIND=%%a"

if "!COMMITS_BEHIND!"=="0" (
    echo   %ESC%[1;32m  ✔   Ваш форк актуален. Нет новых коммитов.%ESC%[0m
    echo.
    echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
    echo   %ESC%[1;32mОбновление не требуется!%ESC%[0m
    echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
    echo.
    pause
    popd
    exit /b 0
)

echo   %ESC%[1;33m  →   Доступно !COMMITS_BEHIND! новых коммитов в origin/main.%ESC%[0m

REM ============================================================================
REM   Мерж origin/main → ru-localization
REM ============================================================================
echo.
echo   %ESC%[1;33m[3/3]%ESC%[0m %ESC%[1mСлияние origin/main → ru-localization...%ESC%[0m
git merge origin/main --no-edit

if !errorlevel! neq 0 (
    echo.
    echo   %ESC%[1;31m[КОНФЛИКТ] Требуется ручное разрешение!%ESC%[0m
    echo   %ESC%[33m       Откройте репозиторий в VS 2022 и разрешите конфликты.%ESC%[0m
    echo.
    echo   %ESC%[33m       После разрешения:%ESC%[0m
    echo   %ESC%[33m       git add .%ESC%[0m
    echo   %ESC%[33m       git commit -m "Merge upstream updates into ru-localization"%ESC%[0m
    echo   %ESC%[33m       git push origin ru-localization%ESC%[0m
    echo.
    pause
    popd
    exit /b 1
)

echo   %ESC%[1;32m  ✔   Слияние завершено без конфликтов!%ESC%[0m

REM ============================================================================
REM   Пуш в GitHub
REM ============================================================================
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mОтправка в GitHub...%ESC%[0m
git push origin ru-localization

if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  ✔   ru-localization обновлена в GitHub!%ESC%[0m
) else (
    echo   %ESC%[1;33m  ⚠   Не удалось запушить. Проверьте соединение.%ESC%[0m
)

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mОбновление завершено!%ESC%[0m
echo   %ESC%[2m       Ветка ru-localization синхронизирована с origin/main.%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

pause
popd
exit /b 0