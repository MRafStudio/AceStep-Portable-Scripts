@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title Git Portable — Установка / Обновление

REM ============================================================================
REM   Определение путей
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "GIT_DIR=%ROOT_DIR%\git"
set "GIT_EXE=%GIT_DIR%\cmd\git.exe"

REM ============================================================================
REM   ИЗОЛЯЦИЯ ДАННЫХ
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "TMP=%DATA_DIR%\temp"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul

REM ============================================================================
REM   КРИТИЧЕСКИ ВАЖНО: Создаём временный скрипт для PowerShell с изоляцией
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

REM ============================================================================
REM   Получение ESC через изолированный PowerShell
REM ============================================================================
for /f "usebackq" %%a in (`%PS_WRAPPER% -Command "Write-Host ([char]27) -NoNewline"`) do set "ESC=%%a"

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                  %ESC%[1;37mGit Portable%ESC%[0m   —   %ESC%[1;33mУстановка / Обновление%ESC%[0m                 %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка ГЛОБАЛЬНОГО Git (системного)
REM ============================================================================
set "GLOBAL_GIT="
where git >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('where git 2^>nul') do set "GLOBAL_GIT=%%a"
)

if defined GLOBAL_GIT (
    for /f "tokens=*" %%a in ('git --version 2^>nul') do set "GIT_VER=%%a"
    echo   %ESC%[1;32m  ✔   Глобальный Git найден: !GIT_VER!%ESC%[0m
    echo   %ESC%[2m       Путь: !GLOBAL_GIT!%ESC%[0m
    echo.
    
    REM ============================================================================
    REM   Создаём символическую ссылку на глобальный Git (или копируем путь)
    REM ============================================================================
    if not exist "%GIT_DIR%" mkdir "%GIT_DIR%" 2>nul
    
    REM Проверяем, что portable Git ещё не создан
    if not exist "%GIT_EXE%" (
        echo   %ESC%[1;33m→%ESC%[0m %ESC%[1mСоздание ссылки на глобальный Git...%ESC%[0m
        
        REM Копируем путь в .cmd файл для использования
        (
            echo @echo off
            echo "%GLOBAL_GIT%" %%*
        ) > "%GIT_DIR%\git.cmd"
        
        echo   %ESC%[1;32m  ✔   Ссылка на глобальный Git создана.%ESC%[0m
        echo   %ESC%[2m       Приоритет: глобальный Git%ESC%[0m
    ) else (
        echo   %ESC%[2m       Portable Git уже существует.%ESC%[0m
    )
    
    set "PATH=%GIT_DIR%;%PATH%"
    
    if "%AUTOCLOSE%"=="0" pause
    del "%PS_WRAPPER%" 2>nul
    exit /b 0
)

REM ============================================================================
REM   Проверка ЛОКАЛЬНОГО (portable) Git
REM ============================================================================
if exist "%GIT_EXE%" (
    for /f "tokens=*" %%a in ('"%GIT_EXE%" --version 2^>nul') do set "GIT_VER=%%a"
    echo   %ESC%[1;32m  ✔   Portable Git уже установлен: !GIT_VER!%ESC%[0m
    echo   %ESC%[2m       Путь: %GIT_DIR%%ESC%[0m
    echo.
    
    set "PATH=%GIT_DIR%\cmd;%PATH%"
    
    if "%AUTOCLOSE%"=="0" pause
    del "%PS_WRAPPER%" 2>nul
    exit /b 0
)

REM ============================================================================
REM   Ни глобального, ни локального — устанавливаем portable
REM ============================================================================
echo   %ESC%[1;33m[1/2]%ESC%[0m %ESC%[1mЗагрузка Git Portable...%ESC%[0m
echo   %ESC%[2m       ~50 МБ%ESC%[0m

curl -# -L -o "%TEMP%\git-portable.zip" "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/MinGit-2.45.1-64-bit.zip"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось загрузить Git.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    del "%PS_WRAPPER%" 2>nul
    exit /b 1
)

echo   %ESC%[1;32m  ✔   Загрузка завершена.%ESC%[0m
echo.
echo   %ESC%[1;33m[2/2]%ESC%[0m %ESC%[1mРаспаковка...%ESC%[0m

if exist "%GIT_DIR%" rmdir /s /q "%GIT_DIR%"
mkdir "%GIT_DIR%"

REM ============================================================================
REM   Распаковка: сначала 7-Zip, потом PowerShell (fallback)
REM ============================================================================
echo   %ESC%[2m       Попытка распаковки через 7-Zip...%ESC%[0m

set "SEVENZIP="

where 7z >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('where 7z 2^>nul') do set "SEVENZIP=%%a"
)

if not defined SEVENZIP (
    if exist "C:\Program Files\7-Zip\7z.exe" set "SEVENZIP=C:\Program Files\7-Zip\7z.exe"
)
if not defined SEVENZIP (
    if exist "C:\Program Files (x86)\7-Zip\7z.exe" set "SEVENZIP=C:\Program Files (x86)\7-Zip\7z.exe"
)

if defined SEVENZIP (
    echo   %ESC%[2m       Найден 7-Zip: %SEVENZIP%%ESC%[0m
    "%SEVENZIP%" x "%TEMP%\git-portable.zip" -o"%GIT_DIR%" -y >nul 2>&1
    if !errorlevel! equ 0 (
        echo   %ESC%[1;32m  ✔   Распаковка через 7-Zip завершена.%ESC%[0m
    ) else (
        echo   %ESC%[1;33m  ⚠   7-Zip не справился. Переключение на PowerShell...%ESC%[0m
        goto ps_unpack_git
    )
) else (
    echo   %ESC%[2m       7-Zip не найден. Используем PowerShell...%ESC%[0m
    goto ps_unpack_git
)

goto unpack_done_git

:ps_unpack_git
%PS_WRAPPER% -Command "Expand-Archive -Path '%TEMP%\git-portable.zip' -DestinationPath '%GIT_DIR%' -Force"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось распаковать Git.%ESC%[0m
    rmdir /s /q "%GIT_DIR%" 2>nul
    del "%TEMP%\git-portable.zip" 2>nul
    del "%PS_WRAPPER%" 2>nul
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)
echo   %ESC%[1;32m  ✔   Распаковка через PowerShell завершена.%ESC%[0m

:unpack_done_git

del "%TEMP%\git-portable.zip" 2>nul

if not exist "%GIT_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Git не установился.%ESC%[0m
    del "%PS_WRAPPER%" 2>nul
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)

echo   %ESC%[1;32m  ✔   Git успешно установлен (portable).%ESC%[0m
echo   %ESC%[2m       Путь: %GIT_DIR%%ESC%[0m

set "PATH=%GIT_DIR%\cmd;%PATH%"

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mУстановка Git завершена!%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

del "%PS_WRAPPER%" 2>nul

if "%AUTOCLOSE%"=="0" pause
exit /b 0