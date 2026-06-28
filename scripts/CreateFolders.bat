@echo off
REM Создание стандартных папок пользователя в изолированном окружении

if not exist "%HOME%" mkdir "%HOME%" 2>nul
if not exist "%HOME%\Desktop" mkdir "%HOME%\Desktop" 2>nul
if not exist "%HOME%\Documents" mkdir "%HOME%\Documents" 2>nul
if not exist "%HOME%\Downloads" mkdir "%HOME%\Downloads" 2>nul
if not exist "%HOME%\Pictures" mkdir "%HOME%\Pictures" 2>nul
if not exist "%HOME%\Music" mkdir "%HOME%\Music" 2>nul
if not exist "%HOME%\Videos" mkdir "%HOME%\Videos" 2>nul