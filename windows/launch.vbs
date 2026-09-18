' Lanceur silencieux pour Consolidation Balance
' Ce script VBS lance start.bat sans afficher de console noire

Set WshShell = CreateObject("WScript.Shell")
' 0 = fenetre cachee, False = ne pas attendre la fin
WshShell.Run """" & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\start.bat""", 0, False
Set WshShell = Nothing