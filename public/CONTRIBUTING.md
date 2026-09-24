# Contributing

Thanks for your interest! Issues and pull requests are welcome.

## Build

Requires macOS 14+ and Swift 5.9+ (Command Line Tools are enough, Xcode is not required).

```bash
swift build -c release
scripts/make_app.sh          # builds build/TreeBars.app
```

## Checks

There is no XCTest target (the project is built without Xcode). Instead, the app has console modes:

```bash
tools/make_fixture.sh /tmp/ts-fixture            # a test folder with awkward cases
python3 tools/compare.py /tmp/ts-fixture         # Swift scanner vs the Python reference
tools/check_task.sh 03                           # model / format / action facts
.build/release/TreeSizeApp --root /tmp/ts-fixture --snapshot /tmp/snap.png --tab pie   # render the window to PNG
```

`reference/treesize.py` and `reference/template.html` are the original Python scanner and HTML report the app was ported from. The Swift scanner must match the Python output.

## Translations (good first issue)

UI strings live in `Sources/TreeSizeCore/L10n_<code>.swift`. The Russian source string is the key. To add a language:

1. Copy `L10n_en.swift` to `L10n_<code>.swift` and translate the values (keep leading/trailing spaces, emoji and `**bold**` markers).
2. Register the table in `L10n.tables` in `L10n.swift`.
3. Check it: `TREEBARS_LANG=<code> .build/release/TreeSizeApp --root /tmp/ts-fixture --snapshot /tmp/snap.png --tab pie`.

Native-speaker reviews of the existing translations (zh, ja, ko, de, es, fr, pt) are very welcome too — they were drafted by a language model.

## Safety rules for code that touches files

Anything that deletes, moves or changes attributes of user files must go through `FileActions.canTrash(path:root:)` (inside the scanned root and not a protected system folder) and ask for confirmation. Pull requests that change this code get a careful review.

## How this project was built

The code was written by cheap coding models under Claude's supervision. The tasks, checks and lessons are in `docs/` — see [docs/FINDINGS.md](docs/FINDINGS.md). You are welcome to contribute with any tools you like.
