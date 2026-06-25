REM scripts\InstallOrUpdate-Deps-AMD.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title AceStep-1.5 — AMD ROCm
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "REPO_DIR=%ROOT_DIR%\repo"
set "PYTHON_DIR=%ROOT_DIR%\python-3.11.9"
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"

REM ============================================================================
REM   Изоляция
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
if not exist "%HOME%" mkdir "%HOME%" 2>nul

cls
echo.
echo  %ESC%[1;36m╔══════════════════════════════════════════════════════════════════════════════╗%ESC%[0m
echo  %ESC%[1;36m║%ESC%[0m                         %ESC%[1;37mAceStep-1.5%ESC%[0m  —  %ESC%[1;33mAMD ROCm%ESC%[0m                           %ESC%[1;36m║%ESC%[0m
echo  %ESC%[1;36m╚══════════════════════════════════════════════════════════════════════════════╝%ESC%[0m
echo.

if not exist "%PYTHON_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Python не найден!%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

if not exist "%REPO_DIR%\requirements.txt" (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не найден!%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

REM ============================================================================
REM   venv
REM ============================================================================
echo   %ESC%[1;33m[1/4]%ESC%[0m %ESC%[1mСоздание venv...%ESC%[0m
cd /d "%REPO_DIR%"
if not exist ".venv" (
    "%PYTHON_EXE%" -m venv .venv
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось создать venv.%ESC%[0m
        if "%AUTOCLOSE%"=="0" pause
        popd
        exit /b 1
    )
    echo   %ESC%[1;32m  +   venv создан.%ESC%[0m
) else (
    echo   %ESC%[1;32m  +   venv уже есть.%ESC%[0m
)

set "VENV_PYTHON=%REPO_DIR%\.venv\Scripts\python.exe"
set "VENV_PIP=%REPO_DIR%\.venv\Scripts\pip.exe"

REM ============================================================================
REM   pip
REM ============================================================================
echo.
echo   %ESC%[1;33m[2/4]%ESC%[0m %ESC%[1mОбновление pip...%ESC%[0m
"%VENV_PYTHON%" -m pip install --upgrade pip --quiet
echo   %ESC%[1;32m  +   pip готов.%ESC%[0m

REM ============================================================================
REM   PyTorch ROCm
REM ============================================================================
echo.
echo   %ESC%[1;33m[3/4]%ESC%[0m %ESC%[1mУстановка PyTorch ROCm...%ESC%[0m
echo   %ESC%[2m       Источник: https://download.pytorch.org/whl/rocm6.2%ESC%[0m

REM Проверка: уже установлена ROCm версия?
"%VENV_PYTHON%" -c "import torch; import sys; v=torch.__version__; h=torch.version.hip if hasattr(torch.version, 'hip') else None; sys.exit(0 if (h and '2.' in v) else 1)" >nul 2>nul
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   PyTorch ROCm уже установлен.%ESC%[0m
    goto pytorch_done
)

echo   %ESC%[2m       Загрузка ~2-3 GB, может занять 10-30 минут...%ESC%[0m
echo   %ESC%[2m       Не закрывайте окно! При прерывании повторный запуск докачает из кэша.%ESC%[0m
echo.

REM Установка БЕЗ --quiet — видим прогресс
"%VENV_PIP%" install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2

if !errorlevel! neq 0 (
    echo.
    echo   %ESC%[1;31m[ОШИБКА] PyTorch ROCm не установился.%ESC%[0m
    echo   %ESC%[33m       Возможные причины:%ESC%[0m
    echo   %ESC%[33m       1. Прервалась загрузка — запустите повторно, докачает из кэша%ESC%[0m
    echo   %ESC%[33m       2. Нет интернета%ESC%[0m
    echo   %ESC%[33m       3. ROCm не поддерживает вашу карту%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)
echo   %ESC%[1;32m  +   PyTorch ROCm установлен.%ESC%[0m

:pytorch_done

REM ============================================================================
REM   Зависимости ACE-Step
REM ============================================================================
echo.
echo   %ESC%[1;33m[4/4]%ESC%[0m %ESC%[1mУстановка зависимостей ACE-Step...%ESC%[0m
echo   %ESC%[2m       Это может занять 5-15 минут...%ESC%[0m

set "PIP_TIMEOUT=120"
set "PIP_RETRIES=10"

"%VENV_PIP%" install -r "%REPO_DIR%\requirements.txt" --timeout %PIP_TIMEOUT% --retries %PIP_RETRIES%
set "DEPS_OK=!errorlevel!"

if !DEPS_OK! neq 0 (
    echo.
    echo   %ESC%[1;33m→ Пробуем без flash_attn...%ESC%[0m
    
    findstr /V /I "flash-attn" "%REPO_DIR%\requirements.txt" > "%TEMP%\requirements_no_flash.txt" 2>nul
    "%VENV_PIP%" install -r "%TEMP%\requirements_no_flash.txt" --timeout %PIP_TIMEOUT% --retries %PIP_RETRIES%
    
    if !errorlevel! equ 0 (
        echo   %ESC%[1;32m  +   Основные зависимости установлены.%ESC%[0m
        echo   %ESC%[1;33m  ⚠   flash_attn пропущен. Установите вручную:%ESC%[0m
        echo   %ESC%[33m       https://github.com/Dao-AILab/flash-attention/releases%ESC%[0m
    ) else (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось установить зависимости.%ESC%[0m
        echo   %ESC%[33m       Проверьте интернет и повторите.%ESC%[0m
    )
    
    del "%TEMP%\requirements_no_flash.txt" 2>nul
) else (
    echo   %ESC%[1;32m  +   Зависимости установлены.%ESC%[0m
)

REM ============================================================================
REM   Проверка
REM ============================================================================
echo.
echo   %ESC%[1;33mПроверка...%ESC%[0m
"%VENV_PYTHON%" -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'ROCm: {torch.version.hip}'); print(f'GPU: {torch.cuda.is_available()}')" 2>nul
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   PyTorch ROCm работает!%ESC%[0m
) else (
    echo   %ESC%[1;33m  ⚠   Не удалось проверить PyTorch ROCm.%ESC%[0m
)

echo.
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;32mГотово! %ESC%[0m  %ESC%[2mPyTorch ROCm установлен.%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo.

if "%AUTOCLOSE%"=="0" pause
popd
exit /b 0