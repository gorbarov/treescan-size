#!/usr/bin/env python3
"""Проверка словарей переводов Sources/TreeSizeCore/L10n_*.swift.
Дубли ключей в словарном литерале Swift роняют приложение при запуске (код 133) — ловим до сборки.
Проверяет: нет дублей; у всех языков одинаковый набор ключей (как у en); в значениях не-русских
языков нет кириллицы; каждый литерал tr("…") из Sources/TreeSizeApp есть в словаре en."""
import collections, glob, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAIR = re.compile(r'^\s*("(?:[^"\\]|\\.)*")\s*:\s*\n?\s*("(?:[^"\\]|\\.)*")', re.M)
TR = re.compile(r'\btr\("((?:[^"\\]|\\.)*)"\)')
bad = []
tables = {}
for f in sorted(glob.glob(str(ROOT / "Sources/TreeSizeCore/L10n_*.swift"))):
    lang = Path(f).stem.split("_")[1]
    pairs = PAIR.findall(Path(f).read_text(encoding="utf-8"))
    keys = [k for k, _ in pairs]
    for k, c in collections.Counter(keys).items():
        if c > 1:
            bad.append(f"{lang}: ключ {k} встречается {c} раза — приложение упадёт при запуске")
    for k, v in pairs:
        if re.search("[а-яё]", v, re.I):
            bad.append(f"{lang}: кириллица в переводе {k[:50]} → {v[:50]}")
    tables[lang] = set(keys)
en = tables.get("en", set())
for lang, ks in tables.items():
    for k in sorted(en - ks)[:10]:
        bad.append(f"{lang}: нет ключа {k[:60]}")
    for k in sorted(ks - en)[:10]:
        bad.append(f"{lang}: лишний ключ (нет в en) {k[:60]}")
used = set()
for f in glob.glob(str(ROOT / "Sources/TreeSizeApp/*.swift")) + glob.glob(str(ROOT / "Sources/TreeSizeCore/*.swift")):
    for m in TR.finditer(Path(f).read_text(encoding="utf-8")):
        if "\\(" not in m.group(1) and re.search("[а-яё]", m.group(1), re.I):
            used.add('"' + m.group(1) + '"')
for k in sorted(used - en)[:20]:
    bad.append(f"en: строка интерфейса без перевода {k[:70]}")
for b in bad:
    print("L10N:", b)
print(f"L10N: {'OK' if not bad else 'ОШИБКИ: ' + str(len(bad))} ({len(tables)} словарей, {len(en)} ключей)")
sys.exit(1 if bad else 0)
