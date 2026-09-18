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
:: CHEMINS DU PROJET
:: ============================================================

set "WINDOWS_DIR=%~dp0"
set "PROJECT_DIR=%WINDOWS_DIR%.."
set "BACKEND_DIR=%PROJECT_DIR%\excel-consolidator-backend"
set "FRONTEND_DIR=%PROJECT_DIR%\excel-consolidator-frontend"

echo Dossier du projet :
echo %PROJECT_DIR%
echo.

:: ============================================================
:: ETAPE 1 - NODE.JS
:: ============================================================

echo ============================================================
echo [1/5] Verification de Node.js
echo ============================================================
echo.

where node >nul 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo Node.js n'est pas installe.
    echo.
    echo Tentative d'installation de Node.js LTS...
    echo.

    where winget >nul 2>nul

    if %ERRORLEVEL% NEQ 0 (
        echo [ERREUR] winget n'est pas disponible sur ce PC.
        echo.
        echo Installez Node.js LTS manuellement depuis :
        echo https://nodejs.org/
        echo.
        pause
        exit /b 1
    )

    winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements

    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo [ERREUR] L'installation de Node.js a echoue.
        echo.
        echo Installez Node.js LTS manuellement depuis :
        echo https://nodejs.org/
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Node.js a ete installe.
    echo.
    echo Fermez cette fenetre puis relancez install.bat.
    echo Cela permettra a Windows de recharger le PATH.
    echo.

    pause
    exit /b 0
)

for /f "tokens=*" %%v in ('node --version') do set "NODE_VERSION=%%v"

echo Node.js detecte : !NODE_VERSION!
echo.

:: ============================================================
:: ETAPE 2 - NPM
:: ============================================================

echo ============================================================
echo [2/5] Verification de npm
echo ============================================================
echo.

where npm >nul 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] npm est introuvable.
    echo.
    echo Reinstallez Node.js LTS.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('npm --version') do set "NPM_VERSION=%%v"

echo npm detecte : !NPM_VERSION!
echo.

:: ============================================================
:: ETAPE 3 - BACKEND
:: ============================================================

echo ============================================================
echo [3/5] Installation du backend
echo ============================================================
echo.

if not exist "%BACKEND_DIR%\package.json" (
    echo [ERREUR] package.json du backend introuvable.
    echo.
    echo Chemin attendu :
    echo %BACKEND_DIR%\package.json
    echo.
    pause
    exit /b 1
)

cd /d "%BACKEND_DIR%"

if exist "package-lock.json" (
    echo package-lock.json detecte.
    echo Utilisation de npm ci...
    echo.

    call npm ci

    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo [ERREUR] Installation du backend echouee.
        echo.
        pause
        exit /b 1
    )
) else (
    echo package-lock.json absent.
    echo Utilisation de npm install...
    echo.

    call npm install

    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo [ERREUR] Installation du backend echouee.
        echo.
        pause
        exit /b 1
    )
)

echo.
echo Backend installe avec succes.
echo.

:: ============================================================
:: ETAPE 4 - FRONTEND
:: ============================================================

echo ============================================================
echo [4/5] Installation du frontend
echo ============================================================
echo.

if not exist "%FRONTEND_DIR%\package.json" (
    echo [ERREUR] package.json du frontend introuvable.
    echo.
    echo Chemin attendu :
    echo %FRONTEND_DIR%\package.json
    echo.
    pause
    exit /b 1
)

cd /d "%FRONTEND_DIR%"

if exist "package-lock.json" (
    echo package-lock.json detecte.
    echo Utilisation de npm ci...
    echo.

    call npm ci

    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo [ERREUR] Installation du frontend echouee.
        echo.
        pause
        exit /b 1
    )
) else (
    echo package-lock.json absent.
    echo Utilisation de npm install...
    echo.

    call npm install

    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo [ERREUR] Installation du frontend echouee.
        echo.
        pause
        exit /b 1
    )
)

echo.
echo Frontend installe avec succes.
echo.

:: ============================================================
:: ETAPE 5 - RACCOURCI BUREAU
:: ============================================================

echo ============================================================
echo [5/5] Creation du raccourci Bureau
echo ============================================================
echo.

set "START_BAT=%WINDOWS_DIR%start.bat"
set "ICON=%SystemRoot%\System32\shell32.dll,13"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell;" ^
  "$desktop = [Environment]::GetFolderPath('Desktop');" ^
  "$lnk = $ws.CreateShortcut((Join-Path $desktop 'Consolidation Balance.lnk'));" ^
  "$lnk.TargetPath = 'cmd.exe';" ^
  "$lnk.Arguments = '/c ""%START_BAT%""';" ^
  "$lnk.WorkingDirectory = '%WINDOWS_DIR%';" ^
  "$lnk.IconLocation = '%ICON%';" ^
  "$lnk.Description = 'Demarrer Consolidation Balance';" ^
  "$lnk.Save();"

if !ERRORLEVEL! EQU 0 (
    echo Raccourci cree avec succes.
) else (
    echo [AVERTISSEMENT] Impossible de creer le raccourci.
    echo Vous pouvez lancer start.bat manuellement.
)

echo.
echo ============================================================
echo       INSTALLATION TERMINEE AVEC SUCCES
echo ============================================================
echo.
echo Un raccourci "Consolidation Balance" a ete cree
echo sur le Bureau.
echo.
echo Double-cliquez dessus pour demarrer l'application.
echo.

pause

endlocal
exit /b 0
