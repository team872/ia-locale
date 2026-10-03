# Journal des versions

## 1.2.0 — 4 octobre 2026

**Sécurité**
- Le lanceur ne règle plus `OLLAMA_ORIGINS="*"`, qui ouvrait Ollama à tous les sites web. L'interface
  est servie par un mini-serveur local sur `http://127.0.0.1:11500`, accepté par Ollama sans réglage.
  Le lanceur annule le réglage laissé par la 1.1.
- Windows : le lanceur VBScript (technologie que Microsoft retire) est remplacé par `IA Locale.bat`.

**Corrections**
- Anonymisation : les prénoms accentués (Chloé, Élise…) n'étaient jamais masqués ; liste portée à
  ~500 prénoms ; noms de famille masqués ; plus de faux positifs sur Victor Hugo ou Louis XIV ; et
  surtout l'historique de la conversation repartait EN CLAIR au deuxième message.
- Mode cloud : les cinq modèles gratuits proposés n'existaient plus ; la liste est désormais lue chez
  OpenRouter.
- PDF : pdf.js est inclus, la lecture marche hors ligne et n'appelle plus de CDN.
- macOS 15 et plus : consigne « Ouvrir quand même » à jour.

**Nouveautés**
- Onglet Modèles : installer, choisir, supprimer un modèle en un clic, avec barre de progression.
  Catalogue renouvelé (Ministral 3, Gemma 4, Qwen 3.5, Granite 4.2, gpt-oss, Mistral Small 3.2…).
- Photos : les modèles qui lisent les images reçoivent la photo jointe (glisser, coller, 📎).
- Bibliothèque : formulaires guidés pour les prompts à trous, recherche, catégories, « Mes prompts ».
- Chat : Arrêter (ou Échap), Régénérer, suites rapides, impression, tableaux et formules lisibles,
  exemples cliquables, recherche et renommage des conversations.
- Sauvegarde : export complet et import (pour récupérer les conversations de la 1.1).

## 1.1.1

Dernière version distribuée avec `OLLAMA_ORIGINS="*"`.
