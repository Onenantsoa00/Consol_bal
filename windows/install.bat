@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

title Installation - Consolidation Balance
color 0A

echo ============================================================
echo    INSTALLATION DE L'APPLICATION CONSOLIDATION BALANCE
echo ============================================================
echo.

:: =====================================================
:: ETAPE 1 : Verification de Node.js
:: =====================================================
echo [1/5] Verification de Node.js...
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo     Node.js n'est pas installe.
    echo     Tentative d'installation automatique via winget...
    echo.

    where winget >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo [ERREUR] winget n'est pas disponible sur ce PC.
        echo.
        echo Veuillez installer manuellement Node.js LTS depuis :
        echo     https://nodejs.org/fr/download
        echo Puis relancez ce fichier install.bat.
        echo.
        pause
        exit /b 1
    )

    winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    if %ERRORLEVEL% NEQ 0 (
        echo [ERREUR] L'installation automatique de Node.js a echoue.
        echo Installez Node.js manuellement : https://nodejs.org/fr/download
        pause
        exit /b 1
    )

    echo.
    echo Node.js vient d'etre installe.
    echo IMPORTANT : fermez cette fenetre et relancez install.bat
    echo             pour que le PATH soit actualise.
    echo.
    pause
    exit /b 0
)

for /f "tokens=*" %%v in ('node --version') do set NODE_VERSION=%%v
echo     Node.js detecte : %NODE_VERSION%
echo.

:: =====================================================
:: ETAPE 2 : Verification de npm
:: =====================================================
echo [2/5] Verification de npm...
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] npm est introuvable.
    echo Reinstallez Node.js depuis https://nodejs.org/fr/download
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('npm --version') do set NPM_VERSION=%%v
echo     npm detecte : %NPM_VERSION%
echo.

:: =====================================================
:: ETAPE 3 : Installation des dependances BACKEND
:: =====================================================
echo [3/5] Installation des dependances du BACKEND...
cd /d "%~dp0..\excel-consolidator-backend"
if not exist "package.json" (
    echo [ERREUR] package.json introuvable dans excel-consolidator-backend
    pause
    exit /b 1
)
if not exist "node_modules" (
    echo     Installation en cours... (peut prendre 1-2 minutes)
    call npm install
    if !ERRORLEVEL! NEQ 0 (
        echo [ERREUR] Echec de npm install dans le backend.
        pause
        exit /b 1
    )
) else (
    echo     Dependances deja installees, verification...
    call npm install --silent
)
echo     Backend : OK
echo.

:: =====================================================
:: ETAPE 4 : Installation des dependances FRONTEND
:: =====================================================
echo [4/5] Installation des dependances du FRONTEND...
cd /d "%~dp0..\excel-consolidator-frontend"
if not exist "package.json" (
    echo [ERREUR] package.json introuvable dans excel-consolidator-frontend
    pause
    exit /b 1
)
if not exist "node_modules" (
    echo     Installation en cours... (peut prendre 1-2 minutes)
    call npm install
    if !ERRORLEVEL! NEQ 0 (
        echo [ERREUR] Echec de npm install dans le frontend.
        pause
        exit /b 1
    )
) else (
    echo     Dependances deja installees, verification...
    call npm install --silent
)
echo     Frontend : OK
echo.

:: =====================================================
:: ETAPE 5 : Creation du raccourci Bureau
:: =====================================================
echo [5/5] Creation du raccourci sur le Bureau...
call "%~dp0create-shortcut.bat"
echo.

echo ============================================================
echo    INSTALLATION TERMINEE AVEC SUCCES !
echo ============================================================
echo.
echo Un raccourci "Consolidation Balance" a ete cree sur votre Bureau.
echo Double-cliquez dessus pour demarrer l'application.
echo.
pause
endlocal