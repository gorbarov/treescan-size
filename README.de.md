<p align="center">
  <img src="docs/screenshots/icon.png" width="128" alt="TreeScan Size icon">
</p>

<h1 align="center">TreeScan Size</h1>

<p align="center">
  <b>Sieh, was deinen Mac füllt — als Ordnerbaum mit Größenbalken.</b><br>
  Kostenlos und Open Source. Kein Netzwerk, kein Tracking. Versteht Dropbox, iCloud und OneDrive.
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
  <a href="README.md">English</a> · <a href="README.ru.md">Русский</a> · <a href="README.es.md">Español</a> · <b>Deutsch</b> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português</a> · <a href="README.ko.md">한국어</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a>
</p>

<p align="center">
  <img src="docs/screenshots/pie-en.png" width="900" alt="TreeScan Size: folder tree with size bars and a chart">
</p>

---

## Warum

Der Finder kann dir nicht sagen, welche Ordner deine Festplatte gefressen haben. Die meisten Festplatten-Analyse-Tools für den Mac zeichnen Ringe oder Treemaps. **TreeScan Size zeigt die Ansicht, die Windows-Nutzer von TreeSize kennen:** einen schlichten Ordnerbaum, in dem jede Zeile einen Größenbalken und ihren Anteil am übergeordneten Ordner hat. Scrolle nach unten — und du weißt, was du aufräumen musst.

## Highlights

|  |  |
|---|---|
| 🌳 **Baum mit Größenbalken** | Jeder Ordner zeigt seine Größe und den %-Anteil am übergeordneten Ordner, sortiert nach größten zuerst. Pfeiltasten, Klick überall auf eine Zeile. |
| ⚡ **Live-Scan** | Der Baum füllt sich, während der Scan läuft, mit einem echten Fortschrittsbalken (Prozent des belegten Speicherplatzes). Kein Warten hinter einem Spinner. |
| ☁️ **Cloud-fähig** | Dropbox-, iCloud- und OneDrive-Dateien, die „nur online" sind, werden markiert: Sie zählen zu deinem Cloud-Tarif, belegen aber keinen Speicherplatz auf dem Mac. Markiere einen Dropbox-Ordner direkt im Menü mit **Nicht synchronisieren**. |
| ⚖️ **Größe vs. auf dem Datenträger** | *Größe* ist das, was Dateien wiegen und was Cloud-Kontingente zählen. *Auf dem Datenträger* ist das, was sie wirklich auf diesem Mac belegen. Ein Docker- oder VM-Datenträger kann 460 GB „wiegen" und 39 GB belegen — du siehst beides. |
| 🔍 **Sechs Ansichten** | Diagramm, Details, Dateiendungen, Dateialter, Top-Dateien, Duplikat-Kandidaten (gefunden ohne Cloud-Dateien herunterzuladen). |
| 🛡️ **Sicher und privat** | Nur in den Papierkorb, mit Bestätigung; Systemordner sind geschützt. Überhaupt kein Netzwerkzugriff, keine Analysen, keine Konten. Siehe [PRIVACY.md](PRIVACY.md). |
| 🌍 **9 Sprachen** | Englisch, 简体中文, 日本語, 한국어, Deutsch, Español, Français, Português, Русский. Helles und dunkles Design. |

## Screenshots

| Live-Scan | Top-Dateien | Duplikat-Kandidaten |
|---|---|---|
| <img src="docs/screenshots/live-en.png" alt="Live scan with progress"> | <img src="docs/screenshots/top-en.png" alt="Top files in a folder"> | <img src="docs/screenshots/duplicates-en.png" alt="Duplicate candidates"> |

| Was scannen? | Dunkles Design | Größe vs. auf dem Datenträger, erklärt |
|---|---|---|
| <img src="docs/screenshots/welcome-en.png" alt="Start screen"> | <img src="docs/screenshots/details-dark-en.png" alt="Details, dark theme"> | <img src="docs/screenshots/mode-help-en.png" alt="Size vs On disk help"> |

## Installation

Erfordert **macOS 14 Sonoma oder neuer** auf **Apple Silicon**.

