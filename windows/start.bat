@echo off
setlocal

title Consolidation Balance

REM ============================================================
REM CONSOLIDATION BALANCE - DEMARRAGE
REM ============================================================

set "WINDOWS_DIR=%~dp0"
set "PROJECT_DIR=%WINDOWS_DIR%.."
set "BACKEND_DIR=%PROJECT_DIR%\excel-consolidator-backend"
set "FRONTEND_DIR=%PROJECT_DIR%\excel-consolidator-frontend"

echo.
echo ============================================================
echo          CONSOLIDATION BALANCE
echo ============================================================
echo.

REM ------------------------------------------------------------
REM Verification des dossiers
REM ------------------------------------------------------------

if not exist "%BACKEND_DIR%\package.json" (
    echo [ERREUR] Backend introuvable.
    echo.
    echo %BACKEND_DIR%
    echo.
    pause
    exit /b 1
)

if not exist "%FRONTEND_DIR%\package.json" (
    echo [ERREUR] Frontend introuvable.
    echo.
    echo %FRONTEND_DIR%
    echo.
    pause
    exit /b 1
)

REM ------------------------------------------------------------
REM Verification de Node.js
REM ------------------------------------------------------------

where node >nul 2>nul

if errorlevel 1 (
    echo [ERREUR] Node.js n'est pas installe.
    echo.
    echo Lancez install.bat.
    echo.
    pause
    exit /b 1
)

REM ------------------------------------------------------------
REM Verification des dependances
REM ------------------------------------------------------------

if not exist "%BACKEND_DIR%\node_modules" (
    echo [ERREUR] Les dependances du backend sont absentes.
    echo.
    echo Lancez install.bat.
    echo.
    pause
    exit /b 1
)

if not exist "%FRONTEND_DIR%\node_modules" (
    echo [ERREUR] Les dependances du frontend sont absentes.
    echo.
    echo Lancez install.bat.
    echo.
    pause
    exit /b 1
)

REM ------------------------------------------------------------
REM Verification des ports
REM ------------------------------------------------------------

echo Verification du backend...

netstat -ano | findstr /R /C:":3000 .*LISTENING" >nul 2>nul

if not errorlevel 1 (
    echo Backend deja demarre sur le port 3000.
) else (
    echo Demarrage du backend...

    start "Consolidation Balance - Backend" /min cmd /k "cd /d ""%BACKEND_DIR%"" && npm start"
)

REM ------------------------------------------------------------

echo.
echo Verification du frontend...

netstat -ano | findstr /R /C:":5173 .*LISTENING" >nul 2>nul

if not errorlevel 1 (
    echo Frontend deja demarre sur le port 5173.
) else (
    echo Demarrage du frontend...

    start "Consolidation Balance - Frontend" /min cmd /k "cd /d ""%FRONTEND_DIR%"" && npm run dev"
)

REM ------------------------------------------------------------
REM Attente du demarrage
REM ------------------------------------------------------------

echo.
echo Attente du demarrage de l'application...

timeout /t 8 /nobreak >nul

REM ------------------------------------------------------------
REM Ouverture du navigateur
REM ------------------------------------------------------------

echo.
echo Ouverture de Consolidation Balance...
echo.

start "" "http://localhost:5173/"

echo.
echo ============================================================
echo          APPLICATION DEMARREE
echo ============================================================
echo.
echo Frontend : http://localhost:5173
echo Backend  : http://localhost:3000
echo.
echo Vous pouvez fermer cette fenetre.
echo.
echo Pour arreter l'application, utilisez stop.bat.
echo.

timeout /t 3 /nobreak >nul

endlocal
exit /b 0
