REM scripts\InstallOrUpdate-Models.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title AceStep-1.5 — Установка / Обновление моделей
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение ROOT_DIR (корень проекта = уровень выше scripts\)
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "MODELS_DIR=%ROOT_DIR%\models"
set "PYTHON_DIR=%ROOT_DIR%\python-3.11.9"
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"

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
REM   Проверка Python и hf.exe
REM ============================================================================
if not exist "%PYTHON_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Python не найден!%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

set "PATH=%PYTHON_DIR%;%PYTHON_DIR%\Scripts;%PATH%"

where hf >nul 2>nul
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] hf.exe не найден!%ESC%[0m
    echo   %ESC%[33m       Запустите установку Python сначала.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

:menu
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m          %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mУстановка / Обновление моделей%ESC%[0m             %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.
echo   %ESC%[1;33mДоступные модели:%ESC%[0m
echo.
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mbase%ESC%[0m        %ESC%[2m~8GB  |  VRAM: 8GB+  |  Быстро  |  Хорошее качество%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mxl-base%ESC%[0m     %ESC%[2m~20GB |  VRAM: 20GB+ |  Средне  |  Отличное качество%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mxl-sft%ESC%[0m      %ESC%[2m~20GB |  VRAM: 20GB+ |  Средне  |  Fine-tuned%ESC%[0m
echo   %ESC%[1;37m[4]%ESC%[0m %ESC%[1mxl-turbo%ESC%[0m    %ESC%[2m~20GB |  VRAM: 20GB+ |  Очень быстро |  Оптимизированная%ESC%[0m
echo.
echo   %ESC%[1;33mТвоя видеокарта:%ESC%[0m %ESC%[1;32mRTX 5090 32GB%ESC%[0m %ESC%[33m— все модели доступны!%ESC%[0m
echo.
echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mНазад%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите модель (1-4, 0 для выхода): %ESC%[0m"

set "choice=%choice: =%"
if "%choice%"=="" goto menu
if "%choice%"=="0" goto exit
if "%choice%"=="1" set "MODEL=base" & goto download
if "%choice%"=="2" set "MODEL=xl-base" & goto download
if "%choice%"=="3" set "MODEL=xl-sft" & goto download
if "%choice%"=="4" set "MODEL=xl-turbo" & goto download
goto menu

:download
cls
echo.
echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mСкачивание модели %MODEL%...%ESC%[0m
echo   %ESC%[2m       Это может занять 10-30 минут в зависимости от скорости интернета%ESC%[0m
echo.

set "MODEL_PATH=%MODELS_DIR%\%MODEL%"
if not exist "%MODEL_PATH%" mkdir "%MODEL_PATH%" 2>nul

REM ============================================================================
REM   Скачивание через huggingface-cli
REM ============================================================================
set "HF_REPO=ace-step/ACE-Step-1.5"

echo   %ESC%[2m       Репозиторий: %HF_REPO%%ESC%[0m
echo   %ESC%[2m       Модель: %MODEL%%ESC%[0m
echo   %ESC%[2m       Путь: %MODEL_PATH%%ESC%[0m
echo.

huggingface-cli download %HF_REPO% --include "%MODEL%/*" --local-dir "%MODEL_PATH%" --local-dir-use-symlinks False

if !errorlevel! neq 0 (
    echo.
    echo   %ESC%[1;31m[ОШИБКА] Не удалось скачать модель.%ESC%[0m
    echo   %ESC%[33m       Попробуйте скачать вручную:%ESC%[0m
    echo   %ESC%[33m       https://huggingface.co/%HF_REPO%%ESC%[0m
    echo.
    pause
    goto menu
)

echo.
echo   %ESC%[1;32m  ✔   Модель %MODEL% успешно скачана!%ESC%[0m

REM ============================================================================
REM   Обновление Config.ini
REM ============================================================================
if exist "%CONFIG_FILE%" (
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'CURRENT_MODEL=.*', 'CURRENT_MODEL=%MODEL%' | Set-Content '%CONFIG_FILE%'"
    echo   %ESC%[1;32m  ✔   Config.ini обновлён: CURRENT_MODEL=%MODEL%%ESC%[0m
)

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mМодель %MODEL% готова к использованию!%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

if "%AUTOCLOSE%"=="0" pause
goto menu

:exit
popd
exit /b 0