<p align="center">
  <img src="docs/screenshots/icon.png" width="128" alt="TreeScan Size icon">
</p>

<h1 align="center">TreeScan Size</h1>

<p align="center">
  <b>Voyez ce qui remplit votre Mac — sous forme d'arborescence de dossiers avec des barres de taille.</b><br>
  Gratuit et open source. Aucun réseau, aucun suivi. Comprend Dropbox, iCloud et OneDrive.
</p>

<p align="center">
  <a href="https://github.com/gorbarov/treescan-size/releases/latest"><img src="https://img.shields.io/github/v/release/gorbarov/treescan-size?label=download&color=2a78d6" alt="Download"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-lightgrey" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Apple%20Silicon-native-lightgrey" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/SwiftUI-100%25-orange" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT"></a>
  <img src="https://img.shields.io/badge/languages-9-blueviolet" alt="9 languages">
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.ru.md">Русский</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <b>Français</b> · <a href="README.pt-BR.md">Português</a> · <a href="README.ko.md">한국어</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a>
</p>

<p align="center">
  <img src="docs/screenshots/pie-en.png" width="900" alt="TreeScan Size: folder tree with size bars and a chart">
</p>

---

## Pourquoi

Finder ne peut pas vous dire quels dossiers ont englouti votre disque. La plupart des analyseurs de disque pour le Mac dessinent des anneaux ou des treemaps. **TreeScan Size affiche la vue que connaissent les utilisateurs de Windows avec TreeSize :** une simple arborescence de dossiers où chaque ligne possède une barre de taille et sa part du dossier parent. Faites défiler — et vous savez quoi nettoyer.

## Points forts

