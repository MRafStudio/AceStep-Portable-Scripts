REM scripts\ChoiceModels.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 — Выбор модели
pushd %~dp0..

REM ============================================================================
REM   Получение ESC
REM ============================================================================
for /f %%a in ('powershell -NoProfile -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Пути
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "REPO_DIR=%ROOT_DIR%\repo"
set "CHECKPOINTS_DIR=%REPO_DIR%\checkpoints"

REM ============================================================================
REM   Изоляция
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul

REM ============================================================================
REM   Чтение текущей модели из Config.ini
REM ============================================================================
set "CURRENT_MODEL=turbo"
set "LM_MODEL=acestep-5Hz-lm-1.7B"
if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CURRENT_MODEL=" "%CONFIG_FILE%"') do set "CURRENT_MODEL=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LM_MODEL=" "%CONFIG_FILE%"') do set "LM_MODEL=%%b"
)
set "CURRENT_MODEL=%CURRENT_MODEL: =%"
set "LM_MODEL=%LM_MODEL: =%"

REM Валидация и маппинг через MapModel.bat
call "%SCRIPTS_DIR%\MapModel.bat" "%CURRENT_MODEL%"
if "%REAL_MODEL%"=="acestep-v15-turbo" if not "%CURRENT_MODEL%"=="turbo" (
    set "CURRENT_MODEL=turbo"
    call "%SCRIPTS_DIR%\MapModel.bat" "turbo"
)

