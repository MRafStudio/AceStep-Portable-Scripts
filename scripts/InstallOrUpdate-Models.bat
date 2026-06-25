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
echo  %ESC%[1;36m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;36m║%ESC%[0m               %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mУстановка / Обновление моделей%ESC%[0m               %ESC%[1;36m║%ESC%[0m
echo  %ESC%[1;36m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.
echo   %ESC%[1;33mДоступные модели:%ESC%[0m
echo.
echo   %ESC%[1;34m── Стандарт (2B, ~5GB) ─────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mbase%ESC%[0m   %ESC%[2m~5GB  VRAM: 6GB+  Шаги: 50  Все задачи%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1msft%ESC%[0m    %ESC%[2m~5GB  VRAM: 6GB+  Шаги: 50  Стандарт%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mturbo%ESC%[0m  %ESC%[2m~5GB  VRAM: 6GB+  Шаги: 8   Быстрая%ESC%[0m
echo.
echo   %ESC%[1;34m── XL (4B, ~19GB) ───────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[4]%ESC%[0m %ESC%[1mxl-base%ESC%[0m   %ESC%[2m~19GB  VRAM: 12GB+  Шаги: 50  Все задачи%ESC%[0m
echo   %ESC%[1;37m[5]%ESC%[0m %ESC%[1mxl-sft%ESC%[0m    %ESC%[2m~19GB  VRAM: 12GB+  Шаги: 50  Стандарт%ESC%[0m
echo   %ESC%[1;37m[6]%ESC%[0m %ESC%[1mxl-turbo%ESC%[0m  %ESC%[2m~19GB  VRAM: 12GB+  Шаги: 8   Быстрая%ESC%[0m
echo.

REM ============================================================================
REM   Автоопределение GPU + VRAM через PowerShell
REM ============================================================================
set "GPU_NAME=Не определена"
set "GPU_VRAM=0"

nvidia-smi -L >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('nvidia-smi -L 2^>nul') do (
        set "RAW=%%a"
        set "RAW=!RAW:GPU 0: =!"
        for /f "delims=(" %%b in ("!RAW!") do set "GPU_NAME=%%b"
        set "GPU_NAME=!GPU_NAME:~0,-1!"
    )
    REM Получаем VRAM через PowerShell (обход noheader)
    for /f "usebackq" %%a in (`powershell -NoProfile -Command "try { $v = (nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>$null).Trim().Split(' ')[0]; if ($v -match '^\d+$') { [int]$v } else { 0 } } catch { 0 }"`) do (
        set "GPU_VRAM=%%a"
    )
) else (
    for /f "tokens=*" %%a in ('wmic path win32_VideoController get Name /value 2^>nul ^| findstr /I "Name="') do (
        set "GPU_RAW=%%a"
        set "GPU_NAME=!GPU_RAW:~5!"
    )
    REM Для AMD/Intel через wmic AdapterRAM (байты → MiB)
    for /f "tokens=2 delims==" %%a in ('wmic path win32_VideoController get AdapterRAM /value 2^>nul ^| findstr "AdapterRAM"') do (
        set "GPU_VRAM_RAW=%%a"
        for /f "usebackq" %%b in (`powershell -NoProfile -Command "[math]::Round(!GPU_VRAM_RAW! / 1048576)"`) do (
            set "GPU_VRAM=%%b"
        )
    )
)

echo   %ESC%[1;33mGPU:%ESC%[0m %ESC%[1;32m!GPU_NAME!%ESC%[0m
if !GPU_VRAM! gtr 0 (
    echo   %ESC%[2m       VRAM: !GPU_VRAM! MiB%ESC%[0m
)

echo.
echo   %ESC%[1;33mРекомендация:%ESC%[0m

if !GPU_VRAM! geq 24000 (
    echo   %ESC%[1;32m  XL модели — максимальное качество!%ESC%[0m
    echo   %ESC%[2m       xl-base или xl-sft для лучшего результата%ESC%[0m
) else if !GPU_VRAM! geq 12000 (
    echo   %ESC%[1;32m  XL turbo — оптимальный баланс скорости и качества%ESC%[0m
) else if !GPU_VRAM! geq 6000 (
    echo   %ESC%[1;32m  Стандартные модели ^(2B^) — стабильно и быстро%ESC%[0m
    echo   %ESC%[2m       turbo для максимальной скорости%ESC%[0m
) else if !GPU_VRAM! gtr 0 (
    echo   %ESC%[1;33m  Мало VRAM. Попробуйте turbo ^(2B^) или CPU.%ESC%[0m
) else (
    echo   %ESC%[1;33m  Невозможно определить VRAM. Начните с turbo ^(2B^).%ESC%[0m
)

echo.
echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mНазад%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите модель (1-6, 0 для выхода): %ESC%[0m"

set "choice=%choice: =%"
if "%choice%"=="" goto menu
if "%choice%"=="0" goto exit
if "%choice%"=="1" set "MODEL=base" & goto download
if "%choice%"=="2" set "MODEL=sft" & goto download
if "%choice%"=="3" set "MODEL=turbo" & goto download
if "%choice%"=="4" set "MODEL=xl-base" & goto download
if "%choice%"=="5" set "MODEL=xl-sft" & goto download
if "%choice%"=="6" set "MODEL=xl-turbo" & goto download
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
set "HF_REPO=ACE-Step/acestep-v15-%MODEL%"

echo   %ESC%[2m       Репозиторий: %HF_REPO%%ESC%[0m
echo   %ESC%[2m       Модель: %MODEL%%ESC%[0m
echo   %ESC%[2m       Путь: %MODEL_PATH%%ESC%[0m
echo.

hf download %HF_REPO% --local-dir "%MODEL_PATH%"

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
echo   %ESC%[1;32m  +   Модель %MODEL% успешно скачана!%ESC%[0m

REM ============================================================================
REM   Обновление Config.ini
REM ============================================================================
if exist "%CONFIG_FILE%" (
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'CURRENT_MODEL=.*', 'CURRENT_MODEL=%MODEL%' | Set-Content '%CONFIG_FILE%'"
    echo   %ESC%[1;32m  +   Config.ini обновлён: CURRENT_MODEL=%MODEL%%ESC%[0m
)

echo.
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;32mМодель %MODEL% готова к использованию!%ESC%[0m
echo   %ESC%[2m       Путь: %MODEL_PATH%%ESC%[0m
echo   %ESC%[2m       Запуск: Start.bat → Запуск AceStep-1.5%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo.

if "%AUTOCLOSE%"=="0" pause
goto menu

:exit
popd
exit /b 0