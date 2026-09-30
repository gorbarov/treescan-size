<p align="center">
  <img src="docs/screenshots/icon.png" width="128" alt="TreeScan Size icon">
</p>

<h1 align="center">TreeScan Size</h1>

<p align="center">
  <b>See what fills your Mac — as a folder tree with size bars.</b><br>
  Free and open source. No network, no tracking. Understands Dropbox, iCloud and OneDrive.
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
  <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a>
</p>

<p align="center">
  <img src="docs/screenshots/pie-en.png" width="900" alt="TreeScan Size: folder tree with size bars and a chart">
</p>

---

## Why

Finder can't tell you which folders ate your disk. Most disk analyzers for the Mac draw rings or treemaps. **TreeScan Size shows the view Windows users know from TreeSize:** a plain folder tree where every row has a size bar and its share of the parent. Scroll down — and you know what to clean up.

## Highlights

|  |  |
|---|---|
| 🌳 **Tree with size bars** | Every folder shows its size and % of the parent, sorted biggest first. Arrow keys, click anywhere on a row. |
| ⚡ **Live scan** | The tree fills in while the scan runs, with a real progress bar (percent of the used disk space). No waiting behind a spinner. |
| ☁️ **Cloud-aware** | Dropbox, iCloud and OneDrive "online-only" files are marked: they count toward your cloud plan but take no space on the Mac. Mark a Dropbox folder **Don't sync** right from the menu. |
| ⚖️ **Size vs On disk** | *Size* is what files weigh and what cloud quotas count. *On disk* is what they really take on this Mac. A Docker or VM disk can "weigh" 460 GB and use 39 GB — you see both. |
| 🔍 **Six views** | Chart, Details, Extensions, File age, Top files, Duplicate candidates (found without downloading cloud files). |
| 🛡️ **Safe and private** | Trash only, with a confirmation; system folders are protected. No network access at all, no analytics, no accounts. See [PRIVACY.md](PRIVACY.md). |
| 🌍 **9 languages** | English, 简体中文, 日本語, 한국어, Deutsch, Español, Français, Português, Русский. Light and dark theme. |

## Screenshots

| Live scan | Top files | Duplicate candidates |
|---|---|---|
| <img src="docs/screenshots/live-en.png" alt="Live scan with progress"> | <img src="docs/screenshots/top-en.png" alt="Top files in a folder"> | <img src="docs/screenshots/duplicates-en.png" alt="Duplicate candidates"> |

| What to scan? | Dark theme | Size vs On disk, explained |
|---|---|---|
| <img src="docs/screenshots/welcome-en.png" alt="Start screen"> | <img src="docs/screenshots/details-dark-en.png" alt="Details, dark theme"> | <img src="docs/screenshots/mode-help-en.png" alt="Size vs On disk help"> |

## Install

Requires **macOS 14 Sonoma or later** on **Apple Silicon**.

1. Download **TreeScan Size.zip** from [Releases](https://github.com/gorbarov/treescan-size/releases/latest), unzip it and move the app to Applications.
2. The build is **not notarized yet**, so macOS blocks the first launch:
   - **macOS 15 and later:** open the app once, click *Done*, then **System Settings → Privacy & Security → Open Anyway**.
   - **macOS 14:** right-click the app → **Open** → **Open**.
   - Or in Terminal: `xattr -dr com.apple.quarantine "/Applications/TreeScan Size.app"`
3. On first launch the app asks for **Full Disk Access** — one switch in System Settings instead of a dozen macOS prompts for Desktop, Documents, iCloud and other apps' data. You can skip it: protected folders are then simply marked 🔒 and not read.

### Build from source

```bash
git clone https://github.com/gorbarov/treescan-size && cd treescan-size
scripts/make_app.sh          # Command Line Tools are enough (Swift 5.9+), no Xcode needed
open "build/TreeScan Size.app"
```

## Compared to other tools

| | TreeScan Size | DaisyDisk | GrandPerspective | OmniDiskSweeper | Disk Inventory X |
|---|---|---|---|---|---|
| Main view | tree with size bars + chart | sunburst rings | treemap | column list | treemap + list |
| Price | free | paid | free (paid in App Store) | free | free |
| Source code | open, MIT | closed | open, GPL | closed | open, GPL |

On top of that: online-only cloud files marked, Dropbox "Don't sync" from the menu, Size / On disk toggle, live tree during the scan, duplicate candidates without downloading cloud files.

*Based on public descriptions as of September 2026 — corrections welcome.*

## How it was built

TreeScan Size is also an experiment. **The code was written by a cheap coding model** (DeepSeek V4 Flash) while Claude Opus acted as the tech lead: wrote the spec, cut the work into ~25 small tasks with precomputed answers, reviewed every risky line. A Python script and an HTML report ([reference/](reference/)) served as the reference implementation.

What we learned, in short:
- A cheap model is great at a laid-out path: port logic from a reference, build UI from a code skeleton.
- Green tests are not enough: it once disabled the Trash menu's system-folder protection while every test passed — only code review caught it.
- A 500-file test folder hides what 2.9 million files show: one tab took 9 minutes to draw on a real disk. Real-size checks found it, a human found the rest.

The full story — tasks, checks, lessons, run logs — is in [docs/FINDINGS.md](docs/FINDINGS.md) and [docs/RESEARCH.md](docs/RESEARCH.md) (in Russian); run logs are attached to the [release](https://github.com/gorbarov/treescan-size/releases/latest).

## Contributing

Bug reports, translations and native-speaker reviews are very welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License and trademarks

[MIT](LICENSE). TreeScan Size is inspired by TreeSize for Windows but is **not affiliated with or endorsed by JAM Software**. TreeSize is a registered trademark of Joachim Marder e.K. (JAM Software). Dropbox, iCloud, OneDrive and macOS are trademarks of their respective owners.
