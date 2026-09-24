<p align="center"><img src="docs/screenshots/icon.png" width="96" alt=""></p>

<h1 align="center">TreeBars</h1>

<p align="center"><b>See what fills your Mac — as a folder tree with size bars.</b><br>
Free, open source, no network. Understands Dropbox and iCloud.</p>

<p align="center"><a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a></p>

<p align="center"><img src="docs/screenshots/pie-en.png" width="860" alt="TreeBars: folder tree with size bars and a pie chart"></p>

## Why

Finder can't tell you which folders ate your disk. Disk analyzers for the Mac show rings or treemaps. TreeBars shows the view Windows users know from TreeSize: **a plain folder tree where every row has a size bar and its share of the parent**. Scroll down, and you see what to clean up.

## Features

- **Folder tree with size bars** and percentages, sorted by size, with keyboard navigation.
- **Chart** of the selected folder, plus **Details**, **Extensions**, **File age**, **Top files** and **Duplicates** tabs.
- **Cloud-aware.** Dropbox and iCloud "online-only" files are marked: they count toward your cloud plan but take no space on the Mac. For Dropbox folders you can choose **Don't sync** right from the context menu.
- **Size / On disk toggle.** *Size* is what files weigh and what cloud quotas count. *On disk* is the space they really take on this Mac. Cloud-only files are ~0 on disk; sparse files such as a Docker or VM disk can show 460 GB of size while using 39 GB.
- **Duplicate candidates** — same size and extension, found without downloading cloud files.
- **Safe:** files go to the Trash only, after a confirmation; system folders are protected.
- **Private:** no network access, no analytics, no accounts. See [PRIVACY.md](PRIVACY.md).
- Light and dark themes. **9 languages:** English, 简体中文, 日本語, 한국어, Deutsch, Español, Français, Português, Русский.

| Top files | Duplicates | Dark theme |
|---|---|---|
| <img src="docs/screenshots/tree-videos-en.png" alt="Top files"> | <img src="docs/screenshots/duplicates-en.png" alt="Duplicate candidates"> | <img src="docs/screenshots/details-dark-en.png" alt="Details, dark theme"> |

## Install

Requires **macOS 14 Sonoma or later** on **Apple Silicon**.

1. Download `TreeBars.zip` from [Releases](https://github.com/gorbarov/treebars/releases), unzip it and move `TreeBars.app` to Applications.
2. The current build is **not notarized yet** (notarization is coming), so macOS will block the first launch:
   - **macOS 15 and later:** open the app once, click *Done*, then go to **System Settings → Privacy & Security** and click **Open Anyway**.
   - **macOS 14:** right-click the app → **Open** → **Open**.
   - Or in Terminal: `xattr -dr com.apple.quarantine /Applications/TreeBars.app`

To scan protected places (Mail, Messages, other users' data), give the app **Full Disk Access** in System Settings → Privacy & Security. It's optional: without it those folders are simply skipped.

### Build from source

```bash
git clone https://github.com/gorbarov/treebars && cd treebars
scripts/make_app.sh          # needs only Command Line Tools (Swift 5.9+), no Xcode
open build/TreeBars.app
```

## Compared to other tools

| | TreeBars | DaisyDisk | GrandPerspective | OmniDiskSweeper | Disk Inventory X |
|---|---|---|---|---|---|
| Main view | tree with size bars + pie | sunburst rings | treemap | column list | treemap + list |
| Price | free | paid | free (paid in App Store) | free | free |
| Source code | open, MIT | closed | open, GPL | closed | open, GPL |

What TreeBars adds on top: marks Dropbox/iCloud online-only files, "Don't sync" for Dropbox folders, a Size / On disk toggle, and duplicate candidates without downloading cloud files.

*Based on public descriptions as of September 2026; corrections are welcome.*

## How it was built

TreeBars is also an experiment: **the code was written by a cheap coding model** (DeepSeek V4 Flash), while Claude Opus acted as the tech lead — wrote the spec, cut the work into small tasks with precomputed answers, and reviewed the code. A Python script and an HTML report ([reference/](reference/)) served as the reference implementation. Total model cost was under $3.

The cheap model did well on logic with a reference and on UI with a code skeleton. It also once disabled the Trash menu's system-folder protection while every test was green — only code review caught it. The findings, tasks, checks and the lessons list are in [docs/FINDINGS.md](docs/FINDINGS.md) and [docs/RESEARCH.md](docs/RESEARCH.md) (in Russian; English write-up coming).

## Contributing

Bug reports, translations and native-speaker reviews are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License and trademarks

[MIT](LICENSE). TreeBars is inspired by TreeSize for Windows but is **not affiliated with or endorsed by JAM Software**. TreeSize is a registered trademark of Joachim Marder e.K. (JAM Software). Dropbox, iCloud and macOS are trademarks of their respective owners.
