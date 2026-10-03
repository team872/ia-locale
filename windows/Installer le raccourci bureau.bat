@echo off
title IA Locale - Installation du raccourci bureau
chcp 65001 > nul
cd /d "%~dp0"

echo.
echo Creation du raccourci "IA Locale" sur le bureau...
echo.

rem WindowStyle 7 = fenetre de demarrage reduite : on voit l'interface, pas la console.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ws = New-Object -ComObject WScript.Shell;" ^
    "$lnk = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\IA Locale.lnk');" ^
    "$lnk.TargetPath = '%CD%\IA Locale.bat';" ^
    "$lnk.IconLocation = '%CD%\icon.ico';" ^
    "$lnk.WorkingDirectory = '%CD%';" ^
    "$lnk.WindowStyle = 7;" ^
    "$lnk.Description = 'IA Locale - une IA qui tourne sur votre ordinateur';" ^
    "$lnk.Save()"

if errorlevel 1 (
    echo X Erreur lors de la creation du raccourci.
) else (
    echo OK Raccourci "IA Locale" cree sur le bureau.
    echo.
    echo Vous pouvez maintenant double-cliquer dessus pour lancer l'application.
)
echo.
pause
