@echo off
chcp 65001 >nul

title Arret - Consolidation Balance

echo.
echo ============================================================
echo       ARRET DE CONSOLIDATION BALANCE
echo ============================================================
echo.

echo Arret du backend...

taskkill /FI "WindowTitle eq Backend-Consol*" /T /F >nul 2>nul

echo Arret du frontend...

taskkill /FI "WindowTitle eq Frontend-Consol*" /T /F >nul 2>nul

echo.
echo Liberation du port 3000...

for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>nul
)

echo Liberation du port 5173...

for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":5173" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>nul
)

echo.
echo ============================================================
echo       APPLICATION ARRETEE
echo ============================================================
echo.

timeout /t 3 /nobreak >nul

exit /b 0
