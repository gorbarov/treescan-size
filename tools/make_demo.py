#!/usr/bin/env python3
"""Демо-папка для витринных снимков: «Dropbox» пользователя alex, файлы разреженные (занимают ~0 на диске).
  tools/make_demo.py [/tmp/tbdemo]   → /tmp/tbdemo/Users/alex/Library/CloudStorage/Dropbox
Путь с CloudStorage/Dropbox включает в приложении режим Dropbox (плашка, «Размер» по умолчанию)."""
import json, os, shutil, subprocess, sys
from pathlib import Path

base = Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/tbdemo")
m = json.loads((Path(__file__).parent / "demo_manifest.json").read_text(encoding="utf-8"))
root = base / m["root"]
if base.exists():
    shutil.rmtree(base)
for rel, size in m["files"]:
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "wb") as f:
        f.truncate(size)
for rel in m["ignored"]:
    subprocess.run(["xattr", "-w", "com.apple.fileprovider.ignore#P", "1", str(root / rel)], check=True)
print(root)