:menu
cls
echo.
echo  %ESC%[1;36m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;36m║%ESC%[0m                       %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mВыбор модели%ESC%[0m                         %ESC%[1;36m║%ESC%[0m
echo  %ESC%[1;36m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.
echo   %ESC%[1;33mТекущая модель:%ESC%[0m %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m %ESC%[2m^(%REAL_MODEL%, %MODEL_SIZE%, %MODEL_VRAM%, %MODEL_STEPS% шагов^)%ESC%[0m
echo   %ESC%[1;33mLM модель:%ESC%[0m %ESC%[1;33m%LM_MODEL%%ESC%[0m
echo.
echo   %ESC%[1;33mСтатус checkpoints\:%ESC%[0m

REM Проверка DiT модели
set "DIT_FOUND=0"
if exist "%CHECKPOINTS_DIR%\%REAL_MODEL%\model.safetensors" (
    set "DIT_FOUND=1"
    echo     %ESC%[1;32m+  %ESC%[0m DiT модель: %ESC%[1;32m%REAL_MODEL% загружена%ESC%[0m
) else (
    echo     %ESC%[1;33m.  %ESC%[0m DiT модель: %ESC%[1;33m%REAL_MODEL% — будет загружена при запуске%ESC%[0m
)

REM Проверка LM модели
set "LM_FOUND=0"
if exist "%CHECKPOINTS_DIR%\%LM_MODEL%\model.safetensors" (
    set "LM_FOUND=1"
    echo     %ESC%[1;32m+  %ESC%[0m LM модель: %ESC%[1;32m%LM_MODEL% загружена%ESC%[0m
) else (
    echo     %ESC%[1;33m.  %ESC%[0m LM модель: %ESC%[1;33m%LM_MODEL% — будет загружена при запуске%ESC%[0m
)

REM Проверка VAE
set "VAE_FOUND=0"
if exist "%CHECKPOINTS_DIR%\vae\diffusion_pytorch_model.safetensors" (
    set "VAE_FOUND=1"
    echo     %ESC%[1;32m+  %ESC%[0m VAE: %ESC%[1;32mзагружен%ESC%[0m
) else (
    echo     %ESC%[1;33m.  %ESC%[0m VAE: %ESC%[1;33mбудет загружен при запуске%ESC%[0m
)

REM Проверка Embedding
set "EMB_FOUND=0"
if exist "%CHECKPOINTS_DIR%\Qwen3-Embedding-0.6B\model.safetensors" (
    set "EMB_FOUND=1"
    echo     %ESC%[1;32m+  %ESC%[0m Embedding: %ESC%[1;32mзагружен%ESC%[0m
) else (
    echo     %ESC%[1;33m.  %ESC%[0m Embedding: %ESC%[1;33mбудет загружен при запуске%ESC%[0m
)

echo.
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mСменить модель DiT%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mОткрыть папку checkpoints\%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mУдалить все модели%ESC%[0m %ESC%[2m(освободить место)%ESC%[0m
echo.
echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mНазад%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mДействие (0-3): %ESC%[0m"

set "choice=%choice: =%"
if "%choice%"=="" goto menu
if "%choice%"=="0" goto exit
if "%choice%"=="1" goto change_model
if "%choice%"=="2" goto open_folder
if "%choice%"=="3" goto delete_models
goto menu

REM ============================================================================
REM   [1] Сменить модель DiT
REM ============================================================================
:change_model
cls
echo.
echo   %ESC%[1;33mВыбор модели DiT:%ESC%[0m
echo.
echo   %ESC%[1;34m── Стандарт (2B, ~5GB) ─────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mturbo%ESC%[0m  %ESC%[2m~5GB  ^|  VRAM: 6GB+  ^|  Шаги: 8   ^|  Быстрая%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1msft%ESC%[0m    %ESC%[2m~5GB  ^|  VRAM: 6GB+  ^|  Шаги: 50  ^|  Стандарт%ESC%[0m
echo.
echo   %ESC%[1;34m── XL (4B, ~19GB) ───────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mxl-base%ESC%[0m   %ESC%[2m~19GB ^|  VRAM: 12GB+ ^|  Шаги: 50  ^|  Все задачи%ESC%[0m
echo   %ESC%[1;37m[4]%ESC%[0m %ESC%[1mxl-sft%ESC%[0m    %ESC%[2m~19GB ^|  VRAM: 12GB+ ^|  Шаги: 50  ^|  Стандарт%ESC%[0m
echo   %ESC%[1;37m[5]%ESC%[0m %ESC%[1mxl-turbo%ESC%[0m  %ESC%[2m~19GB ^|  VRAM: 12GB+ ^|  Шаги: 8   ^|  Быстрая%ESC%[0m
echo.
set "mchoice="
set /p "mchoice=%ESC%[33mВыберите модель (1-5): %ESC%[0m"

set "mchoice=%mchoice: =%"
if "%mchoice%"=="1" set "NEW_MODEL=turbo"
if "%mchoice%"=="2" set "NEW_MODEL=sft"
if "%mchoice%"=="3" set "NEW_MODEL=xl-base"
if "%mchoice%"=="4" set "NEW_MODEL=xl-sft"
if "%mchoice%"=="5" set "NEW_MODEL=xl-turbo"

if defined NEW_MODEL (
    if exist "%CONFIG_FILE%" (
        powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'CURRENT_MODEL=.*', 'CURRENT_MODEL=%NEW_MODEL%' | Set-Content '%CONFIG_FILE%'"
        set "CURRENT_MODEL=%NEW_MODEL%"
        call "%SCRIPTS_DIR%\MapModel.bat" "%NEW_MODEL%"
        
        echo.
        echo   %ESC%[1;32m  +   Модель изменена на %NEW_MODEL% ^(%REAL_MODEL%^)%ESC%[0m
        echo   %ESC%[2m       Ace-Step загрузит нужную модель при следующем запуске.%ESC%[0m
    ) else (
        echo   %ESC%[1;31m[ОШИБКА] Config.ini не найден.%ESC%[0m
    )
    timeout /t 2 /nobreak >nul
)
goto menu

REM ============================================================================
REM   [2] Открыть папку checkpoints\
REM ============================================================================
:open_folder
if not exist "%CHECKPOINTS_DIR%" mkdir "%CHECKPOINTS_DIR%" 2>nul
start "" "%CHECKPOINTS_DIR%"
goto menu

REM ============================================================================
REM   [3] Удалить все модели
REM ============================================================================
:delete_models
cls
echo.
echo  %ESC%[1;31m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;31m║%ESC%[0m                          %ESC%[1;37m⚠  УДАЛЕНИЕ МОДЕЛЕЙ ⚠%ESC%[0m                           %ESC%[1;31m║%ESC%[0m
echo  %ESC%[1;31m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.
echo   %ESC%[1;31mВсе модели в checkpoints\ будут удалены!%ESC%[0m
echo   %ESC%[2mПри следующем запуске Ace-Step скачает их заново.%ESC%[0m
echo.
echo   %ESC%[1;31mДля подтверждения введите: DELETE%ESC%[0m
set "DEL_CONFIRM="
set /p "DEL_CONFIRM=%ESC%[33mВвод: %ESC%[0m"
if /I "%DEL_CONFIRM%"=="DELETE" (
    if exist "%CHECKPOINTS_DIR%" (
        rmdir /s /q "%CHECKPOINTS_DIR%"
        echo   %ESC%[1;32m  +   Модели удалены.%ESC%[0m
    ) else (
        echo   %ESC%[1;33m  .   Каталог не существует.%ESC%[0m
    )
) else (
    echo   %ESC%[1;33mОтменено.%ESC%[0m
)
pause
goto menu

:exit
popd
exit /b 0