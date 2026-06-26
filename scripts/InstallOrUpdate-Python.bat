REM scripts\InstallOrUpdate-Python.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================================================
REM   Python 3.12.10 Portable — установка / обновление
REM ============================================================================

title Python Portable — Установка / Обновление

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

REM ============================================================================
REM   Определение путей (корень проекта = уровень выше scripts\)
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "PYTHON_DIR=%ROOT_DIR%\python-3.12.10"
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"

REM ============================================================================
REM   ИЗОЛЯЦИЯ ДАННЫХ (принудительно, ничего в систему!)
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "TMP=%DATA_DIR%\temp"
set "APPDATA=%DATA_DIR%\appdata"
set "LOCALAPPDATA=%DATA_DIR%\localappdata"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"
set "PIP_CACHE_DIR=%DATA_DIR%\pip-cache"
set "PYTHONUSERBASE=%DATA_DIR%\python-user"

REM Создаём папки заранее
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%APPDATA%" mkdir "%APPDATA%" 2>nul
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul
if not exist "%PIP_CACHE_DIR%" mkdir "%PIP_CACHE_DIR%" 2>nul
if not exist "%PYTHONUSERBASE%" mkdir "%PYTHONUSERBASE%" 2>nul

REM ============================================================================
REM   КРИТИЧЕСКИ ВАЖНО: Создаём временный скрипт для PowerShell с изоляцией
REM   Чтобы PowerShell не создавал Microsoft\ в корне проекта
REM ============================================================================
set "PS_WRAPPER=%TEMP%\ps_wrapper.bat"
(
    echo @echo off
    echo set "LOCALAPPDATA=%LOCALAPPDATA%"
    echo set "APPDATA=%APPDATA%"
    echo set "TEMP=%TEMP%"
    echo set "TMP=%TMP%"
    echo set "HOME=%HOME%"
    echo set "USERPROFILE=%USERPROFILE%"
    echo powershell -NoProfile -NonInteractive %%*
) > "%PS_WRAPPER%"

