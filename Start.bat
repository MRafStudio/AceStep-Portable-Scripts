REM Start.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 Portable — Главное меню
pushd %~dp0

REM ============================================================================
REM   Пути (относительно Start.bat)
REM ============================================================================
for %%F in ("%~dp0") do set "ROOT_DIR=%%~fF"
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "REPO_DIR=%ROOT_DIR%\repo"
set "PYTHON_DIR=%ROOT_DIR%\python-3.12.10"
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
set "GIT_FOUND=0"
git --version >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('git --version 2^>nul') do set "GIT_VER=%%a"
    set "GIT_FOUND=1"
)

if !GIT_FOUND! equ 0 (
    cls
    echo.
    echo  %ESC%[1;31m################################################################################%ESC%[0m
    echo  %ESC%[1;31m##                                                                            ##%ESC%[0m
    echo  %ESC%[1;31m##%ESC%[0m                         %ESC%[1;37mGit не найден в системе%ESC%[0m                            %ESC%[1;31m##%ESC%[0m
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
    echo   %ESC%[2mПосле установки перезапустите Start.bat%ESC%[0m
    echo.
    pause
    popd
    exit /b 1
)

REM ============================================================================
REM   Авто-создание Config.ini если нет
REM ============================================================================
if not exist "%CONFIG_FILE%" (
    echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mСоздание Config.ini...%ESC%[0m
    (
        echo ; ============================================================
        echo ;   AceStep-1.5 Portable — Конфигурация
        echo ; ============================================================
        echo.
		echo ; --- Язык интерфейса ---
        echo ; Доступные: en, zh, ja, he, pt, ru
        echo LANGUAGE=ru
		echo.
        echo ; --- Модель ---
        echo ; Доступные: base, sft, turbo, xl-base, xl-sft, xl-turbo
        echo ; Примечание: base устарел, используйте turbo или sft
        echo CURRENT_MODEL=turbo
        echo.
        echo ; --- Запуск ---
        echo AUTO_OPEN_BROWSER=1
        echo LAUNCH_METHOD=gradio
        echo.
        echo ; --- CUDA ---
        echo ; Для RTX 5090 ^(Blackwell^) — CUDA 12.8
        echo CUDA_VERSION=12.8
    ) > "%CONFIG_FILE%"
    echo   %ESC%[1;32m  +   Config.ini создан.%ESC%[0m
    echo.
)

REM ============================================================================
REM   Чтение Config.ini
REM ============================================================================
set "CURRENT_MODEL=turbo"
set "LANGUAGE=ru"
set "AUTO_OPEN_BROWSER=1"
set "LAUNCH_METHOD=gradio"

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CURRENT_MODEL=" "%CONFIG_FILE%"') do set "CURRENT_MODEL=%%b"
	for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LANGUAGE=" "%CONFIG_FILE%"') do set "LANGUAGE=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LAUNCH_METHOD=" "%CONFIG_FILE%"') do set "LAUNCH_METHOD=%%b"
)

set "CURRENT_MODEL=%CURRENT_MODEL: =%"
set "LANGUAGE=%LANGUAGE: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"
set "LAUNCH_METHOD=%LAUNCH_METHOD: =%"

REM ============================================================================
REM   Валидация и авто-фикс модели
REM ============================================================================
set "VALID_MODEL=0"
if /I "%CURRENT_MODEL%"=="base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="turbo" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-turbo" set "VALID_MODEL=1"

if "!VALID_MODEL!"=="0" (
    echo   %ESC%[1;33m⚠  Неверное значение CURRENT_MODEL=%CURRENT_MODEL%, исправляем на turbo%ESC%[0m
    set "CURRENT_MODEL=turbo"
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'CURRENT_MODEL=.*', 'CURRENT_MODEL=turbo' | Set-Content '%CONFIG_FILE%'"
    timeout /t 1 /nobreak >nul
)

REM Авто-замена устаревшего base на turbo
if /I "%CURRENT_MODEL%"=="base" (
    echo   %ESC%[1;33m⚠  Модель 'base' устарела, переключаем на 'turbo'%ESC%[0m
    set "CURRENT_MODEL=turbo"
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'CURRENT_MODEL=.*', 'CURRENT_MODEL=turbo' | Set-Content '%CONFIG_FILE%'"
    timeout /t 1 /nobreak >nul
)

REM ============================================================================
REM   Маппинг: короткое имя → реальное имя папки
REM ============================================================================
if "%CURRENT_MODEL%"=="base"     set "REAL_MODEL=acestep-v15-base"
if "%CURRENT_MODEL%"=="sft"      set "REAL_MODEL=acestep-v15-sft"
if "%CURRENT_MODEL%"=="turbo"    set "REAL_MODEL=acestep-v15-turbo"
if "%CURRENT_MODEL%"=="xl-base"  set "REAL_MODEL=acestep-v15-xl-base"
if "%CURRENT_MODEL%"=="xl-sft"   set "REAL_MODEL=acestep-v15-xl-sft"
if "%CURRENT_MODEL%"=="xl-turbo" set "REAL_MODEL=acestep-v15-xl-turbo"

:menu
REM Перечитываем Config.ini (мог измениться в других скриптах)
if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CURRENT_MODEL=" "%CONFIG_FILE%"') do set "CURRENT_MODEL=%%b"
	for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LANGUAGE=" "%CONFIG_FILE%"') do set "LANGUAGE=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LAUNCH_METHOD=" "%CONFIG_FILE%"') do set "LAUNCH_METHOD=%%b"
)

set "CURRENT_MODEL=%CURRENT_MODEL: =%"
set "LANGUAGE=%LANGUAGE: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"
set "LAUNCH_METHOD=%LAUNCH_METHOD: =%"

REM Повторяем валидацию после перечитывания
set "VALID_MODEL=0"
if /I "%CURRENT_MODEL%"=="base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="turbo" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-turbo" set "VALID_MODEL=1"

if "!VALID_MODEL!"=="0" set "CURRENT_MODEL=turbo"
if /I "%CURRENT_MODEL%"=="base" set "CURRENT_MODEL=turbo"

REM Обновляем маппинг
if "%CURRENT_MODEL%"=="base"     set "REAL_MODEL=acestep-v15-base"
if "%CURRENT_MODEL%"=="sft"      set "REAL_MODEL=acestep-v15-sft"
if "%CURRENT_MODEL%"=="turbo"    set "REAL_MODEL=acestep-v15-turbo"
if "%CURRENT_MODEL%"=="xl-base"  set "REAL_MODEL=acestep-v15-xl-base"
if "%CURRENT_MODEL%"=="xl-sft"   set "REAL_MODEL=acestep-v15-xl-sft"
if "%CURRENT_MODEL%"=="xl-turbo" set "REAL_MODEL=acestep-v15-xl-turbo"

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
    echo     %ESC%[1;32m+  %ESC%[0m Python !PYTHON_VER!
    set "PYTHON_INSTALLED=1"
) else (
    echo     %ESC%[1;31m-  %ESC%[0m Python — не установлен
)

REM Git (глобальный, уже проверен выше)
echo     %ESC%[1;32m+  %ESC%[0m Git %GIT_VER%

REM Репозиторий
set "REPO_INSTALLED=0"
set "REPO_BRANCH="
if exist "%REPO_DIR%\.git" (
    cd /d "%REPO_DIR%" 2>nul
    for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "REPO_BRANCH=%%a"
    cd /d "%ROOT_DIR%" 2>nul
    if "!REPO_BRANCH!"=="ru-localization" (
        echo     %ESC%[1;32m+  %ESC%[0m Репозиторий ACE-Step-1.5 %ESC%[2m^(ru-localization^)%ESC%[0m
    ) else (
        echo     %ESC%[1;33m.  %ESC%[0m Репозиторий ACE-Step-1.5 %ESC%[2m^(!REPO_BRANCH!, ожидается ru-localization^)%ESC%[0m
    )
    set "REPO_INSTALLED=1"
) else (
    echo     %ESC%[1;31m-  %ESC%[0m Репозиторий — не клонирован
)

REM Зависимости Python
set "DEPS_INSTALLED=0"
if exist "%REPO_DIR%\.venv\Lib\site-packages\torch" (
    echo     %ESC%[1;32m+  %ESC%[0m PyTorch + зависимости
    set "DEPS_INSTALLED=1"
) else (
    echo     %ESC%[1;31m-  %ESC%[0m PyTorch + зависимости — не установлены
)

REM Модель — проверяем только статус, не требуем для запуска
set "MODEL_STATUS=%ESC%[1;33m%CURRENT_MODEL%%ESC%[0m"
if exist "%REPO_DIR%\checkpoints" (
    dir /b "%REPO_DIR%\checkpoints\%REAL_MODEL%" >nul 2>nul
    if !errorlevel! equ 0 (
        echo     %ESC%[1;32m+  %ESC%[0m Модель: %MODEL_STATUS% %ESC%[2m^(загружена^)%ESC%[0m
    ) else (
        echo     %ESC%[1;33m.  %ESC%[0m Модель: %MODEL_STATUS% %ESC%[2m^(авто-загрузка при запуске^)%ESC%[0m
    )
) else (
    echo     %ESC%[1;33m.  %ESC%[0m Модель: %MODEL_STATUS% %ESC%[2m^(авто-загрузка при запуске^)%ESC%[0m
)

REM Подсчёт — только 3 компонента (без модели)
set /a "INSTALLED_COUNT=!PYTHON_INSTALLED!+!REPO_INSTALLED!+!DEPS_INSTALLED!"

echo.
echo   %ESC%[1;33mТекущие настройки:%ESC%[0m
echo     Модель: %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m %ESC%[2m^(%REAL_MODEL%^)%ESC%[0m
echo     Язык: %ESC%[1;33m%LANGUAGE%%ESC%[0m
echo     Запуск: %ESC%[1;33m%LAUNCH_METHOD%%ESC%[0m
echo     Авто-браузер: %ESC%[1;33m%AUTO_OPEN_BROWSER%%ESC%[0m
echo.

echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mУстановка / Обновление компонентов%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mНастройки%ESC%[0m %ESC%[2m(модель, автозапуск, метод)%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mИнструменты разработчика%ESC%[0m %ESC%[2m(Git, локализация, обновление)%ESC%[0m
echo.

if "!INSTALLED_COUNT!"=="3" (
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
if "!INSTALLED_COUNT!"=="3" (
    cls
    echo.
    echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mЗапуск AceStep-1.5 ^(%LAUNCH_METHOD%^)...%ESC%[0m
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
    echo   %ESC%[1;31m[ОШИБКА] Не все компоненты установлены.%ESC%[0m
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
call "%SCRIPTS_DIR%\DevTools.bat"
goto menu

:exit
popd
exit /b 0