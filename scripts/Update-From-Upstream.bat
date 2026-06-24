@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 — Обновление с оригинального репозитория
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение ROOT_DIR (корень проекта = уровень выше scripts\)
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
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
REM   Проверка Git и репозитория
REM ============================================================================
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
echo  %ESC%[1;36m##%ESC%[0m          %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mОбновление с оригинального репозитория%ESC%[0m    %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

cd /d "%REPO_DIR%"

REM ============================================================================
REM   Проверка upstream
REM ============================================================================
git remote get-url upstream >nul 2>nul
if !errorlevel! neq 0 (
    echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mДобавление upstream...%ESC%[0m
    git remote add upstream https://github.com/ace-step/ACE-Step-1.5.git
    echo   %ESC%[1;32m  ✔   Upstream добавлен.%ESC%[0m
) else (
    echo   %ESC%[2m       Upstream уже настроен.%ESC%[0m
)

REM ============================================================================
REM   Fetch upstream
REM ============================================================================
echo.
echo   %ESC%[1;33m[1/3]%ESC%[0m %ESC%[1mПолучение обновлений...%ESC%[0m
git fetch upstream
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось получить обновления.%ESC%[0m
    pause
    popd
    exit /b 1
)
echo   %ESC%[1;32m  ✔   Обновления получены.%ESC%[0m

REM ============================================================================
REM   Проверка изменений
REM ============================================================================
echo.
echo   %ESC%[1;33m[2/3]%ESC%[0m %ESC%[1mПроверка изменений...%ESC%[0m

for /f %%a in ('git rev-list --count HEAD..upstream/main') do set "COMMITS_BEHIND=%%a"

if "!COMMITS_BEHIND!"=="0" (
    echo   %ESC%[1;32m  ✔   Ваш форк актуален. Нет новых коммитов.%ESC%[0m
    echo.
    pause
    popd
    exit /b 0
)

echo   %ESC%[1;33m  →   Доступно !COMMITS_BEHIND! новых коммитов.%ESC%[0m

REM ============================================================================
REM   Merge
REM ============================================================================
echo.
echo   %ESC%[1;33m[3/3]%ESC%[0m %ESC%[1mСлияние...%ESC%[0m

git stash
git merge upstream/main --no-edit

if !errorlevel! neq 0 (
    echo.
    echo   %ESC%[1;31m[ОШИБКА] Конфликт слияния!%ESC%[0m
    echo   %ESC%[33m       Разрешите конфликт вручную:%ESC%[0m
    echo   %ESC%[33m       cd %REPO_DIR%%ESC%[0m
    echo   %ESC%[33m       git status%ESC%[0m
    echo.
    git stash pop 2>nul
    pause
    popd
    exit /b 1
)

git stash pop 2>nul

echo   %ESC%[1;32m  ✔   Слияние завершено успешно!%ESC%[0m

REM ============================================================================
REM   Push в форк
REM ============================================================================
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mОтправка изменений в ваш форк...%ESC%[0m
git push origin main
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  ✔   Изменения отправлены в MRafStudio/ACE-Step-1.5%ESC%[0m
) else (
    echo   %ESC%[1;33m  ⚠   Не удалось отправить изменения.%ESC%[0m
)

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mОбновление завершено!%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

pause
popd
exit /b 0