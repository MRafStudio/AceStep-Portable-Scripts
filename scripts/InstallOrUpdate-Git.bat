@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title Git Portable — Установка / Обновление
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение ROOT_DIR (корень проекта = уровень выше scripts\)
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "GIT_DIR=%ROOT_DIR%\git"
set "GIT_EXE=%GIT_DIR%\cmd\git.exe"

REM ============================================================================
REM   Изоляция данных
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "TMP=%DATA_DIR%\temp"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                %ESC%[1;37mGit Portable%ESC%[0m   —   %ESC%[1;33mУстановка / Обновление%ESC%[0m                 %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка установленного Git
REM ============================================================================
if exist "%GIT_EXE%" (
    for /f "tokens=*" %%a in ('"%GIT_EXE%" --version 2^>nul') do set "GIT_VER=%%a"
    echo   %ESC%[1;32m  ✔   Git уже установлен: !GIT_VER!%ESC%[0m
    echo   %ESC%[2m       Путь: %GIT_DIR%%ESC%[0m
    echo.
    
    REM Обновляем PATH
    set "PATH=%GIT_DIR%\cmd;%PATH%"
    
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 0
)

echo   %ESC%[1;33m[1/2]%ESC%[0m %ESC%[1mЗагрузка Git Portable...%ESC%[0m
echo   %ESC%[2m       ~50 МБ%ESC%[0m

curl -# -L -o "%TEMP%\git-portable.zip" "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/PortableGit-2.45.1-64-bit.7z.exe"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось загрузить Git.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

echo   %ESC%[1;32m  ✔   Загрузка завершена.%ESC%[0m
echo.
echo   %ESC%[1;33m[2/2]%ESC%[0m %ESC%[1mРаспаковка...%ESC%[0m

if exist "%GIT_DIR%" rmdir /s /q "%GIT_DIR%"
mkdir "%GIT_DIR%"

REM PortableGit скачивается как самораспаковывающийся 7z, но мы можем использовать 7z или переименовать
REM На самом деле PortableGit-2.45.1-64-bit.7z.exe — это 7z SFX, можно распаковать через 7z
REM Но проще скачать .zip версию

REM Альтернатива: скачиваем .zip
echo   %ESC%[2m       Попытка загрузить .zip версию...%ESC%[0m
curl -# -L -o "%TEMP%\git-portable.zip" "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/MinGit-2.45.1-64-bit.zip"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось загрузить Git.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

powershell -Command "& { Expand-Archive -Path '%TEMP%\git-portable.zip' -DestinationPath '%GIT_DIR%' -Force }"
del "%TEMP%\git-portable.zip" 2>nul

if not exist "%GIT_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Git не установился.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    popd
    exit /b 1
)

echo   %ESC%[1;32m  ✔   Git успешно установлен.%ESC%[0m
echo   %ESC%[2m       Путь: %GIT_DIR%%ESC%[0m

REM Обновляем PATH
set "PATH=%GIT_DIR%\cmd;%PATH%"

echo.
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo   %ESC%[1;32mУстановка Git завершена!%ESC%[0m
echo  %ESC%[36m--------------------------------------------------------------------------------%ESC%[0m
echo.

if "%AUTOCLOSE%"=="0" pause
popd
exit /b 0