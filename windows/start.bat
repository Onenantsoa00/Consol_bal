@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

title Consolidation Balance

echo.
echo ============================================================
echo       DEMARRAGE DE CONSOLIDATION BALANCE
echo ============================================================
echo.

:: ============================================================
:: CHEMINS
:: ============================================================

set "WINDOWS_DIR=%~dp0"
set "PROJECT_DIR=%WINDOWS_DIR%.."
set "BACKEND_DIR=%PROJECT_DIR%\excel-consolidator-backend"
set "FRONTEND_DIR=%PROJECT_DIR%\excel-consolidator-frontend"

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

:: ============================================================
:: VERIFICATION DES DEPENDANCES
:: ============================================================

if not exist "%BACKEND_DIR%\node_modules" (
    echo [ERREUR] Les dependances du backend ne sont pas installees.
    echo.
    echo Lancez d'abord install.bat.
    echo.
    pause
    exit /b 1
)

if not exist "%FRONTEND_DIR%\node_modules" (
    echo [ERREUR] Les dependances du frontend ne sont pas installees.
    echo.
    echo Lancez d'abord install.bat.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: BACKEND - PORT 3000
:: ============================================================

echo Verification du backend...

netstat -ano | findstr ":3000" | findstr "LISTENING" >nul 2>nul

if %ERRORLEVEL% EQU 0 (
    echo Backend deja actif sur le port 3000.
) else (
    echo Demarrage du backend...

    start "Backend-Consol" /min cmd /c "cd /d "%BACKEND_DIR%" && npm start"

    echo Attente du demarrage du backend...

    set "BACKEND_READY=0"

    for /L %%i in (1,1,30) do (
        timeout /t 1 /nobreak >nul

        netstat -ano | findstr ":3000" | findstr "LISTENING" >nul 2>nul

        if !ERRORLEVEL! EQU 0 (
            set "BACKEND_READY=1"
            goto BACKEND_OK
        )

        echo Attente... %%i/30
    )

    :BACKEND_OK

    if "!BACKEND_READY!"=="0" (
        echo.
        echo [ERREUR] Le backend ne repond pas sur le port 3000.
        echo.
        echo Verifiez la fenetre "Backend-Consol".
        echo.
        pause
        exit /b 1
    )

    echo Backend demarre avec succes.
)

echo.

:: ============================================================
:: FRONTEND - PORT 5173
:: ============================================================

echo Verification du frontend...

netstat -ano | findstr ":5173" | findstr "LISTENING" >nul 2>nul

if %ERRORLEVEL% EQU 0 (
    echo Frontend deja actif sur le port 5173.
) else (
    echo Demarrage du frontend...

    start "Frontend-Consol" /min cmd /c "cd /d "%FRONTEND_DIR%" && npm run dev"

    echo Attente du demarrage du frontend...

    set "FRONTEND_READY=0"

    for /L %%i in (1,1,60) do (
        timeout /t 1 /nobreak >nul

        netstat -ano | findstr ":5173" | findstr "LISTENING" >nul 2>nul

        if !ERRORLEVEL! EQU 0 (
            set "FRONTEND_READY=1"
            goto FRONTEND_OK
        )

        echo Attente... %%i/60
    )

    :FRONTEND_OK

    if "!FRONTEND_READY!"=="0" (
        echo.
        echo [ERREUR] Le frontend ne repond pas sur le port 5173.
        echo.
        echo Verifiez la fenetre "Frontend-Consol".
        echo.
        pause
        exit /b 1
    )

    echo Frontend demarre avec succes.
)

:: ============================================================
:: OUVERTURE DU NAVIGATEUR
:: ============================================================

echo.
echo Ouverture de l'application...

start "" "http://localhost:5173/"

echo.
echo ============================================================
echo       CONSOLIDATION BALANCE EST DEMARRE
echo ============================================================
echo.
echo Frontend : http://localhost:5173/
echo Backend  : http://localhost:3000/
echo.
echo Vous pouvez utiliser l'application.
echo.
echo Pour arreter l'application :
echo lancez windows\stop.bat
echo.

timeout /t 5 /nobreak >nul

endlocal
exit /b 0
