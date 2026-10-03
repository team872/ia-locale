# IA Locale

Une IA qui tourne **sur votre ordinateur**, pour les métiers où la confidentialité n'est pas
optionnelle : enseignement, santé, droit, travail social. En mode local (par défaut), vos textes
ne quittent pas la machine. Gratuit, logiciel libre (licence MIT), édité par 3h33.

Page de présentation et téléchargements : <https://ia-magique.com/app-IA-locale/>

## Ce que c'est

Une seule page web (`app/IA-Locale.html`, HTML/CSS/JS sans dépendance en ligne) qui parle au
moteur libre [Ollama](https://ollama.com) installé sur l'ordinateur, plus un lanceur par système :

| Dossier | Contenu |
|---|---|
| `app/` | l'interface, et `lib/` : pdf.js (Mozilla, Apache 2.0) pour lire les PDF hors ligne |
| `mac/IA Locale.app/` | lanceur macOS (script bash) et `serveur.pl`, le mini-serveur local |
| `windows/` | lanceur `IA Locale.bat`, mini-serveur `serveur.ps1`, raccourci bureau, script Inno Setup |
| `tests/` | tests de l'anonymisation (`node tests/anonymisation.test.mjs`) |
| `construire.sh` | fabrique `dist/IA-Locale-Mac.zip` et `dist/IA-Locale-Windows.zip` |

Fonctions : chat en streaming avec bouton Arrêter et Régénérer, suites rapides (plus court, plus
simple, en tableau…), bibliothèque de prompts pédagogiques avec formulaires guidés et « Mes
prompts », installation et suppression des modèles en un clic, lecture de photos par les modèles
qui le savent, lecture des PDF, anonymisation des élèves, export Word / Markdown / impression,
recherche dans les conversations, sauvegarde et import. Mode cloud OpenRouter optionnel, désactivé
par défaut.

## Pourquoi un mini-serveur local

Ouverte comme simple fichier (`file://`), la page envoie l'en-tête `Origin: null`, qu'Ollama
refuse. La version 1.1 contournait ce refus en réglant `OLLAMA_ORIGINS="*"` — ce qui permettait à
**n'importe quel site web** visité ensuite de piloter l'Ollama de l'utilisateur (lancer des
calculs, télécharger ou effacer des modèles). Vérifié le 03/10/2026 sur Ollama 0.35 : avec `*`,
un site tiers obtient `Access-Control-Allow-Origin: *`, y compris pour `DELETE /api/delete`.

Depuis la 1.2, le lanceur sert l'interface sur `http://127.0.0.1:11500`, origine qu'Ollama
accepte **par défaut** : aucun réglage d'Ollama n'est modifié. Le lanceur annule même
`OLLAMA_ORIGINS="*"` s'il le trouve, et redémarre Ollama pour que ce soit effectif.

Le mini-serveur (Perl sur Mac, PowerShell sur Windows — tous deux présents d'origine) :
- n'écoute que sur `127.0.0.1`, injoignable depuis le réseau ;
- ne sert qu'une liste fermée de quatre fichiers, en `GET`/`HEAD` seulement ;
- s'arrête seul après 8 h sans requête ;
- répond à `/__ia-locale` par `ia-locale <pid> <dossier servi>`, ce qui permet au lanceur de
  remplacer le serveur d'une autre copie de l'application (ancienne version installée ailleurs).

⚠️ Les conversations sont gardées dans le navigateur, **par adresse**. Passer de `file://` (1.1)
à `http://127.0.0.1:11500` (1.2) ne les montre plus : d'où l'export (1.1) puis l'import (1.2).
Ne pas changer le port 11500 à la légère, pour la même raison.

## Fabriquer une version

1. Modifier `app/IA-Locale.html` (la seule source de l'interface).
2. Pour une nouvelle version : changer `VERSION` dans la page, `Info.plist` et `windows/IA Locale.iss`
   (le script refuse de construire s'ils divergent).
3. `./construire.sh` — lance les tests, puis produit les deux ZIP dans `dist/`.
4. Copier les ZIP dans le dépôt `team872/ia-magique-com` (`app-IA-locale/`), qui les publie.

## Vérifié, et ce qui ne l'est pas

Vérifié le 03-04/10/2026 sur macOS 26 avec Ollama 0.35 : envoi et streaming, arrêt, régénération,
anonymisation de bout en bout (le modèle ne reçoit que « Élève A »), lecture d'une image par un
modèle vision, lecture d'un PDF sans requête externe, installation et suppression d'un modèle,
import/export, les deux mini-serveurs (le PowerShell avec PowerShell 7 sur Mac).

**Pas encore vérifié sur un vrai PC Windows** : le lanceur `IA Locale.bat` (démarrage d'Ollama,
lancement du serveur en arrière-plan, nettoyage de `OLLAMA_ORIGINS`), et le serveur sous
Windows PowerShell 5.1.

## Catalogue des modèles

`CATALOGUE` dans `app/IA-Locale.html`. Chaque entrée a été vérifiée dans la bibliothèque officielle
d'Ollama (le manifeste existe, et la taille annoncée est la somme réelle des couches) — relevé du
04/10/2026. Pour vérifier un modèle avant de l'ajouter :

```bash
curl -s -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
  https://registry.ollama.ai/v2/library/ministral-3/manifests/3b
```
