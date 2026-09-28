#!/bin/zsh
# Проверка задания: tools/check_task.sh <номер>. Выход 0 — прошло.
# Сборка всегда в /tmp/ts-build (вне Dropbox).
set -e
cd "$(dirname "$0")/.."
N=${1:?номер задания}
B=/tmp/ts-build
swift build -c release --disable-sandbox --scratch-path $B 2>&1 | tail -3
[ -d /tmp/ts-fixture ] || tools/make_fixture.sh /tmp/ts-fixture >/dev/null
# Общие проверки для любого задания: словари переводов и запуск на всех языках (дубль ключа роняет приложение)
python3 tools/check_l10n.py | tail -5
for L in ru en zh ja ko de es fr pt; do
  TREEBARS_LANG=$L $B/release/TreeSizeApp --root /tmp/ts-fixture --mode-help --snapshot $B/lang_$L.png >/dev/null 2>&1 \
    || { echo "ЯЗЫК $L: приложение упало при запуске"; exit 1; }
done
echo "ЯЗЫКИ: запуск на 9 языках OK"
case $N in
  01) $B/release/tscan --model-check /tmp/ts-fixture > $B/01.txt
      diff -u tools/expected/01_model_check.txt $B/01.txt && echo "ЗАДАНИЕ 01: OK" ;;
  02) $B/release/tscan --actions-check /tmp/ts-fixture > $B/02.txt
      diff -u tools/expected/02_actions_check.txt $B/02.txt && echo "ЗАДАНИЕ 02: OK" ;;
  03) $B/release/TreeSizeApp --root /tmp/ts-fixture --selftest > $B/03.json
      python3 -c "
import json,sys
e=json.load(open('tools/expected/03_selftest.json')); g=json.load(open('$B/03.json'))
bad=[(k,e[k],g.get(k)) for k in e if g.get(k)!=e[k]]
[print(f'  {k}: ждали {a!r}, получили {b!r}') for k,a,b in bad]
sys.exit(1 if bad else 0)" && echo "ЗАДАНИЕ 03: OK" ;;
  10u) $B/release/TreeSizeApp --root /tmp/ts-fixture --uitest > $B/10u.json
      python3 -c "
import json,sys
e=json.load(open('tools/expected/10u_uitest.json')); g=json.load(open('$B/10u.json'))
bad=[(k,e[k],g.get(k)) for k in e if g.get(k)!=e[k]]
[print(f'  {k}: ждали {a!r}, получили {b!r}') for k,a,b in bad]
sys.exit(1 if bad else 0)" && echo "ЗАДАНИЕ 10u: OK" ;;
  *)  $B/release/TreeSizeApp --root /tmp/ts-fixture --snapshot $B/snap_$N.png ${@:2} && ls -la $B/snap_$N.png && echo "ЗАДАНИЕ $N: снимок готов, его смотрит приёмщик" ;;
esac
