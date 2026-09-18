@echo off
setlocal

title Consolidation Balance - Arret

echo.
echo ============================================================
echo       ARRET DE CONSOLIDATION BALANCE
echo ============================================================
echo.

REM ------------------------------------------------------------
REM Arret des fenetres Node.js
REM ------------------------------------------------------------

echo Arret du backend...

taskkill /FI "WINDOWTITLE eq Consolidation Balance - Backend*" /T /F >nul 2>nul

echo Arret du frontend...

taskkill /FI "WINDOWTITLE eq Consolidation Balance - Frontend*" /T /F >nul 2>nul

REM ------------------------------------------------------------
REM Liberation du port 3000
REM ------------------------------------------------------------

echo.
echo Liberation du port 3000...

for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%P >nul 2>nul
)

REM ------------------------------------------------------------
REM Liberation du port 5173
REM ------------------------------------------------------------

echo Liberation du port 5173...

for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":5173" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%P >nul 2>nul
)

echo.
echo ============================================================
echo       APPLICATION ARRETEE
echo ============================================================
echo.

timeout /t 2 /nobreak >nul

endlocal
exit /b 0
