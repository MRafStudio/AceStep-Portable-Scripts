REM scripts\InstallOrUpdate-Deps-AMD.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title AceStep-1.5 — AMD ROCm
pushd %~dp0..

REM ============================================================================
REM   Получение ESC через PowerShell
REM ============================================================================
for /f %%a in ('powershell -NoProfile -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

goto :skip_smart_pause

:smart_pause
if not "%AUTOCLOSE%"=="1" (
    pause
    goto :eof
)

echo.
echo   %ESC%[1;33m  →  Авто-продолжение через 5 сек...%ESC%[0m
echo   %ESC%[2m       ^(нажмите любую клавишу для остановки^)%ESC%[0m

REM timeout /t 5 /nobreak — ждёт 5 сек, но ЛЮБАЯ клавиша прерывает
timeout /t 5 /nobreak >nul

REM timeout возвращает errorlevel 1 если прерван клавишей, 0 если таймаут
if errorlevel 1 (
    echo.
    echo   %ESC%[1;33m  Остановлено. Нажмите Enter для продолжения...%ESC%[0m
    pause >nul
)

goto :eof

:skip_smart_pause

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "REPO_DIR=%ROOT_DIR%\repo"
set "PYTHON_DIR=%ROOT_DIR%\python-3.12.10"
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
echo  %ESC%[1;36m║%ESC%[0m                           %ESC%[1;37mAceStep-1.5%ESC%[0m  —  %ESC%[1;33mAMD ROCm%ESC%[0m                           %ESC%[1;36m║%ESC%[0m
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
echo   %ESC%[1;33m[1/5]%ESC%[0m %ESC%[1mСоздание venv...%ESC%[0m
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
echo   %ESC%[1;33m[2/5]%ESC%[0m %ESC%[1mОбновление pip...%ESC%[0m
"%VENV_PYTHON%" -m pip install --upgrade pip
echo   %ESC%[1;32m  +   pip готов.%ESC%[0m

REM ============================================================================
REM   ROCm SDK
REM ============================================================================
echo.
echo   %ESC%[1;33m[3/5]%ESC%[0m %ESC%[1mУстановка ROCm SDK 7.2.1...%ESC%[0m

REM Проверка: уже установлена нужная версия?
"%VENV_PIP%" show rocm-sdk-core 2>nul | findstr "Version: 7.2.1" >nul
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   ROCm SDK 7.2.1 уже установлен.%ESC%[0m
    goto rocm_done
)

echo   %ESC%[2m       Это может занять 5-10 минут...%ESC%[0m

"%VENV_PIP%" install --no-cache-dir ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2.1/rocm_sdk_core-7.2.1-py3-none-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2.1/rocm_sdk_devel-7.2.1-py3-none-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2.1/rocm_sdk_libraries_custom-7.2.1-py3-none-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2.1/rocm-7.2.1.tar.gz

if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] ROCm SDK не установился.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)
echo   %ESC%[1;32m  +   ROCm SDK 7.2.1 установлен.%ESC%[0m

:rocm_done

REM ============================================================================
REM   PyTorch ROCm
REM ============================================================================
echo.
echo   %ESC%[1;33m[4/5]%ESC%[0m %ESC%[1mУстановка PyTorch ROCm...%ESC%[0m

REM Проверка: уже установлена ROCm-версия PyTorch?
"%VENV_PIP%" show torch 2>nul | findstr /I "rocm" >nul
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   PyTorch ROCm уже установлен.%ESC%[0m
    goto pytorch_done
)

echo   %ESC%[2m       Загрузка ~2-3 GB, может занять 10-30 минут...%ESC%[0m
echo   %ESC%[2m       Не закрывайте окно! При прерывании повторный запуск докачает из кэша.%ESC%[0m
echo.

"%VENV_PIP%" install --no-cache-dir ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2.1/torch-2.9.1%%2Brocm7.2.1-cp312-cp312-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2.1/torchaudio-2.9.1%%2Brocm7.2.1-cp312-cp312-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2.1/torchvision-0.24.1%%2Brocm7.2.1-cp312-cp312-win_amd64.whl

if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] PyTorch ROCm не установился.%ESC%[0m
    ...
)
echo   %ESC%[1;32m  +   PyTorch ROCm установлен.%ESC%[0m

:pytorch_done

REM ============================================================================
REM   Зависимости ACE-Step (без flash_attn и torch — уже установлены)
REM ============================================================================
echo.
echo   %ESC%[1;33m[5/5]%ESC%[0m %ESC%[1mУстановка зависимостей ACE-Step...%ESC%[0m
echo   %ESC%[2m       Это может занять 5-15 минут...%ESC%[0m

REM Фильтруем из requirements.txt:
REM   - flash-attn (NVIDIA-only)
REM   - torch, torchvision, torchaudio (уже ROCm в [4/5])
findstr /V /I "flash-attn" "%REPO_DIR%\requirements.txt" | findstr /V /I /R "^torch[audio]*== ^torchvision==" > "%TEMP%\requirements_amd.txt"

"%VENV_PIP%" install -r "%TEMP%\requirements_amd.txt"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Зависимости не установились.%ESC%[0m
    del "%TEMP%\requirements_amd.txt" 2>nul
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)
echo   %ESC%[1;32m  +   Зависимости ACE-Step установлены.%ESC%[0m
del "%TEMP%\requirements_amd.txt" 2>nul

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
echo   %ESC%[1;32mГотово: %ESC%[0m  %ESC%[2mPyTorch ROCm установлен.%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m

call :smart_pause
popd
exit /b 0