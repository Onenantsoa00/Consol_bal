@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

title Consolidation Balance

:: ============================================================
:: CHEMINS
:: ============================================================

set "WINDOWS_DIR=%~dp0"
set "PROJECT_DIR=%WINDOWS_DIR%.."
set "BACKEND_DIR=%PROJECT_DIR%\excel-consolidator-backend"
set "FRONTEND_DIR=%PROJECT_DIR%\excel-consolidator-frontend"

set "BACKEND_LOG=%WINDOWS_DIR%backend.log"
set "FRONTEND_LOG=%WINDOWS_DIR%frontend.log"

echo.
echo ============================================================
echo       CONSOLIDATION BALANCE
echo ============================================================
echo.

:: ============================================================
:: VERIFICATION DES DOSSIERS
:: ============================================================

if not exist "%BACKEND_DIR%\package.json" (
    echo [ERREUR] Backend introuvable.
    echo.
    echo Dossier recherche :
    echo %BACKEND_DIR%
    echo.
    pause
    exit /b 1
)

if not exist "%FRONTEND_DIR%\package.json" (
    echo [ERREUR] Frontend introuvable.
    echo.
    echo Dossier recherche :
    echo %FRONTEND_DIR%
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: VERIFICATION NODE.JS
:: ============================================================

where node >nul 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Node.js n'est pas installe.
    echo.
    echo Lancez d'abord install.bat.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('node --version') do (
    echo Node.js : %%v
)

echo.

:: ============================================================
:: VERIFICATION NPM
:: ============================================================

where npm >nul 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] npm est introuvable.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: VERIFICATION NODE_MODULES
:: ============================================================

if not exist "%BACKEND_DIR%\node_modules" (
    echo [ERREUR] Dependances backend absentes.
    echo.
    echo Lancez d'abord install.bat.
    echo.
    pause
    exit /b 1
)

if not exist "%FRONTEND_DIR%\node_modules" (
    echo [ERREUR] Dependances frontend absentes.
    echo.
    echo Lancez d'abord install.bat.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: BACKEND
:: ============================================================

echo ============================================================
echo [1/2] Demarrage du backend
echo ============================================================
echo.

netstat -ano | findstr ":3000" | findstr "LISTENING" >nul 2>nul

if %ERRORLEVEL% EQU 0 (
    echo Backend deja actif sur le port 3000.
) else (
    echo Demarrage du serveur Node.js...

    if exist "%BACKEND_LOG%" del /q "%BACKEND_LOG%" >nul 2>nul

    start "Backend-Consol" /min /D "%BACKEND_DIR%" "%ComSpec%" /c "npm start > "%BACKEND_LOG%" 2>&1"

    echo Attente du backend...

    set "BACKEND_READY=0"

    for /L %%i in (1,1,30) do (
        timeout /t 1 /nobreak >nul

        netstat -ano | findstr ":3000" | findstr "LISTENING" >nul 2>nul

        if !ERRORLEVEL! EQU 0 (
            set "BACKEND_READY=1"
            goto BACKEND_READY
        )

        echo     Attente %%i/30...
    )

    :BACKEND_READY

    if "!BACKEND_READY!"=="0" (
        echo.
        echo ============================================================
        echo [ERREUR] Le backend n'a pas demarre.
        echo ============================================================
        echo.
        echo Consultez le fichier :
        echo %BACKEND_LOG%
        echo.
        if exist "%BACKEND_LOG%" (
            echo ---------------- ERREUR BACKEND ----------------
            type "%BACKEND_LOG%"
            echo ------------------------------------------------
        )
        echo.
        pause
        exit /b 1
    )

    echo Backend demarre sur http://localhost:3000
)

echo.

:: ============================================================
:: FRONTEND
:: ============================================================

echo ============================================================
echo [2/2] Demarrage du frontend
echo ============================================================
echo.

netstat -ano | findstr ":5173" | findstr "LISTENING" >nul 2>nul

if %ERRORLEVEL% EQU 0 (
    echo Frontend deja actif sur le port 5173.
) else (
    echo Demarrage de Vite...

    if exist "%FRONTEND_LOG%" del /q "%FRONTEND_LOG%" >nul 2>nul

    start "Frontend-Consol" /min /D "%FRONTEND_DIR%" "%ComSpec%" /c "npm run dev > "%FRONTEND_LOG%" 2>&1"

    echo Attente du frontend...

    set "FRONTEND_READY=0"

    for /L %%i in (1,1,60) do (
        timeout /t 1 /nobreak >nul

        netstat -ano | findstr ":5173" | findstr "LISTENING" >nul 2>nul

        if !ERRORLEVEL! EQU 0 (
            set "FRONTEND_READY=1"
            goto FRONTEND_READY
        )

        echo     Attente %%i/60...
    )

    :FRONTEND_READY

    if "!FRONTEND_READY!"=="0" (
        echo.
        echo ============================================================
        echo [ERREUR] Le frontend n'a pas demarre.
        echo ============================================================
        echo.
        echo Consultez le fichier :
        echo %FRONTEND_LOG%
        echo.
        if exist "%FRONTEND_LOG%" (
            echo ---------------- ERREUR FRONTEND ----------------
            type "%FRONTEND_LOG%"
            echo -------------------------------------------------
        )
        echo.
        pause
        exit /b 1
    )

    echo Frontend demarre sur http://localhost:5173
)

:: ============================================================
:: OUVERTURE DU NAVIGATEUR
:: ============================================================

echo.
echo ============================================================
echo       APPLICATION PRETE
echo ============================================================
echo.
echo Backend  : http://localhost:3000/
echo Frontend : http://localhost:5173/
echo.

echo Ouverture du navigateur...

start "" "http://localhost:5173/"

echo.
echo Le navigateur devrait maintenant s'ouvrir.
echo.
echo Pour arreter l'application :
echo double-cliquez sur stop.bat
echo.

timeout /t 5 /nobreak >nul

endlocal
exit /b 0
