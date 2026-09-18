@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

title Installation - Consolidation Balance
color 0A

echo.
echo ============================================================
echo       INSTALLATION DE CONSOLIDATION BALANCE
echo ============================================================
echo.

:: ============================================================
:: CHEMINS
:: ============================================================

set "WINDOWS_DIR=%~dp0"
set "PROJECT_DIR=%WINDOWS_DIR%.."
set "BACKEND_DIR=%PROJECT_DIR%\excel-consolidator-backend"
set "FRONTEND_DIR=%PROJECT_DIR%\excel-consolidator-frontend"

echo Projet :
echo %PROJECT_DIR%
echo.

:: ============================================================
:: NODE.JS
:: ============================================================

echo ============================================================
echo [1/5] Verification de Node.js
echo ============================================================
echo.

where node >nul 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo Node.js n'est pas installe.
    echo.
    echo Recherche de winget...

    where winget >nul 2>nul

    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [ERREUR] winget n'est pas disponible.
        echo.
        echo Installez Node.js LTS depuis :
        echo https://nodejs.org/
        echo.
        pause
        exit /b 1
    )

    echo Installation de Node.js LTS...
    echo.

    winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements

    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo [ERREUR] Installation de Node.js echouee.
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Node.js a ete installe.
    echo.
    echo IMPORTANT :
    echo Fermez cette fenetre puis relancez install.bat.
    echo.
    pause
    exit /b 0
)

for /f "tokens=*" %%v in ('node --version') do (
    echo Node.js : %%v
)

echo.

:: ============================================================
:: NPM
:: ============================================================

echo ============================================================
echo [2/5] Verification de npm
echo ============================================================
echo.

where npm >nul 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] npm est introuvable.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('npm --version') do (
    echo npm : %%v
)

echo.

:: ============================================================
:: BACKEND
:: ============================================================

echo ============================================================
echo [3/5] Installation du backend
echo ============================================================
echo.

if not exist "%BACKEND_DIR%\package.json" (
    echo [ERREUR] Backend introuvable :
    echo %BACKEND_DIR%
    echo.
    pause
    exit /b 1
)

cd /d "%BACKEND_DIR%"

if exist "package-lock.json" (
    echo Installation avec npm ci...
    call npm ci
) else (
    echo Installation avec npm install...
    call npm install
)

if !ERRORLEVEL! NEQ 0 (
    echo.
    echo [ERREUR] Installation du backend echouee.
    echo.
    pause
    exit /b 1
)

echo.
echo Backend : OK
echo.

:: ============================================================
:: FRONTEND
:: ============================================================

echo ============================================================
echo [4/5] Installation du frontend
echo ============================================================
echo.

if not exist "%FRONTEND_DIR%\package.json" (
    echo [ERREUR] Frontend introuvable :
    echo %FRONTEND_DIR%
    echo.
    pause
    exit /b 1
)

cd /d "%FRONTEND_DIR%"

if exist "package-lock.json" (
    echo Installation avec npm ci...
    call npm ci
) else (
    echo Installation avec npm install...
    call npm install
)

if !ERRORLEVEL! NEQ 0 (
    echo.
    echo [ERREUR] Installation du frontend echouee.
    echo.
    pause
    exit /b 1
)

echo.
echo Frontend : OK
echo.

:: ============================================================
:: RACCOURCI
:: ============================================================

echo ============================================================
echo [5/5] Creation du raccourci Bureau
echo ============================================================
echo.

set "START_BAT=%WINDOWS_DIR%start.bat"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell;" ^
  "$desktop = [Environment]::GetFolderPath('Desktop');" ^
  "$shortcut = $ws.CreateShortcut((Join-Path $desktop 'Consolidation Balance.lnk'));" ^
  "$shortcut.TargetPath = $env:ComSpec;" ^
  "$shortcut.Arguments = '/c call ""%START_BAT%""';" ^
  "$shortcut.WorkingDirectory = '%WINDOWS_DIR%';" ^
  "$shortcut.IconLocation = '%SystemRoot%\System32\shell32.dll,13';" ^
  "$shortcut.Description = 'Demarrer Consolidation Balance';" ^
  "$shortcut.Save();"

if !ERRORLEVEL! EQU 0 (
    echo Raccourci cree avec succes.
) else (
    echo [AVERTISSEMENT] Impossible de creer le raccourci.
    echo.
    echo Vous pouvez utiliser start.bat directement.
)

echo.
echo ============================================================
echo       INSTALLATION TERMINEE
echo ============================================================
echo.
echo Le raccourci "Consolidation Balance" est disponible
echo sur le Bureau.
echo.
echo Double-cliquez dessus pour lancer l'application.
echo.

pause

endlocal
exit /b 0