@echo off
chcp 65001 >nul
echo Suppression du raccourci Bureau...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$desktop = [Environment]::GetFolderPath('Desktop');" ^
  "$lnk = Join-Path $desktop 'Consolidation Balance.lnk';" ^
  "if (Test-Path $lnk) { Remove-Item $lnk -Force; Write-Host '    Raccourci supprime.' } else { Write-Host '    Aucun raccourci a supprimer.' }"

timeout /t 2 /nobreak >nul
exit /b 0