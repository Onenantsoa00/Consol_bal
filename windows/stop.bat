@echo off
chcp 65001 >nul
title Arret - Consolidation Balance

echo ============================================================
echo    ARRET DE L'APPLICATION CONSOLIDATION BALANCE
echo ============================================================
echo.

echo Arret du BACKEND...
taskkill /FI "WindowTitle eq Backend-Consol*" /T /F >nul 2>nul
if %ERRORLEVEL% EQU 0 (echo    Backend arrete.) else (echo    Backend non actif.)

echo Arret du FRONTEND...
taskkill /FI "WindowTitle eq Frontend-Consol*" /T /F >nul 2>nul
if %ERRORLEVEL% EQU 0 (echo    Frontend arrete.) else (echo    Frontend non actif.)

echo.
echo Liberation des ports 3000 et 5173...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":3000" ^| find "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>nul
)
for /f "tokens=5" %%a in ('netstat -aon ^| find ":5173" ^| find "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>nul
)

echo.
echo ============================================================
echo    APPLICATION ARRETEE
echo ============================================================
echo.
timeout /t 3 /nobreak >nul
exit /b 0