|  |  |
|---|---|
| 🌳 **Arborescence avec barres de taille** | Chaque dossier affiche sa taille et son % du parent, trié du plus gros au plus petit. Touches fléchées, clic n'importe où sur une ligne. |
| ⚡ **Analyse en direct** | L'arborescence se remplit pendant l'analyse, avec une vraie barre de progression (pourcentage de l'espace disque utilisé). Pas d'attente derrière un indicateur de chargement. |
| ☁️ **Compatible cloud** | Les fichiers « en ligne uniquement » de Dropbox, iCloud et OneDrive sont signalés : ils comptent dans votre forfait cloud mais n'occupent aucun espace sur le Mac. Marquez un dossier Dropbox **Ne pas synchroniser** directement depuis le menu. |
| ⚖️ **Taille vs Sur disque** | *Taille* correspond au poids des fichiers et à ce que comptent les quotas cloud. *Sur disque* correspond à ce qu'ils occupent réellement sur ce Mac. Un disque Docker ou de VM peut « peser » 460 Go et n'utiliser que 39 Go — vous voyez les deux. |
| 🔍 **Six vues** | Graphique, Détails, Extensions, Âge des fichiers, Top, Candidats en double (détectés sans télécharger les fichiers cloud). |
| 🛡️ **Sûr et privé** | Corbeille uniquement, avec confirmation ; les dossiers système sont protégés. Aucun accès réseau, aucune analyse, aucun compte. Voir [PRIVACY.md](PRIVACY.md). |
| 🌍 **9 langues** | English, 简体中文, 日本語, 한국어, Deutsch, Español, Français, Português, Русский. Thème clair et sombre. |

## Captures d'écran

| Analyse en direct | Top des fichiers | Candidats en double |
|---|---|---|
| <img src="docs/screenshots/live-en.png" alt="Live scan with progress"> | <img src="docs/screenshots/top-en.png" alt="Top files in a folder"> | <img src="docs/screenshots/duplicates-en.png" alt="Duplicate candidates"> |

| Que scanner ? | Thème sombre | Taille vs Sur disque, expliqué |
|---|---|---|
| <img src="docs/screenshots/welcome-en.png" alt="Start screen"> | <img src="docs/screenshots/details-dark-en.png" alt="Details, dark theme"> | <img src="docs/screenshots/mode-help-en.png" alt="Size vs On disk help"> |

## Installation

Nécessite **macOS 14 Sonoma ou ultérieur** sur **Apple Silicon**.

1. Téléchargez **TreeScan-Size.zip** depuis les [Releases](https://github.com/gorbarov/treescan-size/releases/latest), décompressez-le et déplacez l'app dans Applications.
2. La version **n'est pas encore notariée**, donc macOS bloque le premier lancement :
   - **macOS 15 et ultérieur :** ouvrez l'app une fois, cliquez sur *Terminé*, puis **Réglages Système → Confidentialité et sécurité → Ouvrir quand même**.
   - **macOS 14 :** faites un clic droit sur l'app → **Ouvrir** → **Ouvrir**.
   - Ou dans le Terminal : `xattr -dr com.apple.quarantine "/Applications/TreeScan Size.app"`
3. Au premier lancement, l'app demande l'**Accès complet au disque** — un seul interrupteur dans Réglages Système au lieu d'une dizaine d'invites macOS pour le Bureau, les Documents, iCloud et les données d'autres apps. Vous pouvez l'ignorer : les dossiers protégés sont alors simplement marqués 🔒 et non lus.

### Compiler depuis les sources

```bash
git clone https://github.com/gorbarov/treescan-size && cd treescan-size
scripts/make_app.sh          # Command Line Tools are enough (Swift 5.9+), no Xcode needed
open "build/TreeScan Size.app"
```

## Comparé aux autres outils

| | TreeScan Size | DaisyDisk | GrandPerspective | OmniDiskSweeper | Disk Inventory X |
|---|---|---|---|---|---|
| Vue principale | arborescence avec barres de taille + graphique | anneaux sunburst | treemap | liste en colonnes | treemap + liste |
| Prix | gratuit | payant | gratuit (payant sur l'App Store) | gratuit | gratuit |
| Code source | ouvert, MIT | fermé | ouvert, GPL | fermé | ouvert, GPL |

En plus : fichiers cloud « en ligne uniquement » signalés, « Ne pas synchroniser » Dropbox depuis le menu, bascule Taille / Sur disque, arborescence en direct pendant l'analyse, candidats en double sans télécharger les fichiers cloud.

*D'après les descriptions publiques en date de septembre 2026 — corrections bienvenues.*

## Comment il a été conçu

TreeScan Size est aussi une expérience. **Le code a été écrit par un modèle de codage bon marché** (DeepSeek V4 Flash) tandis que Claude Opus jouait le rôle de chef de projet technique : rédaction de la spécification, découpage du travail en ~25 petites tâches avec réponses précalculées, relecture de chaque ligne risquée. Un script Python et un rapport HTML ([reference/](reference/)) ont servi d'implémentation de référence.

Ce que nous avons appris, en bref :
- Un modèle bon marché est excellent sur un chemin balisé : porter la logique depuis une référence, construire l'interface à partir d'un squelette de code.
- Des tests au vert ne suffisent pas : il a une fois désactivé la protection des dossiers système du menu Corbeille alors que tous les tests passaient — seule la relecture du code l'a détecté.
- Un dossier de test de 500 fichiers cache ce que 2,9 millions de fichiers révèlent : un onglet a mis 9 minutes à s'afficher sur un vrai disque. Les vérifications à taille réelle l'ont trouvé, un humain a trouvé le reste.

L'histoire complète — tâches, vérifications, leçons, journaux d'exécution — se trouve dans [docs/FINDINGS.md](docs/FINDINGS.md) et [docs/RESEARCH.md](docs/RESEARCH.md) (en russe) ; les journaux d'exécution sont joints à la [release](https://github.com/gorbarov/treescan-size/releases/latest).

## Contribuer

Rapports de bugs, traductions et relectures par des locuteurs natifs sont les bienvenus — voir [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence et marques

[MIT](LICENSE). TreeScan Size s'inspire de TreeSize pour Windows mais n'est **ni affilié à JAM Software ni approuvé par celui-ci**. TreeSize est une marque déposée de Joachim Marder e.K. (JAM Software). Dropbox, iCloud, OneDrive et macOS sont des marques de leurs propriétaires respectifs.