REM ============================================================================
REM   Получение ESC через изолированный PowerShell (usebackq для кавычек)
REM ============================================================================
for /f "usebackq" %%a in (`%PS_WRAPPER% -Command "Write-Host ([char]27) -NoNewline"`) do set "ESC=%%a"

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m           %ESC%[1;37mPython 3.12.10 Portable%ESC%[0m   —   %ESC%[1;33mУстановка / Обновление%ESC%[0m             %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

echo   %ESC%[1;33m[0/3]%ESC%[0m %ESC%[1mПроверка разрядности Windows...%ESC%[0m
set ARCH_OK=0
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set ARCH_OK=1
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set ARCH_OK=1

if %ARCH_OK%==0 (
    echo.
    echo   %ESC%[1;31m^[ОШИБКА^] Обнаружена 32-разрядная ^(x86^) версия Windows.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)
echo   %ESC%[1;32m  ✔   Система 64-разрядная (x64).%ESC%[0m
echo.

REM ============================================================================
REM   Проверка установленного Python
REM ============================================================================
set "PYTHON_OK=0"

if exist "%PYTHON_EXE%" (
    REM python.exe работает?
    "%PYTHON_EXE%" --version >nul 2>nul
    if !errorlevel! equ 0 (
        REM pip доступен?
        "%PYTHON_EXE%" -m pip --version >nul 2>nul
        if !errorlevel! equ 0 (
            set "PYTHON_OK=1"
        ) else (
            echo   %ESC%[1;33m  .   Python найден, но pip не работает. Переустановка...%ESC%[0m
        )
    ) else (
        echo   %ESC%[1;33m  .   Python найден, но не работает. Переустановка...%ESC%[0m
    )
)

if "!PYTHON_OK!"=="1" (
    echo   %ESC%[1;32m  +   Python уже установлен.%ESC%[0m
    set /p "=%ESC%[2m       Версия: %ESC%[0m" <nul
    "%PYTHON_EXE%" --version 2>nul
    echo.
    goto check_hf
)

REM Если дошли сюда — Python битый или не установлен, удаляем и ставим заново
if exist "%PYTHON_DIR%" (
    echo   %ESC%[1;33m  .   Удаление повреждённой установки...%ESC%[0m
    rmdir /s /q "%PYTHON_DIR%"
)

echo   %ESC%[1;33m[1/3]%ESC%[0m %ESC%[1mЗагрузка Python 3.12.10...%ESC%[0m
echo   %ESC%[2m       ~32 МБ, подождите...%ESC%[0m

REM Удаляем битый zip если есть
if exist "%TEMP%\python-3.12.10-amd64.zip" del "%TEMP%\python-3.12.10-amd64.zip" 2>nul

REM ============================================================================
REM   Загрузка с изоляцией TEMP
REM ============================================================================
curl -L -o "%TEMP%\python-3.11.9-amd64.zip" "https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.zip"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось загрузить Python.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)

echo   %ESC%[1;32m  +   Загрузка завершена.%ESC%[0m
echo   %ESC%[1;33m[2/3]%ESC%[0m %ESC%[1mРаспаковка...%ESC%[0m

if exist "%PYTHON_DIR%" rmdir /s /q "%PYTHON_DIR%"
mkdir "%PYTHON_DIR%"

REM ============================================================================
REM   Распаковка: сначала 7-Zip, потом PowerShell (fallback)
REM ============================================================================
echo   %ESC%[2m       Попытка распаковки через 7-Zip...%ESC%[0m

set "SEVENZIP="

REM Ищем 7z.exe в PATH
where 7z >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('where 7z 2^>nul') do set "SEVENZIP=%%a"
)

REM Ищем в стандартных путях
if not defined SEVENZIP (
    if exist "C:\Program Files\7-Zip\7z.exe" set "SEVENZIP=C:\Program Files\7-Zip\7z.exe"
)
if not defined SEVENZIP (
    if exist "C:\Program Files (x86)\7-Zip\7z.exe" set "SEVENZIP=C:\Program Files (x86)\7-Zip\7z.exe"
)

if defined SEVENZIP (
    echo   %ESC%[2m       Найден 7-Zip: %SEVENZIP%%ESC%[0m
    
    REM Распаковка через 7-Zip (быстро и надёжно)
    "%SEVENZIP%" x "%TEMP%\python-3.11.9-amd64.zip" -o"%PYTHON_DIR%" -y >nul 2>&1
    
    if !errorlevel! equ 0 (
        echo   %ESC%[32m  ✔   Распаковка через 7-Zip завершена.%ESC%[0m
    ) else (
        echo   %ESC%[1;33m  ⚠   7-Zip не справился. Переключение на PowerShell...%ESC%[0m
        goto ps_unpack
    )
) else (
    echo   %ESC%[2m       7-Zip не найден. Используем PowerShell...%ESC%[0m
    goto ps_unpack
)

goto unpack_done

:ps_unpack
REM ============================================================================
REM   Fallback: PowerShell с изоляцией (через wrapper)
REM ============================================================================
%PS_WRAPPER% -Command "Expand-Archive -Path '%TEMP%\python-3.11.9-amd64.zip' -DestinationPath '%PYTHON_DIR%' -Force"

if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось распаковать архив!%ESC%[0m
    rmdir /s /q "%PYTHON_DIR%" 2>nul
    del "%TEMP%\python-3.11.9-amd64.zip" 2>nul
    del "%PS_WRAPPER%" 2>nul
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)

echo   %ESC%[32m  ✔   Распаковка через PowerShell завершена.%ESC%[0m

:unpack_done

del "%TEMP%\python-3.11.9-amd64.zip" 2>nul

echo   %ESC%[32m  ✔   Python успешно установлен в python-3.11.9\%ESC%[0m
set /p "=%ESC%[2m       Версия: %ESC%[0m" <nul
"%PYTHON_EXE%" --version 2>nul
echo.

:check_hf
REM ============================================================================
REM   Установка / обновление huggingface-hub
REM ============================================================================
echo   %ESC%[1;33m[3/3]%ESC%[0m %ESC%[1mПроверка hf.exe...%ESC%[0m

REM Добавляем Scripts в PATH для текущей сессии
set "PATH=%PYTHON_DIR%;%PYTHON_DIR%\Scripts;%PATH%"

where hf >nul 2>nul
if !errorlevel! neq 0 (
    echo   %ESC%[1;33m  →   Установка huggingface-hub...%ESC%[0m
    
    REM ============================================================================
    REM   Изоляция для pip
    REM ============================================================================
    set "TEMP=%DATA_DIR%\temp"
    set "TMP=%DATA_DIR%\temp"
    set "APPDATA=%DATA_DIR%\appdata"
    set "LOCALAPPDATA=%DATA_DIR%\localappdata"
    set "HOME=%DATA_DIR%\home"
    set "USERPROFILE=%DATA_DIR%\home"
    set "PIP_CACHE_DIR=%DATA_DIR%\pip-cache"
    
    "%PYTHON_EXE%" -m pip install huggingface-hub --no-warn-script-location --cache-dir "%PIP_CACHE_DIR%"
    
    if !errorlevel! neq 0 (
        echo   %ESC%[1;31m[ОШИБКА] Не удалось установить huggingface-hub.%ESC%[0m
        echo   %ESC%[33m       Загрузка моделей будет недоступна.%ESC%[0m
    ) else (
        echo   %ESC%[1;32m  ✔   hf.exe установлен.%ESC%[0m
    )
) else (
    echo   %ESC%[1;33m  →   Обновление huggingface-hub...%ESC%[0m
    
    REM ============================================================================
    REM   Изоляция для pip
    REM ============================================================================
    set "TEMP=%DATA_DIR%\temp"
    set "TMP=%DATA_DIR%\temp"
    set "APPDATA=%DATA_DIR%\appdata"
    set "LOCALAPPDATA=%DATA_DIR%\localappdata"
    set "HOME=%DATA_DIR%\home"
    set "USERPROFILE=%DATA_DIR%\home"
    set "PIP_CACHE_DIR=%DATA_DIR%\pip-cache"
    
    "%PYTHON_EXE%" -m pip install --upgrade huggingface-hub --no-warn-script-location --cache-dir "%PIP_CACHE_DIR%"
    
    if !errorlevel! neq 0 (
        echo   %ESC%[1;33m  ⚠   Не удалось обновить huggingface-hub. Используется текущая версия.%ESC%[0m
    ) else (
        echo   %ESC%[1;32m  ✔   hf.exe обновлён до последней версии.%ESC%[0m
    )
)
REM ============================================================================
REM   Удаляем временный wrapper
REM ============================================================================
del "%PS_WRAPPER%" 2>nul

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mPython 3.12.10 успешно установлен!%ESC%[0m
echo   %ESC%[2m  Путь: %PYTHON_DIR%%ESC%[0m
echo   %ESC%[2m  Изоляция: %DATA_DIR%%ESC%[0m
echo   %ESC%[2m  hf.exe: готов к загрузке моделей%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

if "%AUTOCLOSE%"=="0" pause
exit /b 0