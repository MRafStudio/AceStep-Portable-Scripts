@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title AceStep-1.5 — Установка PyTorch + зависимостей
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение ROOT_DIR (корень проекта = уровень выше scripts\)
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "REPO_DIR=%ROOT_DIR%\repo"
set "PYTHON_DIR=%ROOT_DIR%\python-3.11.9"
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"

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
if not exist "%HOME%" mkdir "%HOME%" 2>nul

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m          %ESC%[1;37mAceStep-1.5%ESC%[0m   —   %ESC%[1;33mУстановка PyTorch + зависимостей%ESC%[0m           %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка Python
REM ============================================================================
if not exist "%PYTHON_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Python не найден! Установите Python сначала.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

REM ============================================================================
REM   Проверка репозитория
REM ============================================================================
if not exist "%REPO_DIR%\requirements.txt" (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не найден! Клонируйте репозиторий сначала.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

REM ============================================================================
REM   Создание venv
REM ============================================================================
echo   %ESC%[1;33m[1/4]%ESC%[0m %ESC%[1mСоздание виртуального окружения...%ESC%[0m

cd /d "%REPO_DIR%"

if not exist ".venv" (
    "%PYTHON_EXE%" -m venv .venv
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось создать venv.%ESC%[0m
        if "%AUTOCLOSE%"=="0" pause
        popd
        exit /b 1
    )
    echo   %ESC%[1;32m  ✔   Виртуальное окружение создано.%ESC%[0m
) else (
    echo   %ESC%[1;32m  ✔   Виртуальное окружение уже существует.%ESC%[0m
)

set "VENV_PYTHON=%REPO_DIR%\.venv\Scripts\python.exe"
set "VENV_PIP=%REPO_DIR%\.venv\Scripts\pip.exe"

REM ============================================================================
REM   Обновление pip
REM ============================================================================
echo.
echo   %ESC%[1;33m[2/4]%ESC%[0m %ESC%[1mОбновление pip...%ESC%[0m

"%VENV_PYTHON%" -m pip install --upgrade pip --quiet
if !errorlevel! neq 0 (
    echo   %ESC%[1;33m  ⚠   Не удалось обновить pip. Продолжаем...%ESC%[0m
) else (
    echo   %ESC%[1;32m  ✔   pip обновлён.%ESC%[0m
)

REM ============================================================================
REM   Установка PyTorch CUDA 12.8 для RTX 5090 (Blackwell)
REM ============================================================================
echo.
echo   %ESC%[1;33m[3/4]%ESC%[0m %ESC%[1mУстановка PyTorch CUDA 12.8...%ESC%[0m
echo   %ESC%[2m       Для RTX 5090 (Blackwell) требуется CUDA 12.8%ESC%[0m

"%VENV_PIP%" install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 --quiet
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось установить PyTorch CUDA 12.8.%ESC%[0m
    echo   %ESC%[33m       Попытка установить CPU версию...%ESC%[0m
    
    "%VENV_PIP%" install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu --quiet
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] PyTorch не установился.%ESC%[0m
        if "%AUTOCLOSE%"=="0" pause
        popd
        exit /b 1
    )
    echo   %ESC%[1;33m  ⚠   Установлена CPU версия PyTorch.%ESC%[0m
    echo   %ESC%[33m       GPU не будет использоваться!%ESC%[0m
) else (
    echo   %ESC%[1;32m  ✔   PyTorch CUDA 12.8 установлен.%ESC%[0m
)

REM ============================================================================
REM   Установка зависимостей из requirements.txt
REM ============================================================================
echo.
echo   %ESC%[1;33m[4/4]%ESC%[0m %ESC%[1mУстановка зависимостей ACE-Step-1.5...%ESC%[0m

"%VENV_PIP%" install -r "%REPO_DIR%\requirements.txt" --quiet
if !errorlevel! neq 0 (
    echo   %ESC%[1;33m  ⚠   Некоторые зависимости не установились.%ESC%[0m
    echo   %ESC%[33m       Возможно, потребуется ручная установка.%ESC%[0m
) else (
    echo   %ESC%[1;32m  ✔   Зависимости установлены.%ESC%[0m
)

REM ============================================================================
REM   Проверка установки
REM ============================================================================
echo.
echo   %ESC%[1;33mПроверка установки...%ESC%[0m

"%VENV_PYTHON%" -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}'); print(f'GPU: {torch.cuda.is_available()}')" 2>nul
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  ✔   PyTorch работает!%ESC%[0m
) else (
    echo   %ESC%[1;33m  ⚠   Не удалось проверить PyTorch.%ESC%[0m
)

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mУстановка зависимостей завершена!%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

if "%AUTOCLOSE%"=="0" pause
popd
exit /b 0