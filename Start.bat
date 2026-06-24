@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 Portable — Главное меню
pushd %~dp0

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Пути (относительно Start.bat)
REM ============================================================================
set "ROOT_DIR=%~dp0"
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "REPO_DIR=%ROOT_DIR%\repo"
set "PYTHON_DIR=%ROOT_DIR%\python-3.11.9"
set "MODELS_DIR=%ROOT_DIR%\models"
set "DATA_DIR=%ROOT_DIR%\data"

REM ============================================================================
REM   Изоляция данных (ничего в систему!)
REM ============================================================================
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
REM   Авто-создание Config.ini если нет
REM ============================================================================
if not exist "%CONFIG_FILE%" (
    echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mСоздание Config.ini...%ESC%[0m
    (
        echo ; ============================================================
        echo ;   AceStep-1.5 Portable — Конфигурация
        echo ; ============================================================
        echo.
        echo ; --- Python ---
        echo PYTHON_VERSION=3.11.9
        echo.
        echo ; --- Модель ---
        echo ; Доступные: base, xl-base, xl-sft, xl-turbo
        echo CURRENT_MODEL=xl-base
        echo.
        echo ; --- Запуск ---
        echo AUTO_OPEN_BROWSER=1
        echo LAUNCH_METHOD=gradio
        echo.
        echo ; --- CUDA ---
        echo ; Для RTX 5090 ^(Blackwell^) — CUDA 12.8
        echo CUDA_VERSION=12.8
    ) > "%CONFIG_FILE%"
    echo   %ESC%[1;32m  ✔   Config.ini создан.%ESC%[0m
    echo.
)

REM ============================================================================
REM   Чтение Config.ini
REM ============================================================================
set "CURRENT_MODEL=xl-base"
set "AUTO_OPEN_BROWSER=1"
set "LAUNCH_METHOD=gradio"

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CURRENT_MODEL=" "%CONFIG_FILE%"') do set "CURRENT_MODEL=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LAUNCH_METHOD=" "%CONFIG_FILE%"') do set "LAUNCH_METHOD=%%b"
)

set "CURRENT_MODEL=%CURRENT_MODEL: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"
set "LAUNCH_METHOD=%LAUNCH_METHOD: =%"

:menu
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                   %ESC%[1;37mAceStep-1.5 Portable%ESC%[0m   —   %ESC%[1;33mГлавное меню%ESC%[0m                  %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка статуса компонентов
REM ============================================================================
echo   %ESC%[1;33mСтатус компонентов:%ESC%[0m

REM Python
set "PYTHON_INSTALLED=0"
if exist "%PYTHON_DIR%\python.exe" (
    for /f "tokens=1,2" %%a in ('"%PYTHON_DIR%\python.exe" --version 2^>nul') do set "PYTHON_VER=%%b"
    echo     %ESC%[1;32m✔  %ESC%[0m Python !PYTHON_VER!
    set "PYTHON_INSTALLED=1"
) else (
    echo     %ESC%[1;31m✗  %ESC%[0m Python — не установлен
)

REM Git
set "GIT_INSTALLED=0"
where git >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('git --version 2^>nul') do set "GIT_VER=%%a"
    echo     %ESC%[1;32m✔  %ESC%[0m Git
    set "GIT_INSTALLED=1"
) else (
    echo     %ESC%[1;31m✗  %ESC%[0m Git — не установлен
)

REM Репозиторий
set "REPO_INSTALLED=0"
set "REPO_BRANCH="
if exist "%REPO_DIR%\.git" (
    cd /d "%REPO_DIR%" 2>nul
    for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "REPO_BRANCH=%%a"
    cd /d "%ROOT_DIR%" 2>nul
    if "!REPO_BRANCH!"=="ru-localization" (
        echo     %ESC%[1;32m✔  %ESC%[0m Репозиторий ACE-Step-1.5 %ESC%[2m^(ru-localization^)%ESC%[0m
    ) else (
        echo     %ESC%[1;33m⚠  %ESC%[0m Репозиторий ACE-Step-1.5 %ESC%[2m^(!REPO_BRANCH!, ожидается ru-localization^)%ESC%[0m
    )
    set "REPO_INSTALLED=1"
) else (
    echo     %ESC%[1;31m✗  %ESC%[0m Репозиторий — не клонирован
)

REM Зависимости Python
set "DEPS_INSTALLED=0"
if exist "%REPO_DIR%\.venv\Lib\site-packages\torch" (
    echo     %ESC%[1;32m✔  %ESC%[0m PyTorch + зависимости
    set "DEPS_INSTALLED=1"
) else (
    echo     %ESC%[1;31m✗  %ESC%[0m PyTorch + зависимости — не установлены
)

REM Модель
set "MODEL_INSTALLED=0"
if exist "%MODELS_DIR%\%CURRENT_MODEL%" (
    dir /b "%MODELS_DIR%\%CURRENT_MODEL%\*.safetensors" >nul 2>nul
    if !errorlevel! equ 0 (
        echo     %ESC%[1;32m✔  %ESC%[0m Модель: %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m
        set "MODEL_INSTALLED=1"
    ) else (
        echo     %ESC%[1;31m✗  %ESC%[0m Модель: %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m %ESC%[2m— не скачана%ESC%[0m
    )
) else (
    echo     %ESC%[1;31m✗  %ESC%[0m Модель: %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m %ESC%[2m— не скачана%ESC%[0m
)

REM Подсчёт
set /a "INSTALLED_COUNT=!PYTHON_INSTALLED!+!GIT_INSTALLED!+!REPO_INSTALLED!+!DEPS_INSTALLED!+!MODEL_INSTALLED!"

echo.
echo   %ESC%[1;33mТекущие настройки:%ESC%[0m
echo     Модель: %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m
echo     Запуск: %ESC%[1;33m%LAUNCH_METHOD%%ESC%[0m
echo     Авто-браузер: %ESC%[1;33m%AUTO_OPEN_BROWSER%%ESC%[0m
echo.

echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mУстановка / Обновление компонентов%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mНастройки%ESC%[0m %ESC%[2m(модель, автозапуск, метод)%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mИнструменты разработчика%ESC%[0m %ESC%[2m(Git, локализация, обновление)%ESC%[0m
echo.

if "!INSTALLED_COUNT!"=="5" (
    echo   %ESC%[1;37m[*]%ESC%[0m %ESC%[1mЗапуск AceStep-1.5%ESC%[0m %ESC%[2m^(%LAUNCH_METHOD%^)%ESC%[0m
    echo     %ESC%[2m       http://127.0.0.1:7860%ESC%[0m
) else (
    echo   %ESC%[1;30m[*]%ESC%[0m %ESC%[1;30mЗапуск AceStep-1.5%ESC%[0m %ESC%[2m^(не все компоненты установлены^)%ESC%[0m
)

echo.
echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mВыход%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите действие (0-3, Enter для запуска): %ESC%[0m"

if not defined choice goto run
set "choice=%choice: =%"
if "%choice%"=="" goto run
if "%choice%"=="*" goto run
if "%choice%"=="1" goto setup
if "%choice%"=="2" goto settings
if "%choice%"=="3" goto dev_tools
if "%choice%"=="0" goto exit
goto menu

:run
if "!INSTALLED_COUNT!"=="5" (
    cls
    echo.
    echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск AceStep-1.5 ^(%LAUNCH_METHOD%^)...%ESC%[0m
    echo.
    if /I "%LAUNCH_METHOD%"=="comfyui" (
        call "%SCRIPTS_DIR%\Start-ComfyUI.bat"
    ) else (
        call "%SCRIPTS_DIR%\Start-Gradio.bat"
    )
    pause
    goto menu
) else (
    cls
    echo.
    echo   %ESC%[1;31m[ОШИБКА] Не все компоненты установлены!%ESC%[0m
    echo   %ESC%[33m       Запустите установку через пункт меню [1]%ESC%[0m
    echo.
    pause
    goto menu
)

:setup
call "%SCRIPTS_DIR%\InstallOrUpdate.bat"
goto menu

:settings
call "%SCRIPTS_DIR%\Settings.bat"
goto menu

:dev_tools
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                %ESC%[1;37mAceStep-1.5 Portable%ESC%[0m   —   %ESC%[1;33mИнструменты разработчика%ESC%[0m       %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM Проверка репозитория
set "REPO_EXISTS=0"
set "REPO_BRANCH="
if exist "%REPO_DIR%\.git" (
    cd /d "%REPO_DIR%" 2>nul
    for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "REPO_BRANCH=%%a"
    cd /d "%ROOT_DIR%" 2>nul
    if "!REPO_BRANCH!"=="ru-localization" (
        echo   %ESC%[1;32m✔  %ESC%[0m Репозиторий: %ESC%[1;33mru-localization%ESC%[0m
    ) else (
        echo   %ESC%[1;33m⚠  %ESC%[0m Репозиторий: %ESC%[1;33m!REPO_BRANCH!%ESC%[0m %ESC%[2m^(ожидается ru-localization^)%ESC%[0m
    )
    set "REPO_EXISTS=1"
) else (
    echo   %ESC%[1;31m✗  %ESC%[0m Репозиторий — не клонирован
)

echo.
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mОбновить репозиторий%ESC%[0m %ESC%[2m(InstallOrUpdate-Repo.bat)%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mОбновить ru-localization из origin/main%ESC%[0m %ESC%[2m(свежие обновления upstream)%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mОтправить локализацию в GitHub%ESC%[0m %ESC%[2m(commit + push ru-localization)%ESC%[0m
echo   %ESC%[1;37m[4]%ESC%[0m %ESC%[1mОбновить скрипты из GitHub%ESC%[0m %ESC%[2m(git pull AceStep-Portable-Scripts)%ESC%[0m
echo.
echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mНазад в главное меню%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите действие (0-4): %ESC%[0m"

set "choice=%choice: =%"
if "%choice%"=="" goto dev_tools
if "%choice%"=="0" goto menu
if "%choice%"=="1" goto update_repo
if "%choice%"=="2" goto update_localization
if "%choice%"=="3" goto push_localization
if "%choice%"=="4" goto update_scripts
goto dev_tools

:update_repo
call "%SCRIPTS_DIR%\InstallOrUpdate-Repo.bat"
goto dev_tools

:update_localization
call "%SCRIPTS_DIR%\Update-From-Upstream.bat"
goto dev_tools

:push_localization
call "%SCRIPTS_DIR%\Push-Localization.bat"
goto dev_tools

:update_scripts
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mОбновление скриптов из GitHub...%ESC%[0m
echo.
cd /d "%ROOT_DIR%"
git pull origin main
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  ✔   Скрипты обновлены!%ESC%[0m
) else (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось обновить скрипты.%ESC%[0m
    echo   %ESC%[33m       Возможно, есть локальные изменения.%ESC%[0m
    echo   %ESC%[33m       Сохраните изменения и повторите.%ESC%[0m
)
echo.
pause
goto dev_tools

:exit
popd
exit /b 0