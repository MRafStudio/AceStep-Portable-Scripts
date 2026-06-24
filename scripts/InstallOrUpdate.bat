@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 Portable — Установка / Обновление
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

set "ROOT_DIR=%~dp0.."
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "PYTHON_DIR=%ROOT_DIR%\python-3.11.9"
set "REPO_DIR=%ROOT_DIR%\repo"
set "MODELS_DIR=%ROOT_DIR%\models"

REM ============================================================================
REM   Изоляция данных
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
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

echo   %ESC%[2m       Изоляция: %DATA_DIR%%ESC%[0m

:menu
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m              %ESC%[1;37mAceStep-1.5 Portable%ESC%[0m   —   %ESC%[1;33mУстановка / Обновление%ESC%[0m             %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка статуса компонентов
REM ============================================================================

REM Python
if exist "%PYTHON_DIR%\python.exe" (
    set "PYTHON_STATUS=Обновить"
    set "PYTHON_COLOR=%ESC%[1;32m"
    set "PYTHON_INSTALLED=1"
) else (
    set "PYTHON_STATUS=Установить"
    set "PYTHON_COLOR=%ESC%[1;33m"
    set "PYTHON_INSTALLED=0"
)

REM Git
where git >nul 2>nul
if !errorlevel! equ 0 (
    set "GIT_STATUS=Обновить"
    set "GIT_COLOR=%ESC%[1;32m"
    set "GIT_INSTALLED=1"
) else (
    set "GIT_STATUS=Установить"
    set "GIT_COLOR=%ESC%[1;33m"
    set "GIT_INSTALLED=0"
)

REM Репозиторий
if exist "%REPO_DIR%\.git" (
    set "REPO_STATUS=Обновить"
    set "REPO_COLOR=%ESC%[1;32m"
    set "REPO_INSTALLED=1"
) else (
    set "REPO_STATUS=Клонировать"
    set "REPO_COLOR=%ESC%[1;33m"
    set "REPO_INSTALLED=0"
)

REM Зависимости
if exist "%REPO_DIR%\.venv\Lib\site-packages\torch" (
    set "DEPS_STATUS=Обновить"
    set "DEPS_COLOR=%ESC%[1;32m"
    set "DEPS_INSTALLED=1"
) else (
    set "DEPS_STATUS=Установить"
    set "DEPS_COLOR=%ESC%[1;33m"
    set "DEPS_INSTALLED=0"
)

REM Модели
set "MODEL_STATUS=Скачать"
set "MODEL_COLOR=%ESC%[1;33m"
set "MODEL_INSTALLED=0"
if exist "%MODELS_DIR%" (
    dir /b "%MODELS_DIR%\*" >nul 2>nul
    if !errorlevel! equ 0 (
        set "MODEL_STATUS=Добавить"
        set "MODEL_COLOR=%ESC%[1;32m"
        set "MODEL_INSTALLED=1"
    )
)

set /a "INSTALLED_COUNT=!PYTHON_INSTALLED!+!GIT_INSTALLED!+!REPO_INSTALLED!+!DEPS_INSTALLED!"

REM ============================================================================
REM   Вывод меню
REM ============================================================================

if !INSTALLED_COUNT!==0 (
    echo   %ESC%[1;33mНичего не установлено. Выберите действие:%ESC%[0m
    echo.
    echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1;33mУстановить все компоненты%ESC%[0m
    echo.
    echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mНазад в главное меню%ESC%[0m
    echo.
    set "choice="
    set /p "choice=%ESC%[33mВыберите действие ^(0-1^): %ESC%[0m"
    
    set "choice=!choice: =!"
    if "!choice!"=="" goto menu
    if "!choice!"=="1" goto first_start
    if "!choice!"=="0" goto exit
    goto menu
) else (
    echo   %ESC%[1;33mУстановленные компоненты:%ESC%[0m
    echo.
    if !PYTHON_INSTALLED!==1 echo     %ESC%[1;32m✔ %ESC%[0m Python
    if !GIT_INSTALLED!==1 echo     %ESC%[1;32m✔ %ESC%[0m Git
    if !REPO_INSTALLED!==1 echo     %ESC%[1;32m✔ %ESC%[0m Репозиторий
    if !DEPS_INSTALLED!==1 echo     %ESC%[1;32m✔ %ESC%[0m PyTorch + зависимости
    if !MODEL_INSTALLED!==1 echo     %ESC%[1;32m✔ %ESC%[0m Модели (частично)
    echo.
    echo   %ESC%[1;33mВыберите действие:%ESC%[0m
    echo.
    echo   %ESC%[1;37m[1]%ESC%[0m !PYTHON_COLOR!!PYTHON_STATUS! Python%ESC%[0m
    echo   %ESC%[1;37m[2]%ESC%[0m !GIT_COLOR!!GIT_STATUS! Git%ESC%[0m
    echo   %ESC%[1;37m[3]%ESC%[0m !REPO_COLOR!!REPO_STATUS! Репозиторий ACE-Step-1.5%ESC%[0m
    echo   %ESC%[1;37m[4]%ESC%[0m !DEPS_COLOR!!DEPS_STATUS! PyTorch + зависимости%ESC%[0m
    echo   %ESC%[1;37m[5]%ESC%[0m !MODEL_COLOR!!MODEL_STATUS! Модели%ESC%[0m
    echo.
    echo   %ESC%[1;37m[8]%ESC%[0m %ESC%[1mОбновить все компоненты%ESC%[0m
    echo.
    echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mНазад в главное меню%ESC%[0m
    echo.
    set "choice="
    set /p "choice=%ESC%[33mВыберите действие (0-8): %ESC%[0m"
    
    set "choice=!choice: =!"
    if "!choice!"=="" goto menu
    if "!choice!"=="1" goto install_python
    if "!choice!"=="2" goto install_git
    if "!choice!"=="3" goto install_repo
    if "!choice!"=="4" goto install_deps
    if "!choice!"=="5" goto install_models
    if "!choice!"=="8" goto install_all
    if "!choice!"=="0" goto exit
    goto menu
)

:first_start
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск установки всех компонентов...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-All.bat" 1
goto menu

:install_all
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск обновления всех компонентов...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-All.bat" 0
goto menu

:install_python
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск !PYTHON_STATUS! Python...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Python.bat" 0
goto menu

:install_git
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск !GIT_STATUS! Git...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Git.bat" 0
goto menu

:install_repo
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск !REPO_STATUS! Репозитория...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Repo.bat" 0
goto menu

:install_deps
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск !DEPS_STATUS! PyTorch + зависимостей...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Dependencies.bat" 0
goto menu

:install_models
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mЗапуск !MODEL_STATUS! Моделей...%ESC%[0m
echo.
call "%SCRIPTS_DIR%\InstallOrUpdate-Models.bat" 0
goto menu

:exit
popd
exit /b 0