REM scripts\Settings.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title AceStep-1.5 Portable — Настройки
pushd %~dp0..

for /f %%a in ('powershell -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение ROOT_DIR (корень проекта = уровень выше scripts\)
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"

:menu
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                      %ESC%[1;37mAceStep-1.5 Portable%ESC%[0m   —   %ESC%[1;33mНастройки%ESC%[0m                  %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Чтение текущих настроек
REM ============================================================================
set "CURRENT_MODEL=turbo"
set "AUTO_OPEN_BROWSER=1"
set "LAUNCH_METHOD=gradio"
set "LANGUAGE=ru"

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CURRENT_MODEL=" "%CONFIG_FILE%"') do set "CURRENT_MODEL=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LAUNCH_METHOD=" "%CONFIG_FILE%"') do set "LAUNCH_METHOD=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LANGUAGE=" "%CONFIG_FILE%"') do set "LANGUAGE=%%b"
)

set "CURRENT_MODEL=%CURRENT_MODEL: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"
set "LAUNCH_METHOD=%LAUNCH_METHOD: =%"
set "LANGUAGE=%LANGUAGE: =%"

REM Валидация модели
set "VALID_MODEL=0"
if /I "%CURRENT_MODEL%"=="base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="turbo" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-base" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-sft" set "VALID_MODEL=1"
if /I "%CURRENT_MODEL%"=="xl-turbo" set "VALID_MODEL=1"

if "!VALID_MODEL!"=="0" set "CURRENT_MODEL=turbo"
if /I "%CURRENT_MODEL%"=="base" set "CURRENT_MODEL=turbo"

REM Маппинг для отображения
if "%CURRENT_MODEL%"=="turbo"    set "DISP_MODEL=acestep-v15-turbo"
if "%CURRENT_MODEL%"=="sft"      set "DISP_MODEL=acestep-v15-sft"
if "%CURRENT_MODEL%"=="xl-base"  set "DISP_MODEL=acestep-v15-xl-base"
if "%CURRENT_MODEL%"=="xl-sft"   set "DISP_MODEL=acestep-v15-xl-sft"
if "%CURRENT_MODEL%"=="xl-turbo" set "DISP_MODEL=acestep-v15-xl-turbo"

REM Маппинг языка для отображения
if "%LANGUAGE%"=="en" set "DISP_LANG=English"
if "%LANGUAGE%"=="zh" set "DISP_LANG=中文"
if "%LANGUAGE%"=="ja" set "DISP_LANG=日本語"
if "%LANGUAGE%"=="he" set "DISP_LANG=עברית"
if "%LANGUAGE%"=="pt" set "DISP_LANG=Português"
if "%LANGUAGE%"=="ru" set "DISP_LANG=Русский"
if not defined DISP_LANG set "DISP_LANG=%LANGUAGE%"

echo   %ESC%[1;33mТекущие настройки:%ESC%[0m
echo.
echo   %ESC%[1;37m[1]%ESC%[0m Модель: %ESC%[1;33m%CURRENT_MODEL%%ESC%[0m %ESC%[2m^(%DISP_MODEL%^)%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m Автозапуск браузера: %ESC%[1;33m%AUTO_OPEN_BROWSER%%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m Метод запуска: %ESC%[1;33m%LAUNCH_METHOD%%ESC%[0m
echo   %ESC%[1;37m[4]%ESC%[0m Язык интерфейса: %ESC%[1;33m%DISP_LANG%%ESC%[0m
echo.
echo   %ESC%[1;37m[0]%ESC%[0m %ESC%[1mСохранить и выйти%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите настройку (1-4, 0 для выхода): %ESC%[0m"

set "choice=%choice: =%"
if "%choice%"=="" goto menu
if "%choice%"=="0" goto exit
if "%choice%"=="1" goto set_model
if "%choice%"=="2" goto set_browser
if "%choice%"=="3" goto set_method
if "%choice%"=="4" goto set_language
goto menu

:set_model
cls
echo.
echo   %ESC%[1;33mВыбор модели DiT:%ESC%[0m
echo.
echo   %ESC%[1;34m── Стандарт (2B, ~5GB) ─────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mturbo%ESC%[0m  %ESC%[2m~5GB  |  VRAM: 6GB+  |  Шаги: 8   |  Быстрая%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1msft%ESC%[0m    %ESC%[2m~5GB  |  VRAM: 6GB+  |  Шаги: 50  |  Стандарт%ESC%[0m
echo.
echo   %ESC%[1;34m── XL (4B, ~19GB) ───────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1mxl-base%ESC%[0m   %ESC%[2m~19GB |  VRAM: 12GB+ |  Шаги: 50  |  Все задачи%ESC%[0m
echo   %ESC%[1;37m[4]%ESC%[0m %ESC%[1mxl-sft%ESC%[0m    %ESC%[2m~19GB |  VRAM: 12GB+ |  Шаги: 50  |  Стандарт%ESC%[0m
echo   %ESC%[1;37m[5]%ESC%[0m %ESC%[1mxl-turbo%ESC%[0m  %ESC%[2m~19GB |  VRAM: 12GB+ |  Шаги: 8   |  Быстрая%ESC%[0m
echo.
echo   %ESC%[1;33mТвоя видеокарта:%ESC%[0m %ESC%[1;32mRTX 5090 32GB%ESC%[0m
echo   %ESC%[1;32m  Рекомендуется: xl-base или xl-sft для максимального качества%ESC%[0m
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
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'CURRENT_MODEL=.*', 'CURRENT_MODEL=%NEW_MODEL%' | Set-Content '%CONFIG_FILE%'"
    echo   %ESC%[1;32m  ✔   Модель изменена на %NEW_MODEL%%ESC%[0m
    timeout /t 2 /nobreak >nul
)
goto menu

:set_browser
cls
echo.
echo   %ESC%[1;33mАвтозапуск браузера:%ESC%[0m
echo.
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mВключить%ESC%[0m  — браузер откроется автоматически при запуске
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mВыключить%ESC%[0m — запуск только сервера, браузер вручную
echo.
set "bchoice="
set /p "bchoice=%ESC%[33mВыберите (1-2): %ESC%[0m"

set "bchoice=%bchoice: =%"
if "%bchoice%"=="1" (
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'AUTO_OPEN_BROWSER=.*', 'AUTO_OPEN_BROWSER=1' | Set-Content '%CONFIG_FILE%'"
    echo   %ESC%[1;32m  ✔   Автозапуск включён%ESC%[0m
    timeout /t 2 /nobreak >nul
)
if "%bchoice%"=="2" (
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'AUTO_OPEN_BROWSER=.*', 'AUTO_OPEN_BROWSER=0' | Set-Content '%CONFIG_FILE%'"
    echo   %ESC%[1;32m  ✔   Автозапуск выключен%ESC%[0m
    timeout /t 2 /nobreak >nul
)
goto menu

:set_method
cls
echo.
echo   %ESC%[1;33mМетод запуска:%ESC%[0m
echo.
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mgradio%ESC%[0m  — веб-интерфейс Gradio (простой, стабильный)
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1mcomfyui%ESC%[0m — ноды ComfyUI (сложнее, но гибче)
echo.
set "mchoice="
set /p "mchoice=%ESC%[33mВыберите (1-2): %ESC%[0m"

set "mchoice=%mchoice: =%"
if "%mchoice%"=="1" (
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'LAUNCH_METHOD=.*', 'LAUNCH_METHOD=gradio' | Set-Content '%CONFIG_FILE%'"
    echo   %ESC%[1;32m  ✔   Метод изменён на gradio%ESC%[0m
    timeout /t 2 /nobreak >nul
)
if "%mchoice%"=="2" (
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'LAUNCH_METHOD=.*', 'LAUNCH_METHOD=comfyui' | Set-Content '%CONFIG_FILE%'"
    echo   %ESC%[1;32m  ✔   Метод изменён на comfyui%ESC%[0m
    timeout /t 2 /nobreak >nul
)
goto menu

:set_language
cls
echo.
echo   %ESC%[1;33mВыбор языка интерфейса:%ESC%[0m
echo.
echo   %ESC%[1;37m[1]%ESC%[0m %ESC%[1mEnglish%ESC%[0m
echo   %ESC%[1;37m[2]%ESC%[0m %ESC%[1m中文 (Chinese)%ESC%[0m
echo   %ESC%[1;37m[3]%ESC%[0m %ESC%[1m日本語 (Japanese)%ESC%[0m
echo   %ESC%[1;37m[4]%ESC%[0m %ESC%[1mРусский%ESC%[0m
echo   %ESC%[1;37m[5]%ESC%[0m %ESC%[1mעברית (Hebrew)%ESC%[0m
echo   %ESC%[1;37m[6]%ESC%[0m %ESC%[1mPortuguês%ESC%[0m
echo.
set "lchoice="
set /p "lchoice=%ESC%[33mВыберите язык (1-6): %ESC%[0m"

set "lchoice=%lchoice: =%"
if "%lchoice%"=="1" set "NEW_LANG=en"
if "%lchoice%"=="2" set "NEW_LANG=zh"
if "%lchoice%"=="3" set "NEW_LANG=ja"
if "%lchoice%"=="4" set "NEW_LANG=ru"
if "%lchoice%"=="5" set "NEW_LANG=he"
if "%lchoice%"=="6" set "NEW_LANG=pt"

if defined NEW_LANG (
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'LANGUAGE=.*', 'LANGUAGE=%NEW_LANG%' | Set-Content '%CONFIG_FILE%'"
    set "LANGUAGE=%NEW_LANG%"
    echo   %ESC%[1;32m  ✔   Язык изменён на %NEW_LANG%%ESC%[0m
    timeout /t 2 /nobreak >nul
)
goto menu

:exit
popd
exit /b 0