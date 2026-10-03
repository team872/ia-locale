@echo off
setlocal
chcp 65001 > nul
title IA Locale - Demarrage
cd /d "%~dp0"

rem IA Locale - lanceur Windows
rem  1. verifie qu'Ollama est installe ;
rem  2. defait le reglage dangereux de la version 1.1 (OLLAMA_ORIGINS="*") ;
rem  3. demarre Ollama s'il ne repond pas ;
rem  4. demarre le mini-serveur local de l'interface (http://127.0.0.1:11500) ;
rem  5. telecharge le modele par defaut au premier lancement ;
rem  6. ouvre l'interface dans le navigateur.

set "RACINE=%~dp0app"
set "PORT=11500"
set "ADRESSE=http://127.0.0.1:%PORT%"
set "OLLAMA=http://127.0.0.1:11434"
set "OLLAMA_EXE=ollama"
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" set "OLLAMA_EXE=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"

echo.
echo  IA Locale - demarrage
echo  ---------------------
echo.

rem --- 1. Ollama installe ? ---------------------------------------------------
where ollama > nul 2>&1
if errorlevel 1 if not exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    echo  Ollama n'est pas encore installe.
    echo  La page de telechargement va s'ouvrir : installez Ollama pour Windows,
    echo  puis relancez IA Locale.
    timeout /t 4 > nul
    start "" https://ollama.com/download
    pause
    exit /b 0
)

rem --- 2. Defaire le reglage de la version 1.1 --------------------------------
rem OLLAMA_ORIGINS="*" autorisait n'importe quel site web a piloter Ollama.
set "REDEMARRER="
for /f "tokens=3" %%v in ('reg query "HKCU\Environment" /v OLLAMA_ORIGINS 2^>nul ^| findstr /i "OLLAMA_ORIGINS"') do (
    if "%%v"=="*" (
        reg delete "HKCU\Environment" /v OLLAMA_ORIGINS /f > nul 2>&1
        set "REDEMARRER=1"
    )
)
rem Cette fenetre peut encore heriter de l'ancienne valeur : on l'efface pour Ollama.
set "OLLAMA_ORIGINS="
if defined REDEMARRER (
    echo  Mise a jour de securite : redemarrage d'Ollama...
    taskkill /IM "ollama app.exe" /F > nul 2>&1
    taskkill /IM ollama.exe /F > nul 2>&1
    timeout /t 2 > nul
)

rem --- 3. Ollama doit repondre ------------------------------------------------
curl -s --max-time 2 %OLLAMA%/api/tags > nul 2>&1
if errorlevel 1 (
    echo  Demarrage d'Ollama...
    if exist "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe" (
        start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"
    ) else (
        start "Ollama" /min "%OLLAMA_EXE%" serve
    )
    for /L %%i in (1,1,20) do (
        curl -s --max-time 2 %OLLAMA%/api/tags > nul 2>&1 && goto :ollama_ok
        timeout /t 1 > nul
    )
)
:ollama_ok

rem --- 4. Mini-serveur de l'interface ----------------------------------------
rem Le serveur se presente par "ia-locale PID DOSSIER-SERVI". S'il sert une
rem autre copie de l'application (ancienne version installee ailleurs), on le remplace.
set "SRV_PID="
set "SRV_RACINE="
for /f "tokens=1,2,*" %%a in ('curl -s --max-time 2 %ADRESSE%/__ia-locale 2^>nul') do if "%%a"=="ia-locale" (
    set "SRV_PID=%%b"
    set "SRV_RACINE=%%c"
)
if not defined SRV_PID goto :lancer_serveur
if /i "%SRV_RACINE%"=="%RACINE%" goto :serveur_ok
taskkill /PID %SRV_PID% /F > nul 2>&1
timeout /t 1 > nul

:lancer_serveur
netstat -ano | findstr /r /c:"127.0.0.1:%PORT% .*LISTENING" /c:"0.0.0.0:%PORT% .*LISTENING" > nul
if not errorlevel 1 goto :port_occupe
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0serveur.ps1" -Racine "%RACINE%" -Port %PORT%
for /L %%i in (1,1,20) do (
    curl -s --max-time 1 %ADRESSE%/__ia-locale 2>nul | findstr /b "ia-locale" > nul && goto :serveur_ok
    timeout /t 1 > nul
)
echo  Le serveur de l'interface ne repond pas.
pause
exit /b 1

:port_occupe
echo.
echo  Le port %PORT% est deja utilise par un autre logiciel :
echo  IA Locale ne peut pas demarrer. Fermez ce logiciel puis relancez IA Locale.
pause
exit /b 1

:serveur_ok
        timeout /t 1 > nul
    )
    echo  Le serveur de l'interface ne repond pas.
    pause
    exit /b 1
)
:serveur_ok

rem --- 5. Modele par defaut au premier lancement ------------------------------
curl -s --max-time 3 %OLLAMA%/api/tags 2>nul | findstr /c:"llama3.2" > nul
if errorlevel 1 (
    echo.
    echo  Telechargement du modele llama3.2:3b - environ 2 Go, une seule fois.
    echo.
    "%OLLAMA_EXE%" pull llama3.2:3b
)

rem --- 6. Interface ------------------------------------------------------------
start "" "%ADRESSE%/"
exit /b 0
