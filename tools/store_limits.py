#!/usr/bin/env python3
"""Проверка лимитов App Store Connect для docs/launch/store-listing-i18n.json (и мастера en/ru)."""
import json, sys
from pathlib import Path

LIM = {"name": ("chars", 30), "subtitle": ("chars", 30), "promo": ("chars", 170), "keywords": ("bytes", 100), "description": ("chars", 4000)}


def check(lang, d):
    bad = []
    for k, (unit, lim) in LIM.items():
        v = d.get(k, "")
        n = len(v.encode()) if unit == "bytes" else len(v)
        if not v or n > lim:
            bad.append(f"{k} {n}/{lim} {unit}")
    if " " in d.get("keywords", "").replace(", ", ","):
        pass
    if ", " in d.get("keywords", ""):
        bad.append("keywords: пробел после запятой")
    if not d.get("name", "").startswith("TreeBars"):
        bad.append("name не начинается с TreeBars")
    return bad


if __name__ == "__main__":
    data = json.loads(Path(sys.argv[1] if len(sys.argv) > 1 else "docs/launch/store-listing-i18n.json").read_text(encoding="utf-8"))
    ok = True
    for lang, d in data.items():
        bad = check(lang, d)
        ok &= not bad
        print(f"{lang:8} {'OK' if not bad else 'ПРЕВЫШЕНО: ' + '; '.join(bad)}")
    sys.exit(0 if ok else 1)
