#!/bin/bash
# Fabrique les deux paquets téléchargeables dans dist/ :
#   IA-Locale-Mac.zip      — « IA Locale.app » + LISEZ-MOI + LICENSE
#   IA-Locale-Windows.zip  — dossier « IA Locale » + LISEZ-MOI + LICENSE
# L'interface (app/) est copiée dans chaque paquet : c'est la seule source à modifier.
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(grep -o "const VERSION = '[^']*'" app/IA-Locale.html | cut -d"'" -f2)
grep -q "<string>$VERSION</string>" "mac/IA Locale.app/Contents/Info.plist" \
  || { echo "Info.plist n'annonce pas la version $VERSION" >&2; exit 1; }
grep -q "AppVersion=$VERSION" "windows/IA Locale.iss" \
  || { echo "IA Locale.iss n'annonce pas la version $VERSION" >&2; exit 1; }
node tests/anonymisation.test.mjs

TRAVAIL=$(mktemp -d)
trap 'rm -rf "$TRAVAIL"' EXIT
mkdir -p dist

# --- Mac ---
mkdir -p "$TRAVAIL/mac"
cp -R "mac/IA Locale.app" "$TRAVAIL/mac/"
mkdir -p "$TRAVAIL/mac/IA Locale.app/Contents/Resources/app"
cp -R app/IA-Locale.html app/lib "$TRAVAIL/mac/IA Locale.app/Contents/Resources/app/"
cp app/LISEZ-MOI.txt LICENSE "$TRAVAIL/mac/"
chmod +x "$TRAVAIL/mac/IA Locale.app/Contents/MacOS/IA-Locale" "$TRAVAIL/mac/IA Locale.app/Contents/Resources/serveur.pl"
find "$TRAVAIL" -name .DS_Store -delete
rm -f dist/IA-Locale-Mac.zip
( cd "$TRAVAIL/mac" && ditto -c -k --norsrc --noextattr . "$OLDPWD/dist/IA-Locale-Mac.zip" )

# --- Windows ---
mkdir -p "$TRAVAIL/win/IA Locale"
cp "windows/IA Locale.bat" windows/serveur.ps1 "windows/Installer le raccourci bureau.bat" windows/icon.ico \
   "$TRAVAIL/win/IA Locale/"
cp -R app/IA-Locale.html app/lib "$TRAVAIL/win/IA Locale/" 2>/dev/null || true
mkdir -p "$TRAVAIL/win/IA Locale/app" && mv "$TRAVAIL/win/IA Locale/IA-Locale.html" "$TRAVAIL/win/IA Locale/lib" "$TRAVAIL/win/IA Locale/app/"
cp app/LISEZ-MOI.txt LICENSE "$TRAVAIL/win/"
rm -f dist/IA-Locale-Windows.zip
( cd "$TRAVAIL/win" && zip -qrX "$OLDPWD/dist/IA-Locale-Windows.zip" . )

echo "Version $VERSION :"
ls -l dist/*.zip | awk '{print "  " $5 " octets  " $9}'
