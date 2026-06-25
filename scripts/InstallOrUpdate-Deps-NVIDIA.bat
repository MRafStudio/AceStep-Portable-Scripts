REM scripts\InstallOrUpdate-Deps-NVIDIA.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title AceStep-1.5 — NVIDIA CUDA
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
echo  %ESC%[1;36m║%ESC%[0m                         %ESC%[1;37mAceStep-1.5%ESC%[0m  —  %ESC%[1;33mNVIDIA CUDA%ESC%[0m                          %ESC%[1;36m║%ESC%[0m
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
REM   Определение поколения NVIDIA
REM ============================================================================
echo   %ESC%[1;33m→ Определение поколения...%ESC%[0m

set "CUDA_URL=https://download.pytorch.org/whl/cu124"
set "CUDA_VER=12.4"

REM Используем nvidia-smi -L (универсально, все версии драйверов)
for /f "tokens=*" %%a in ('nvidia-smi -L 2^>nul') do (
    set "RAW=%%a"
    set "RAW=!RAW:GPU 0: =!"
    for /f "delims=(" %%b in ("!RAW!") do set "GPU_FULLNAME=%%b"
    set "GPU_FULLNAME=!GPU_FULLNAME:~0,-1!"
    goto gpu_name_parsed
)
:gpu_name_parsed

if "!GPU_FULLNAME!"=="" (
    echo   %ESC%[1;31m  -   Не удалось определить GPU%ESC%[0m
    goto manual_select
)

echo   %ESC%[2m       Обнаружено: !GPU_FULLNAME!%ESC%[0m

REM RTX 50xx (Blackwell) — CUDA 12.8
echo !GPU_FULLNAME! | findstr /I /R "RTX 50[0-9][0-9]" >nul 2>nul
if !errorlevel! equ 0 (
    set "CUDA_URL=https://download.pytorch.org/whl/cu128"
    set "CUDA_VER=12.8"
    echo   %ESC%[1;32m  +   Blackwell ^(RTX 50xx^) — CUDA 12.8%ESC%[0m
    goto cuda_selected
)

REM RTX 40xx (Ada) — CUDA 12.4
echo !GPU_FULLNAME! | findstr /I /R "RTX 40[0-9][0-9]" >nul 2>nul
if !errorlevel! equ 0 (
    set "CUDA_URL=https://download.pytorch.org/whl/cu124"
    set "CUDA_VER=12.4"
    echo   %ESC%[1;32m  +   Ada ^(RTX 40xx^) — CUDA 12.4%ESC%[0m
    goto cuda_selected
)

REM RTX 30xx (Ampere) — CUDA 11.8
echo !GPU_FULLNAME! | findstr /I /R "RTX 30[0-9][0-9]" >nul 2>nul
if !errorlevel! equ 0 (
    set "CUDA_URL=https://download.pytorch.org/whl/cu118"
    set "CUDA_VER=11.8"
    echo   %ESC%[1;32m  +   Ampere ^(RTX 30xx^) — CUDA 11.8%ESC%[0m
    goto cuda_selected
)

REM GTX 16xx, 10xx и старше — CUDA 11.8
echo !GPU_FULLNAME! | findstr /I /R "GTX 16[0-9][0-9] GTX 10[0-9][0-9]" >nul 2>nul
if !errorlevel! equ 0 (
    set "CUDA_URL=https://download.pytorch.org/whl/cu118"
    set "CUDA_VER=11.8"
    echo   %ESC%[1;32m  +   Pascal/Turing — CUDA 11.8%ESC%[0m
    goto cuda_selected
)

REM Неизвестная NVIDIA
echo   %ESC%[1;33m  .   Поколение не определено: !GPU_FULLNAME!%ESC%[0m

:manual_select
echo.
echo   %ESC%[1;33mВыберите CUDA:%ESC%[0m
echo   %ESC%[1;37m[1]%ESC%[0m CUDA 12.8  %ESC%[2m(RTX 50xx — Blackwell)%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m CUDA 12.4  %ESC%[2m(RTX 40xx — Ada)%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m CUDA 11.8  %ESC%[2m(RTX 30xx и старше — Ampere/Pascal/Turing)%ESC%[0m
echo.
set "cchoice="
set /p "cchoice=%ESC%[33mВыбор: %ESC%[0m"
set "cchoice=%cchoice: =%"
if "%cchoice%"=="1" (
    set "CUDA_URL=https://download.pytorch.org/whl/cu128"
    set "CUDA_VER=12.8"
)
if "%cchoice%"=="2" (
    set "CUDA_URL=https://download.pytorch.org/whl/cu124"
    set "CUDA_VER=12.4"
)
if "%cchoice%"=="3" (
    set "CUDA_URL=https://download.pytorch.org/whl/cu118"
    set "CUDA_VER=11.8"
)

:cuda_selected
echo.

REM ============================================================================
REM   Обновление CUDA_VERSION в Config.ini
REM ============================================================================
if exist "%CONFIG_FILE%" (
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'CUDA_VERSION=.*', 'CUDA_VERSION=%CUDA_VER%' | Set-Content '%CONFIG_FILE%'"
    echo   %ESC%[2m       Config.ini: CUDA_VERSION=%CUDA_VER%%ESC%[0m
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
REM   PyTorch CUDA
REM ============================================================================
echo.
echo   %ESC%[1;33m[3/4]%ESC%[0m %ESC%[1mУстановка PyTorch CUDA !CUDA_VER!...%ESC%[0m
echo   %ESC%[2m       Источник: !CUDA_URL!%ESC%[0m

REM Проверка: уже установлена нужная версия?
"%VENV_PYTHON%" -c "import torch; import sys; v=torch.__version__; c=torch.version.cuda; sys.exit(0 if (c=='!CUDA_VER!' and '2.' in v) else 1)" >nul 2>nul
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   PyTorch CUDA !CUDA_VER! уже установлен.%ESC%[0m
    goto pytorch_done
)

echo   %ESC%[2m       Загрузка ~2-3 GB, может занять 10-30 минут...%ESC%[0m
echo   %ESC%[2m       Не закрывайте окно! При прерывании повторный запуск докачает из кэша.%ESC%[0m
echo.

REM Установка БЕЗ --quiet — видим прогресс
"%VENV_PIP%" install torch torchvision torchaudio --index-url !CUDA_URL!

if !errorlevel! neq 0 (
    echo.
    echo   %ESC%[1;31m[ОШИБКА] PyTorch CUDA !CUDA_VER! не установился.%ESC%[0m
    echo   %ESC%[33m       Возможные причины:%ESC%[0m
    echo   %ESC%[33m       1. Прервалась загрузка — запустите повторно, докачает из кэша%ESC%[0m
    echo   %ESC%[33m       2. Нет интернета%ESC%[0m
    echo   %ESC%[33m       3. Неверная версия CUDA для вашей карты%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)
echo   %ESC%[1;32m  +   PyTorch CUDA !CUDA_VER! установлен.%ESC%[0m

:pytorch_done

REM ============================================================================
REM   Зависимости ACE-Step
REM ============================================================================
echo.
echo   %ESC%[1;33m[4/4]%ESC%[0m %ESC%[1mУстановка зависимостей ACE-Step...%ESC%[0m
echo   %ESC%[2m       Это может занять 5-15 минут...%ESC%[0m

REM Сначала ставим всё кроме flash_attn
echo   %ESC%[2m       Установка основных зависимостей...%ESC%[0m
findstr /V /I "flash-attn" "%REPO_DIR%\requirements.txt" > "%TEMP%\requirements_base.txt"
"%VENV_PIP%" install -r "%TEMP%\requirements_base.txt"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Основные зависимости не установились.%ESC%[0m
    del "%TEMP%\requirements_base.txt" 2>nul
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)
echo   %ESC%[1;32m  +   Основные зависимости установлены.%ESC%[0m
del "%TEMP%\requirements_base.txt" 2>nul

REM ============================================================================
REM   flash_attn отдельно (GitHub Releases — curl с User-Agent)
REM ============================================================================
echo.
echo   %ESC%[1;33m→ Установка flash_attn...%ESC%[0m

REM Проверяем, уже установлен?
"%VENV_PYTHON%" -c "import flash_attn" >nul 2>nul
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   flash_attn уже установлен.%ESC%[0m
    goto flash_done
)

REM Парсим URL из requirements.txt
set "FLASH_URL="
for /f "tokens=*" %%a in ('findstr /I "flash-attn" "%REPO_DIR%\requirements.txt"') do (
    set "FLASH_RAW=%%a"
    set "FLASH_URL=!FLASH_RAW:flash-attn @ =!"
    for /f "delims=;" %%b in ("!FLASH_URL!") do set "FLASH_URL=%%b"
    set "FLASH_URL=!FLASH_URL: =!"
    goto flash_url_found
)
:flash_url_found

if "!FLASH_URL!"=="" (
    echo   %ESC%[1;33m  ⚠   URL flash_attn не найден в requirements.txt%ESC%[0m
    goto flash_done
)

echo   %ESC%[2m       Загрузка через curl...%ESC%[0m
set "USER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

REM Извлекаем имя файла из URL (через PowerShell — универсально)
for /f "usebackq" %%n in (`powershell -NoProfile -Command "[System.IO.Path]::GetFileName('!FLASH_URL!')"`) do (
    set "FLASH_NAME=%%n"
)

if "!FLASH_NAME!"=="" (
    echo   %ESC%[1;31m  -   Не удалось определить имя файла из URL.%ESC%[0m
    goto flash_done
)

echo   %ESC%[2m       Файл: !FLASH_NAME!%ESC%[0m

curl -L -A "%USER_AGENT%" -o "!TEMP!\!FLASH_NAME!" "!FLASH_URL!" --connect-timeout 30 --max-time 600 --progress-bar
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m  -   Не удалось загрузить flash_attn.%ESC%[0m
    echo   %ESC%[33m       Попробуйте с VPN или скачайте вручную:%ESC%[0m
    echo   %ESC%[33m       !FLASH_URL!%ESC%[0m
    goto flash_done
)

REM Проверяем, файл скачался
if not exist "!TEMP!\!FLASH_NAME!" (
    echo   %ESC%[1;31m  -   Файл не создан.%ESC%[0m
    goto flash_done
)
for %%F in ("!TEMP!\!FLASH_NAME!") do set "FLASH_SIZE=%%~zF"
if !FLASH_SIZE! lss 1000000 (
    echo   %ESC%[1;31m  -   Файл слишком маленький.%ESC%[0m
    del "!TEMP!\!FLASH_NAME!" 2>nul
    goto flash_done
)

echo   %ESC%[1;32m  +   Загружено (!FLASH_SIZE! байт).%ESC%[0m
echo   %ESC%[1;33m→ Установка из файла...%ESC%[0m

"%VENV_PIP%" install "!TEMP!\!FLASH_NAME!" --no-deps
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   flash_attn установлен.%ESC%[0m
) else (
    echo   %ESC%[1;31m[ОШИБКА] Установка flash_attn не удалась.%ESC%[0m
)

del "!TEMP!\!FLASH_NAME!" 2>nul

:flash_done

REM ============================================================================
REM   Проверка
REM ============================================================================
echo.
echo   %ESC%[1;33mПроверка...%ESC%[0m
"%VENV_PYTHON%" -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}'); print(f'GPU: {torch.cuda.is_available()}')" 2>nul
if !errorlevel! equ 0 (
    echo   %ESC%[1;32m  +   PyTorch работает!%ESC%[0m
) else (
    echo   %ESC%[1;33m  ⚠   Не удалось проверить PyTorch.%ESC%[0m
)

echo.
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;32mГотово: %ESC%[0m  %ESC%[2mPyTorch CUDA !CUDA_VER! установлен.%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo.

if "%AUTOCLOSE%"=="0" pause
popd
exit /b 0