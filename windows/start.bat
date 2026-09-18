@echo off
chcp 65001 >nul
setlocal

title Consolidation Balance - En cours d'execution

echo ============================================================
echo    DEMARRAGE DE L'APPLICATION CONSOLIDATION BALANCE
echo ============================================================
echo.

:: Verifier que Node.js est present
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Node.js n'est pas installe.
    echo Lancez d'abord install.bat.
    pause
    exit /b 1
)

:: Verifier que les node_modules existent
if not exist "%~dp0..\excel-consolidator-backend\node_modules" (
    echo [ERREUR] Le backend n'est pas installe.
    echo Lancez d'abord install.bat.
    pause
    exit /b 1
)
if not exist "%~dp0..\excel-consolidator-frontend\node_modules" (
    echo [ERREUR] Le frontend n'est pas installe.
    echo Lancez d'abord install.bat.
    pause
    exit /b 1
)

:: =====================================================
:: Arreter toute instance existante
:: =====================================================
echo Nettoyage des anciennes instances...
taskkill /FI "WindowTitle eq Backend-Consol*" /T /F >nul 2>nul
taskkill /FI "WindowTitle eq Frontend-Consol*" /T /F >nul 2>nul
timeout /t 1 /nobreak >nul

:: =====================================================
:: Demarrer le BACKEND dans une nouvelle fenetre minimisée
:: =====================================================
echo Demarrage du BACKEND (port 3000)...
start "Backend-Consol" /min cmd /c "cd /d "%~dp0..\excel-consolidator-backend" && npm run dev"

:: Attendre que le backend demarre
timeout /t 3 /nobreak >nul

:: =====================================================
:: Demarrer le FRONTEND dans une nouvelle fenetre minimisée
:: =====================================================
echo Demarrage du FRONTEND (port 5173)...
start "Frontend-Consol" /min cmd /c "cd /d "%~dp0..\excel-consolidator-frontend" && npm run dev"

:: Attendre que Vite soit pret
echo Attente du demarrage du frontend...
timeout /t 8 /nobreak >nul

:: =====================================================
:: Ouvrir le navigateur
:: =====================================================
echo Ouverture du navigateur...
start "" "http://localhost:5173/"

:: =====================================================
:: Information utilisateur
:: =====================================================
echo.
echo ============================================================
echo    APPLICATION DEMARREE
echo ============================================================
echo.
echo    Frontend : http://localhost:5173/
echo    Backend  : http://localhost:3000/
echo.
echo    Pour ARRETER l'application, lancez stop.bat
echo    ou fermez les 2 fenetres minimisees "Backend-Consol"
echo    et "Frontend-Consol" dans la barre des taches.
echo.
echo Cette fenetre peut etre fermee.
timeout /t 10 /nobreak >nul
exit /b 0