@echo off
chcp 65001 >nul
title Creation du raccourci Bureau

echo Creation du raccourci "Consolidation Balance" sur le Bureau...

:: Chemins absolus
set "SCRIPT_DIR=%~dp0"
set "LAUNCHER=%SCRIPT_DIR%launch.vbs"

:: Icone : on utilise une icone standard Windows (globe/terre)
set "ICON=%SystemRoot%\System32\shell32.dll,13"

:: Creer le raccourci via PowerShell (methode fiable)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell;" ^
  "$desktop = [Environment]::GetFolderPath('Desktop');" ^
  "$lnk = $ws.CreateShortcut(\"$desktop\Consolidation Balance.lnk\");" ^
  "$lnk.TargetPath = 'wscript.exe';" ^
  "$lnk.Arguments = '\"%LAUNCHER%\"';" ^
  "$lnk.WorkingDirectory = '%SCRIPT_DIR%';" ^
  "$lnk.IconLocation = '%ICON%';" ^
  "$lnk.Description = 'Lancer l application Consolidation Balance';" ^
  "$lnk.Save();"

if %ERRORLEVEL% EQU 0 (
    echo    Raccourci cree sur le Bureau : "Consolidation Balance"
) else (
    echo    [AVERTISSEMENT] Echec de la creation du raccourci.
    echo    Vous pouvez toujours lancer manuellement start.bat.
)

exit /b 0