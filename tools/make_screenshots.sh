#!/bin/zsh
# Витринные снимки для README и площадок: демо-папка tools/make_demo.py → docs/screenshots/*.png
#   tools/make_screenshots.sh
set -euo pipefail
cd ${0:A:h:h}
B=/tmp/ts-build/release/TreeSizeApp
swift build -c release --disable-sandbox --scratch-path /tmp/ts-build 2>&1 | tail -1
R=$(python3 tools/make_demo.py /tmp/tbdemo)
O=docs/screenshots
shot() { local lang=$1 out=$2; shift 2; TREEBARS_LANG=$lang $B --root "$R" --snapshot "$O/$out.png" "$@" >/dev/null; echo "  $out"; }
shot en pie-en            --tab pie
shot en tree-videos-en    --tab pie     --select "$R/Videos"
shot en details-dark-en   --tab details --select "$R/Videos" --dark
shot en extensions-en     --tab ext
shot en top-en            --tab top     --select "$R/Videos"
shot en duplicates-en     --tab dups
shot en mode-help-en      --mode-help
shot zh pie-zh            --tab pie
shot ja pie-ja            --tab pie
shot ko pie-ko            --tab pie
shot de pie-de            --tab pie
shot en welcome-en        --welcome
shot en access-en         --access
shot en live-en           --live-demo