1. Lade **TreeScan-Size.zip** von [Releases](https://github.com/gorbarov/treescan-size/releases/latest) herunter, entpacke sie und verschiebe die App in den Ordner „Programme".
2. Der Build ist **noch nicht notarisiert**, daher blockiert macOS den ersten Start:
   - **macOS 15 und neuer:** Öffne die App einmal, klicke auf *Fertig*, dann **Systemeinstellungen → Datenschutz & Sicherheit → Dennoch öffnen**.
   - **macOS 14:** Rechtsklick auf die App → **Öffnen** → **Öffnen**.
   - Oder im Terminal: `xattr -dr com.apple.quarantine "/Applications/TreeScan Size.app"`
3. Beim ersten Start bittet die App um **Festplattenvollzugriff** — ein Schalter in den Systemeinstellungen statt eines Dutzends macOS-Abfragen für Schreibtisch, Dokumente, iCloud und Daten anderer Apps. Du kannst es überspringen: Geschützte Ordner werden dann einfach mit 🔒 markiert und nicht gelesen.

### Aus dem Quellcode bauen

```bash
git clone https://github.com/gorbarov/treescan-size && cd treescan-size
scripts/make_app.sh          # Command Line Tools are enough (Swift 5.9+), no Xcode needed
open "build/TreeScan Size.app"
```

## Vergleich mit anderen Tools

| | TreeScan Size | DaisyDisk | GrandPerspective | OmniDiskSweeper | Disk Inventory X |
|---|---|---|---|---|---|
| Hauptansicht | Baum mit Größenbalken + Diagramm | Sunburst-Ringe | Treemap | Spaltenliste | Treemap + Liste |
| Preis | kostenlos | kostenpflichtig | kostenlos (kostenpflichtig im App Store) | kostenlos | kostenlos |
| Quellcode | offen, MIT | geschlossen | offen, GPL | geschlossen | offen, GPL |

Dazu kommt: Nur-online-Cloud-Dateien markiert, Dropbox „Nicht synchronisieren" aus dem Menü, Umschalter Größe / auf dem Datenträger, Live-Baum während des Scans, Duplikat-Kandidaten ohne Herunterladen von Cloud-Dateien.

*Basierend auf öffentlichen Beschreibungen Stand September 2026 — Korrekturen willkommen.*

## Wie es gebaut wurde

TreeScan Size ist auch ein Experiment. **Der Code wurde von einem günstigen Coding-Modell geschrieben** (DeepSeek V4 Flash), während Claude Opus als Tech Lead fungierte: schrieb die Spezifikation, zerlegte die Arbeit in ~25 kleine Aufgaben mit vorberechneten Antworten, prüfte jede riskante Zeile. Ein Python-Skript und ein HTML-Bericht ([reference/](reference/)) dienten als Referenzimplementierung.

Was wir gelernt haben, kurz gesagt:
- Ein günstiges Modell ist großartig auf einem vorgezeichneten Pfad: Logik aus einer Referenz portieren, UI aus einem Code-Skelett bauen.
- Grüne Tests reichen nicht: Einmal deaktivierte es den Systemordner-Schutz des Papierkorb-Menüs, während alle Tests bestanden — nur die Code-Überprüfung fand es.
- Ein Testordner mit 500 Dateien verbirgt, was 2,9 Millionen Dateien zeigen: Ein Tab brauchte 9 Minuten zum Zeichnen auf einer echten Festplatte. Prüfungen in echter Größe fanden es, ein Mensch fand den Rest.

Die vollständige Geschichte — Aufgaben, Prüfungen, Lektionen, Ausführungsprotokolle — steht in [docs/FINDINGS.md](docs/FINDINGS.md) und [docs/RESEARCH.md](docs/RESEARCH.md) (auf Russisch); Ausführungsprotokolle sind an das [Release](https://github.com/gorbarov/treescan-size/releases/latest) angehängt.

## Mitwirken

Fehlerberichte, Übersetzungen und Reviews von Muttersprachlern sind sehr willkommen — siehe [CONTRIBUTING.md](CONTRIBUTING.md).

## Lizenz und Marken

[MIT](LICENSE). TreeScan Size ist von TreeSize für Windows inspiriert, steht aber **in keiner Verbindung zu JAM Software und wird von JAM Software nicht unterstützt**. TreeSize ist eine eingetragene Marke von Joachim Marder e.K. (JAM Software). Dropbox, iCloud, OneDrive und macOS sind Marken ihrer jeweiligen Inhaber.
