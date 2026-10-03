; Script Inno Setup pour générer un installeur Windows "IA Locale Setup.exe"
; Pré-requis : Inno Setup (gratuit) — https://jrsoftware.org/isinfo.php
; Compilation : ouvrir ce fichier dans Inno Setup, appuyer sur F9.
; Ce script s'exécute depuis le dossier windows/ du dépôt : l'interface est prise dans ..\app.

[Setup]
AppId={{B4F9A20E-3D17-4A0A-9E12-IALOCALE0001}
AppName=IA Locale
AppVersion=1.2.0
AppPublisher=3h33
AppPublisherURL=https://ia-magique.com/app-IA-locale/
DefaultDirName={autopf}\IA Locale
DefaultGroupName=IA Locale
DisableProgramGroupPage=yes
OutputBaseFilename=IA Locale Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\icon.ico
ArchitecturesAllowed=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Files]
Source: "IA Locale.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "serveur.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\app\IA-Locale.html"; DestDir: "{app}\app"; Flags: ignoreversion
Source: "..\app\lib\*"; DestDir: "{app}\app\lib"; Flags: ignoreversion
Source: "..\app\LISEZ-MOI.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[InstallDelete]
; Restes de la version 1.1 (lanceur VBScript, interface à la racine)
Type: files; Name: "{app}\IA Locale.vbs"
Type: files; Name: "{app}\launcher.bat"
Type: files; Name: "{app}\IA-Profs.html"

[Icons]
Name: "{group}\IA Locale"; Filename: "{app}\IA Locale.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Flags: runminimized
Name: "{userdesktop}\IA Locale"; Filename: "{app}\IA Locale.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Flags: runminimized; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le bureau"; GroupDescription: "Raccourcis :"

[Run]
Filename: "{app}\IA Locale.bat"; Description: "Lancer IA Locale"; Flags: nowait postinstall skipifsilent runminimized
